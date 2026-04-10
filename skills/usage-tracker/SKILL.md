---
name: usage-tracker
description: "Track and report local Claude Code usage per request: tokens consumed, estimated cost in €, sessions, projects, and tool breakdown. Use when the user asks about consumption, credits, usage, cost per request, wants to see a report, asks why a specific request was expensive, suspects a process is consuming tokens, wants to optimize their Claude Code usage, or wants to audit tool usage by request. Also triggers on Spanish phrases: 'cuánto me está costando', 'cuántos tokens', 'consumo de hoy', 'qué petición fue cara', 'está consumiendo mucho', 'optimizar consumo', 'reporte de uso', 'ver uso', 'instalar tracker', 'hook no registra'. Commands: /usage-tracker report [hoy|semana|mes|all] [proyecto], /usage-tracker top-requests [hoy|semana], /usage-tracker install, /usage-tracker status"
allowed-tools: Bash(~/.claude/*:*) Bash(python3:*) Bash(tail:*) Bash(ls:*) Bash(chmod:*) Bash(grep:*) Bash(cp:*) Bash(mv:*) Read Edit Write
user-invocable: true
---

# Usage Tracker

Gestiona el sistema de logging de consumo local de Claude Code y permite analizar el coste **por petición del usuario**.

## Referencias

| Archivo | Cuándo cargar |
|---------|--------------|
| [`references/pricing.md`](references/pricing.md) | MANDATORY al calcular o explicar costes en € |
| [`references/log-usage.sh`](references/log-usage.sh) | MANDATORY en `install` si el hook no existe |
| [`references/usage-report.sh`](references/usage-report.sh) | MANDATORY en `install` si el script no existe |
| **No cargar** los scripts | Para `report`, `top-requests` y `status` — solo se ejecutan |

## Cómo funciona el coste por petición

Cada mensaje del usuario dispara múltiples tool calls en secuencia. El log registra cada tool call con el campo `request` = último mensaje del usuario que lo originó. Esto permite agrupar todos los tool calls de una petición y calcular su coste total.

```
Usuario: "revisa el módulo delsol"
  └─ Read delsol.module           → 1.200 tok   ┐
  └─ Grep hook_order              → 80 tok      │ mismo "request"
  └─ Read DelsolService.php       → 2.400 tok   │ → coste total: 4.980 tok
  └─ Bash phpcs delsol/           → 1.300 tok   ┘
```

**Para ver el coste por petición:**
```bash
cat ~/.claude/usage.jsonl | python3 -c "
import json, sys
from collections import defaultdict

req = defaultdict(lambda: {'tok':0,'tools':[],'ts':''})
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        r = d.get('request','—')[:80]
        req[r]['tok']   += d.get('tok_total',0)
        req[r]['ts']     = d.get('ts','')[:10]
        req[r]['tools'].append(d.get('tool','?'))
    except: pass

print(f'{'Tokens':>8}  {'Tools':>5}  Petición')
print('-'*80)
for r, v in sorted(req.items(), key=lambda x: -x[1]['tok'])[:15]:
    print(f'{v[\"tok\"]:>8,}  {len(v[\"tools\"]):>5}  {r}')
"
```

## Framework: antes de enviar una petición costosa

Antes de ejecutar, evalúa:

- **¿Necesitas el archivo completo?** — Usa `offset`/`limit` en Read si solo necesitas una sección concreta.
- **¿Esta tarea es independiente?** — Si sí, ábrela en una conversación nueva. El contexto acumulado puede multiplicar el coste real por 5-10x.
- **¿Puedes confirmar antes de leer?** — Un Grep previo que verifica que el contenido existe evita un Read masivo en falso.
- **¿Hay un Agent call implícito?** — Si la petición requiere "analizar todo X", anticipar que el coste real será 10-100x lo que mostrará el log.

## Qué multiplica el coste por petición (no obvio)

**Ficheros grandes leídos completos**
Un `Read` de 3.000 líneas = ~15.000 tokens de output. Si la petición lo lee dos veces (para entender y luego editar), el coste se duplica. Identificar en el log peticiones con múltiples `Read` del mismo archivo.

**Contexto acumulado de conversación**
El hook captura el tool call aislado, pero Claude envía toda la historia con cada petición. Una conversación de 40 mensajes puede añadir 80.000 tokens invisibles por petición. El log subestima más a medida que avanza la conversación — las primeras peticiones del día son las más fiables.

**Agent calls con subagentes**
Un `Agent` tool call lanza una conversación completa internamente. Si el log muestra un Agent con 500 tokens, el coste real puede ser 20.000+. Son el mayor punto ciego del sistema.

**Bash con output masivo**
`git log`, `find`, `cat archivo_grande` pueden devolver miles de líneas. El output del tool son tokens. Una petición con varios Bash de output masivo puede ser 10x más cara de lo que parece.

**Skills cargadas en contexto**
Cada SKILL.md activo añade tokens de overhead fijo por petición durante esa sesión. El log no lo captura.

## Framework: interpretar una petición cara

```
¿Es un Agent call?
└─ Sí → Coste real = 10-100x lo que muestra el log. No analizar más.

¿Hay múltiples Read del mismo archivo?
└─ Sí → Se leyó para entender y se releyó para editar.
        Optimización: usar offset/limit en el segundo Read.

¿Hay Bash con mucho tok_out?
└─ Sí → Output masivo (logs, git, find).
        Optimización: añadir | head -50 o filtrar antes de leer.

¿La petición está tarde en una conversación larga?
└─ Sí → El contexto acumulado domina el coste real.
        Optimización: nueva conversación para tareas independientes.

¿Muchas herramientas para una petición simple?
└─ Sí → Claude exploró antes de actuar (Glob→Read→Read→Edit).
        Normal en primera exploración; evitar en peticiones repetidas.
```

## Patrones de peticiones caras vs baratas

| Tipo de petición | Coste log | Coste real | Causa |
|-----------------|-----------|------------|-------|
| "revisa este archivo" (1.000 LOC) | Alto | Alto | Read masivo |
| "ejecuta el lint" | Bajo | Bajo | Bash corto |
| "analiza todo el módulo" | Alto | Muy alto | Agent probable |
| "arregla este bug" en conv. larga | Medio | Muy alto | Contexto acumulado |
| "cambia este string" | Muy bajo | Bajo | Edit preciso |
| "busca dónde se usa X" | Bajo | Bajo | Grep eficiente |

## Comandos

### `report [hoy|semana|mes|all] [proyecto]`

**MANDATORY**: Cargar [`references/pricing.md`](references/pricing.md) si se explican costes en €.

```bash
~/.claude/usage-report.sh hoy
~/.claude/usage-report.sh semana Oltex
```

El reporte incluye la sección **"Por petición (top 20 más costosas)"** de forma automática — muestra cada mensaje del usuario con su nº de tools, tokens totales, coste y resumen de herramientas (`Edit×5, Bash×3…`). No hace falta ejecutar `top-requests` por separado.

### `top-requests [hoy|semana]`

Ejecutar el snippet Python de "coste por petición" con el filtro de fecha. Mostrar las 15 peticiones más caras del período con sus tokens y herramientas usadas.

### `install`

**MANDATORY**: Cargar [`references/log-usage.sh`](references/log-usage.sh) y [`references/usage-report.sh`](references/usage-report.sh).

1. Verificar: `ls -la ~/.claude/log-usage.sh ~/.claude/usage-report.sh`
2. Si falta alguno: recrear desde `references/` con Write tool
3. `chmod +x ~/.claude/log-usage.sh ~/.claude/usage-report.sh`
4. Verificar hook en `settings.json`: buscar `"$HOME/.claude/log-usage.sh"` en `hooks.PostToolUse`
5. Si falta: añadir con Edit preservando el JSON existente
6. **Validar siempre**: `python3 -c "import json,os; json.load(open(os.path.expanduser('~/.claude/settings.json')))"`
7. Confirmar: ejecutar un Bash y verificar `tail -1 ~/.claude/usage.jsonl`

**Error recovery para `install`**:
- Si el JSON de `settings.json` queda corrupto tras la edición: restaurar desde `~/.claude/settings.json.bak` si existe; si no, reconstruir la sección `hooks` manualmente con Edit y revalidar con python3.
- Si `chmod` falla (permiso denegado): verificar propietario con `ls -la` y usar `sudo chmod` solo si es necesario.
- Si la recreación del script falla: copiar el contenido directamente desde `references/` con Write tool sobreescribiendo el archivo destino.

### `status`

```bash
# Hook activo
python3 -c "import json,os; d=json.load(open(os.path.expanduser('~/.claude/settings.json'))); print('Hook OK' if any('log-usage' in str(h) for h in d.get('hooks',{}).get('PostToolUse',[])) else 'Hook AUSENTE')"

# Última entrada
tail -1 ~/.claude/usage.jsonl | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('ts','')[:19], d.get('tool',''), d.get('label','')[:50])"

# Hace cuánto
python3 -c "
import json,os; from datetime import datetime,timezone
last=json.loads(open(os.path.expanduser('~/.claude/usage.jsonl')).readlines()[-1])
dt=datetime.fromisoformat(last['ts'].replace('Z','+00:00'))
age=(datetime.now(timezone.utc)-dt).seconds//60
print(f'Última entrada hace {age} min — {\"OK\" if age<60 else \"POSIBLE PROBLEMA\"}')" 2>/dev/null || echo "Log vacío"
```

## Árbol de diagnóstico: usage.jsonl corrupto

Si `usage-report.sh` falla con errores de parsing JSON:

```bash
# 1. Contar líneas totales
grep -c '' ~/.claude/usage.jsonl

# 2. Encontrar líneas rotas
python3 -c "
import json, os
with open(os.path.expanduser('~/.claude/usage.jsonl')) as f:
    for i, line in enumerate(f, 1):
        try:
            json.loads(line.strip())
        except:
            print(f'Línea {i} rota: {line[:80]}')
"

# 3. Extraer solo líneas válidas
python3 -c "
import json, sys, os
with open(os.path.expanduser('~/.claude/usage.jsonl')) as f:
    valid = [l for l in f if l.strip()]
for l in valid:
    try: json.loads(l); print(l, end='')
    except: pass
" 2>/dev/null
# Si hay pocas líneas rotas: archivar y regenerar el log limpio
cp ~/.claude/usage.jsonl ~/.claude/usage-backup-$(date +%Y%m%d).jsonl
grep -v '^$' ~/.claude/usage.jsonl | python3 -c "
import sys, json
for l in sys.stdin:
    try: json.loads(l); print(l, end='')
    except: pass
" > /tmp/usage_clean.jsonl && mv /tmp/usage_clean.jsonl ~/.claude/usage.jsonl
```

## Árbol de diagnóstico: hook no registra

```
¿Existe usage.jsonl?
├─ No → Hook nunca disparó
│       → Verificar settings.json (comando status)
│       → chmod +x ~/.claude/log-usage.sh
│       → Reiniciar Claude Code para recargar settings.json
└─ Sí, pero no crece
      ├─ Hook ausente en settings.json → install
      ├─ settings.json JSON inválido   → reparar JSON
      ├─ python3 no disponible         → hook falla silenciosamente
      └─ Script sin permisos           → chmod +x
```

## Problemas conocidos

**Session IDs poco fiables**: `PPID` se reutiliza entre sesiones. Usar `CLAUDE_SESSION_ID` si está disponible; si no, agrupar entradas separadas <30 min del mismo proyecto como una sesión.

**Subestimación sistémica no lineal**: La subestimación no crece linealmente con la conversación — crece de forma cuadrática. A mensaje 5: ~20% de subestimación. A mensaje 20: ~60%. A mensaje 40+: ~80-90%. El motivo: el contexto acumulado se envía completo en cada petición, y ese contexto también crece a cada mensaje. Las primeras peticiones de cada sesión son las únicas realmente fiables; usar `~/.claude/usage-report.sh hoy` comparando solo las primeras entradas del día para calibrar.

**Agent calls son el mayor punto ciego**: Los tokens internos del subagente son invisibles. Nunca comparar proyectos con distinta proporción de Agent calls.

**Ruido de procesos externos**: UUIDs en el reporte = Paperclip u otros procesos. Filtrar por proyecto.

## NEVER

- **NUNCA** asumir hook activo sin verificar que el log crece tras ejecutar una herramienta.
- **NUNCA** editar `settings.json` directamente sin validar JSON después — falla silenciosamente.
- **NUNCA** interpretar tokens estimados como coste absoluto — son índice relativo entre sesiones.
- **NUNCA** comparar proyectos con distinta proporción de Agent calls — fidelidad de medición diferente.
- **NUNCA** borrar `usage.jsonl` — archivar: `cp ~/.claude/usage.jsonl ~/.claude/usage-$(date +%Y%m%d).jsonl`
- **NUNCA** continuar una conversación larga para tareas independientes — el contexto acumulado hace que cada petición cueste 5-10x más que en una conversación nueva.
- **NUNCA** informar el € como coste real en Claude Max — es orientativo para comparación relativa.
- **NUNCA** añadir el hook dos veces en `settings.json` — duplicaría cada entrada del log.
- **NUNCA** concluir que una petición fue barata por tener pocos tool calls — puede haber un Agent call o conversación larga detrás.
- **NUNCA** comparar el coste entre períodos donde el modelo activo era distinto — cambiar de Sonnet a Opus multiplica el índice por ~5; un incremento en el reporte puede ser del modelo, no del trabajo.
