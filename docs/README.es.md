# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de nivel experto para Claude Code. Cada skill puntuada **A+ (120/120)** antes de publicarse.

## Instalar

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | Que hace | Puntuacion |
|-------|----------|------------|
| **[skill-advisor](../skills/skill-advisor/)** | Construye planes de ejecucion que combinan tus skills instaladas con los gaps que te faltan — y ofrece instalarlos. Nunca empieces una tarea sin las herramientas adecuadas. | 120/120 |
| **[skill-guard](../skills/skill-guard/)** | Auditor de seguridad — deteccion de amenazas en 9 capas para skills antes de instalarlas. Registro comunitario de auditorias. | 120/120 |
| **[skill-learner](../skills/skill-learner/)** | Captura errores y persiste correcciones para que el mismo fallo no se repita. Funciona con skills Y comportamiento general de Claude. Opcionalmente genera propuestas de mejora para autores. | 120/120 |

## skill-guard

> **Instalas una skill. Lee tu `~/.ssh`, coge tu `$GITHUB_TOKEN` y lo envia a un servidor remoto. No te enteras.**

skill-guard previene esto. Audita skills antes de instalarlas usando 9 capas de analisis — desde patrones estaticos hasta analisis semantico con LLM que detecta prompt injection disfrazada de instrucciones normales.

### Como funciona

```
Quieres instalar una skill
        |
        v
skill-guard consulta el registro comunitario de auditorias
        |
        v
Ya auditada (mismo SHA)?  --> Muestra informe anterior
No auditada?              --> "Quieres un analisis de seguridad?"
        |
        v
Analisis de 9 capas: permisos, patrones, scripts,
flujo de datos, abuso MCP, supply chain, reputacion...
        |
        v
Puntuacion 0-100 → VERDE / AMARILLO / ROJO
        |
        v
VERDE: auto-instala | AMARILLO: tu decides | ROJO: advertencia fuerte
```

### Las 9 capas

1. **Frontmatter y permisos** (20%) — Sin `allowed-tools`? Bash sin restricciones? Secuestro de descripcion?
2. **Patrones estaticos** (15%) — URLs, IPs, rutas sensibles, comandos peligrosos, variables de entorno
3. **Analisis semantico LLM** (30%) — Prompt injection, troyanos, ingenieria social, bombas de tiempo
4. **Scripts bundled** (15%) — Lee CADA script. Imports peligrosos, ofuscacion, exfiltracion
5. **Flujo de datos** (10%) — Mapea origen → destino. Datos sensibles llegando a URLs externas = amenaza confirmada
6. **MCP y herramientas** — Uso no declarado de MCP, exfiltracion via Slack/GitHub/Monday
7. **Supply chain** (2%) — Typosquatting, versiones sin fijar, repos falsos
8. **Reputacion** (3%) — Perfil del autor, edad del repo, forks troyanos
9. **Anti-evasion** (5%) — Trucos unicode, homoglifos, auto-modificacion, fingerprinting de entorno

### Dos modos de analisis

- **Auditoria completa** — Las 9 capas, informe completo, persistencia en registro
- **Escaneo rapido** — Solo capas 1+2+3. Auto-escala a completa si encuentra hallazgos HIGH/CRITICAL

### Registro comunitario de auditorias

Cada auditoria se guarda en [`skills/skill-guard/audits/`](../skills/skill-guard/audits/), organizada por autor verificado (anthropic, obra, softaworks, etc.). Antes de analizar, skill-guard comprueba si alguien ya audito esa version. Resultados instantaneos si el SHA coincide.

**Modelo de confianza:** Solo el sistema genera y publica resultados de auditoria. Los miembros de la comunidad solicitan auditorias mediante PR a `audits/requests/` — el mantenedor ejecuta skill-guard y publica el resultado. Esto impide que auditorias manipuladas entren en el registro.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **Instalas 50 skills. Usas 5. Las otras 45 acumulan polvo.**

skill-advisor arregla esto. Se situa entre tu y Claude, analizando cada instruccion para encontrar la mejor skill de TU coleccion instalada — antes de empezar a trabajar.

### Dos modos

**Pre-accion** — Antes de que Claude empiece a trabajar, recomienda skills que mejorarian el resultado:

```
> "fix this login bug"

Evaluacion de skills:
1. /systematic-debugging — coincide con "bug, test failure, unexpected behavior"
2. /webapp-testing — verificar el arreglo despues

Procedemos con estas? O directamente sin skill?
```

**Post-accion** — Al terminar un trabajo, sugiere el siguiente paso logico:

```
> [codigo modificado]

Skills recomendadas:
1. /webapp-testing — codigo modificado, tests necesarios
2. /verification-before-completion — antes de dar por terminado
```

### Como funciona

```
Escribes una instruccion
        |
        v
skill-advisor escanea tus skills instaladas
        |
        v
Coincidencia? --> Recomienda 1-5, ordenadas por impacto
Sin match?    --> Continua en silencio (o sugiere una para instalar)
```

### Dos modos

**Pre-accion** — Antes de que Claude empiece a trabajar, recomienda skills que mejorarian el resultado.

**Post-accion** — Al terminar un trabajo, sugiere el siguiente paso logico.

### Que lo hace diferente

- **Lee TUS skills** — Sin lista fija. Escanea el system-reminder dinamicamente.
- **Piensa lateralmente** — "hazlo mas bonito" encuentra skills de diseno, animacion Y auditoria de accesibilidad.
- **Sabe cuando callarse** — Tareas simples no reciben recomendaciones.
- **Recomienda pipelines** — Detecta escenarios multi-paso y sugiere el combo completo.
- **Fallback a la comunidad** — Si nada local coincide, sugiere skills instalables.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude se disculpa, promete hacerlo mejor — y comete el mismo error en la siguiente sesion.**

skill-learner rompe ese ciclo. Cuando una skill o Claude falla, captura que salio mal, por que, y que hacer en su lugar — como un archivo de correccion persistente que sobrevive entre sesiones.

### Como funciona

```
Algo salio mal
        |
        v
skill-learner detecta que skill (o comportamiento general) fallo
        |
        v
Hace preguntas enfocadas hasta entender el error
        |
        v
Guarda una correccion estructurada en ~/.claude/skill-corrections/
        |
        v
La proxima vez que esa skill se ejecute → la correccion esta disponible
        |
        v
Opcionalmente: genera una propuesta de mejora para el autor de la skill
```

### Caracteristicas clave

- **Auto-detecta la skill que fallo** del contexto de la conversacion
- **Deduplica** — consulta INDEX.md antes de crear, fusiona si el mismo problema ya existe
- **9 reglas NEVER** — previene correcciones vagas, duplicadas, scope creep y bypass de seguridad
- **Test de lectura en frio** — verifica que cada correccion es clara para un agente diferente en otra sesion
- **Propuestas de mejora** — genera propuestas con diffs, guardadas en local para que el usuario las suba
- **Bilingue** — escribe correcciones en el idioma del usuario para preservar matices

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## Estandares de Calidad

Cada skill se evalua con el framework [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensiones, 120 puntos max. **Minimo para inclusion: B (96/120).** Coleccion actual: todo A+ (120/120).

## Contribuir

1. Fork este repo
2. Anade tu skill en `skills/<nombre>/SKILL.md`
3. Ejecuta `/skill-judge` — debe puntuar B o superior
4. Abre un PR con tu puntuacion

## Licencia

[MIT](../LICENSE)
