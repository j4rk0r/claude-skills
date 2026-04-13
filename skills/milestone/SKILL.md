---
name: milestone
description: "Persistent development milestone tracker with full context across conversations. Use when: tracking multi-session features, resuming work from a previous conversation, asking 'what's left to do on X' or 'what's pending', breaking work into trackable subtasks, planning complex implementations, updating progress after coding, checking project status, completing a subtask with QA validation, auditing what's missing in the project, syncing milestones with actual code state, or closing/archiving a finished milestone. Also trigger when user references a milestone by name, says 'what did we do last time', 'resume where we left off', 'how far along is X', 'mark this as done', 'milestone done', 'close this milestone', 'what's missing', 'audit the project', 'sync milestones', or wants to plan a feature with subtasks. Commands: /milestone, /milestone <name>, /milestone init, /milestone sync, /milestone start, /milestone done, /milestone update."
allowed-tools: Read Write Edit Glob Grep Bash
---

# Milestone v2 — Persistent Development Context

## Storage: two-tier cache

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (~100 tok, auto-loaded vía MEMORY.md)
<project-root>/.milestones/<slug>.md                      ← AUTHORITATIVE (historial completo)
```

**Regla de lectura**: Snapshot de memoria primero. Solo `.milestones/` si necesitas historial completo o la memoria no existe. **Nunca leer ambos** si la memoria tiene la información suficiente.

**Regla de escritura**: Cada write a `.milestones/<slug>.md` → actualizar también el snapshot. Ruta: `~/.claude/projects/$(pwd | sed 's|/|-|g; s|^-||')/memory/`.

**Por qué esto importa**: Leer un archivo de milestone de 70 líneas cuesta ~1.500 tok. El snapshot cuesta ~100 tok. En una conversación de 40 mensajes, cada tool call reenvía TODO el historial — el contexto acumulado invisible multiplica el coste real 5-10x. Un snapshot en memoria elimina lecturas y mantiene el contexto mínimo.

## When to use milestone vs alternatives

Antes de crear un milestone, pregúntate:
- **¿Abarca múltiples sesiones?** → No: usar TodoWrite o Plan mode
- **¿Necesito contexto para retomar?** → No: la tarea es autocontenida
- **¿Hay decisiones arquitectónicas que recordar?** → Sí: milestone captura el "por qué"
- **¿Sesiones futuras tocarán esto?** → Sí: milestone es el briefing para la siguiente

Todas "no" → TodoWrite/Plan. Al menos una "sí" → milestone.

## Complexity classification

| Nivel | Criterio | Acción |
|-------|----------|--------|
| `[simple]` | 1 archivo, cambio claro, sin dependencias | Ejecutar directamente |
| `[complejo]` | 2+ archivos, nuevo servicio, refactor, integración, lógica nueva | **BLOQUEANTE**: plan antes de ejecutar |

Plan para `[complejo]`: Plan mode o `/gepetto` → guardar en `.milestones/plans/<slug>-<subtask>.md` → añadir referencia en el milestone. Previene el ciclo caro de prueba-error (6+ edits iterativos en el mismo archivo).

## Before starting any subtask

Antes de escribir código, pregúntate:
- **¿Cuántos archivos toca?** → >2 = `[complejo]`, necesita plan
- **¿Puedo describir el cambio en una frase?** → No: el alcance no está definido, planificar primero
- **¿Hay dependencias con otras subtareas?** → Documentar en el plan
- **¿He hecho algo similar en este milestone?** → Buscar en el contexto antes de repetir trabajo
- **¿Necesito leer archivos grandes?** → Usar `offset`/`limit` si solo necesito una sección

## Reference loading guide

| Comando | Cargar | Do NOT load |
|---------|--------|-------------|
| `/milestone` (list) | Nada — solo frontmatter `limit:8` | templates.md, errors.md, qa-validation.md, .milestones/ completos |
| `/milestone <name>` | Solo snapshot de memoria | templates.md, errors.md, qa-validation.md, .milestones/ si memoria suficiente |
| `/milestone init` | templates.md (**MANDATORY**), project-audit.md (si hay doc técnico) | errors.md, qa-validation.md |
| `/milestone sync` | project-audit.md (**MANDATORY**) | templates.md, errors.md |
| `/milestone done` | qa-validation.md (**MANDATORY**) | templates.md, errors.md |
| `/milestone update` | Nada — contenido ya en contexto | templates.md, errors.md, qa-validation.md |
| Corrupción detectada | errors.md (**MANDATORY**) | templates.md, qa-validation.md |

## Commands

### Phase 1 — Discovery

#### `/milestone` — Listar todos
Si `.milestones/` no existe → sugerir `/milestone init <nombre>`.
Leer solo frontmatter (primeras 8 líneas) de cada archivo con `limit:8`. Mostrar tabla:
```
| Estado | Hito | Progreso | Actualizado |
| 🟡 | Dashboard Propietario | 3/7 | 2026-04-09 |
```
🟢 completado · 🟡 en progreso · 🔴 no iniciado · ⚠️ sin actividad >30 días.

**Checkpoint**: si hay >3 milestones en progreso → advertir al usuario que la dispersión reduce calidad. Sugerir priorizar.

#### `/milestone <name>` — Cargar contexto
Fuzzy match: "dash" → "dashboard-propietario". Ambiguo → opciones numeradas. Sin match → listar disponibles.
1. Leer snapshot de memoria (ya en contexto vía MEMORY.md — zero reads)
2. Si no hay snapshot o está desactualizado: leer `.milestones/<slug>.md`
3. Mostrar: objetivo, progreso, subtareas pendientes, último contexto, siguiente acción sugerida
4. Para subtareas `[complejo]` pendientes: indicar si tienen plan o si hay que crearlo

**Checkpoint**: antes de sugerir siguiente acción, verificar si hay dependencias entre subtareas pendientes.

### Phase 2 — Planning

#### `/milestone sync` — Auditoría del proyecto vs milestones
**MANDATORY — LEER COMPLETO**: Cargar [`references/project-audit.md`](references/project-audit.md).

Cruza documento técnico + codebase + milestones existentes para detectar:
- Milestones desactualizados (subtareas completadas sin marcar, código nuevo sin reflejar)
- Funcionalidades descritas en el doc técnico sin milestone
- Deuda técnica no trackeada

Presenta informe con tabla de cobertura (✅/🟡/🔴/⚠️), propone actualizaciones y nuevos milestones con subtareas. **Espera confirmación** antes de crear o modificar nada.

**Trigger automático**: al ejecutar `/milestone` (listar) si hace >14 días de la última auditoría → sugerir ejecutar sync.

#### `/milestone init <name>` — Crear nuevo
Verificar que no existe uno similar (por nombre o por objetivo) → si existe, sugerir añadir subtareas al existente.
Cargar [`references/templates.md`](references/templates.md) (**MANDATORY**).

**Si el proyecto tiene documento técnico** (CLAUDE.md, docs/, spec): antes de crear, cargar [`references/project-audit.md`](references/project-audit.md) y verificar si hay otras funcionalidades sin milestone. Ofrecer crear todos los milestones necesarios de una vez, no solo el solicitado — el usuario decide cuáles confirmar.

1. Extraer objetivo o preguntar
2. Analizar el codebase para estado actual relevante
3. Proponer subtareas con `[simple]` o `[complejo]` y definición clara de "done"
4. Para `[complejo]`: proponer crear plan antes de confirmar
5. **Esperar confirmación** antes de guardar subtareas pendientes
6. Crear `.milestones/<slug>.md` + snapshot de memoria + pointer en `MEMORY.md`

**Checkpoint**: repasar las subtareas propuestas — ¿cada una tiene una definición de "done" verificable? Si no, refinar antes de guardar.

### Phase 3 — Execution

#### `/milestone start <name>` — Nueva sesión limpia
**Solo cuando el usuario lo pide explícitamente.** Nunca sugerir.
Script en [`references/milestone-new-session.sh`](references/milestone-new-session.sh). Auto-install:
1. Si `~/.claude/milestone-new-session.sh` no existe → copiar desde references + `chmod +x`
2. `bash ~/.claude/milestone-new-session.sh "$(pwd)" "<slug>"`

macOS: abre iTerm2/Terminal.app. Linux: muestra comando para copiar.

#### `/milestone done <name> <subtask>` — Completar subtarea
Fuzzy match en milestone y subtarea. Si subtarea ya `[x]` → advertir, no duplicar.

**MANDATORY — LEER COMPLETO**: Antes de marcar `[x]`, cargar y seguir [`references/qa-validation.md`](references/qa-validation.md) (3 fases: backend + frontend + diseño/Figma).
**NUNCA marcar `[x]` sin completar la validación QA. Si cualquier criterio falla, la subtarea queda pendiente.**

Edit mínimo: `old_string` = solo la línea del checkbox. No incluir contexto circundante.
Añadir entrada en `## Contexto` con resumen QA. Actualizar snapshot de memoria.

### Phase 4 — Review

#### `/milestone update <name>` — Actualizar tras sesión

Antes de actualizar, pregúntate:
- **¿Hay cambios sin commitear?** → `git status` — si hay, el trabajo está en curso, no completado
- **¿El usuario ha dicho qué hizo?** → Sí: usar su input. No: inferir de git log + archivos en contexto
- **¿Alguna subtarea se completó?** → Si hay evidencia clara (código existe, tests pasan): marcar `[x]` con QA. Si no hay certeza: preguntar antes de marcar

| Señal | Acción |
|-------|--------|
| Subtarea tiene código nuevo que cumple su "done" | Cargar [`references/qa-validation.md`](references/qa-validation.md), ejecutar QA, marcar `[x]` solo si pasa |
| Código parcial, subtarea a medias | Añadir nota en `## Contexto`, NO marcar `[x]` |
| Se tomó una decisión arquitectónica | Añadir en `## Decisiones` con fecha + razón |
| Se descubrió un problema nuevo | Añadir subtarea pendiente (pedir confirmación) |
| Se modificaron archivos no referenciados | Añadir en `## Referencias` |

Marcar `[x]`, añadir `## Contexto`, actualizar `## Referencias`. Sync memoria.

## Sync de memoria tras cada write

Regenerar snapshot compacto tras cualquier write/edit a `.milestones/`:
```
**<Nombre>** | <status> | <done>/<total> | <fecha>
Objetivo: <primera línea>
Pendiente: <lista [ ] o "(ninguna)">
Último avance: <primera línea del Contexto más reciente>
Archivos clave: <basenames, máx 6>
```
Destino: `~/.claude/projects/$(pwd | sed 's|/|-|g; s|^-||')/memory/milestone_<slug>.md`.
Crear pointer en `MEMORY.md` si es milestone nuevo.

**Si falla**: `mkdir -p` del directorio → reintentar → si persiste: advertir al usuario (milestone funciona sin memoria, solo más lento).

## Auto-status
Recalcular en cada write: todos `[x]` → `completed`, algunos → `in-progress`, ninguno → `not-started`. Actualizar frontmatter `status` y `updated`. Errores de formato → [`references/errors.md`](references/errors.md).

## Freedom calibration

| Operación | Libertad | Motivo |
|-----------|----------|--------|
| init (definir subtareas) | **Alta** | Múltiples descomposiciones válidas, creatividad en estructura |
| load (mostrar estado) | Media | Formato definido pero juicio en qué destacar al usuario |
| done (marcar checkbox) | **Baja** | QA obligatoria → Edit exacto si pasa, bloquear si falla |
| update (registrar trabajo) | Media-baja | Inferir con evidencia (git, contexto), preguntar ante duda, nunca inventar |
| start (nueva sesión) | **Baja** | Script exacto, sin interpretación |

## Edge cases

| Situación | Acción |
|-----------|--------|
| `.milestones/` no existe | Sugerir `/milestone init <nombre>` |
| Fuzzy match ambiguo (2+ resultados) | Mostrar opciones numeradas, pedir elección |
| Fuzzy match sin resultado | Listar todos los milestones disponibles |
| Subtarea ya `[x]` en `/milestone done` | Advertir, no marcar de nuevo |
| Path con espacios o acentos | Escapar con comillas en comandos bash |
| Milestone con >20 subtareas | Sugerir dividir en sub-milestones |
| `## Contexto` con >10 entradas | Las más antiguas pierden relevancia — sugerir archivar a `## Contexto archivado` |
| Snapshot de memoria con fecha < milestone | Regenerar desde archivo authoritative |
| Milestone stale (>30 días sin `updated`) | Flag ⚠️ en listing, preguntar si cerrar o retomar |
| Usuario quiere cerrar/cancelar/archivar con subtareas pendientes | Preguntar motivo. Marcar subtareas pendientes como `[-]` (cancelada) o dejar `[ ]`. Cambiar status a `completed` o `cancelled`. Añadir nota en Contexto con razón del cierre |
| QA falla pero usuario insiste en marcar done | Explicar qué falló, ofrecer fix. Si insiste: marcar `[x]` con `⚠️ QA parcial` en contexto |
| Subtarea depende de otra no completada | Advertir de la dependencia, sugerir completar la otra primero |

## NEVER
- **NUNCA** leer `.milestones/` si el snapshot de memoria tiene la información suficiente — duplica tokens sin aportar nada.
- **NUNCA** leer `.milestones/` + snapshot en la misma operación — el coste acumulado en 40 mensajes es 10x lo visible.
- **NUNCA** ejecutar subtarea `[complejo]` sin plan — la experiencia muestra que produce 6+ edits iterativos al mismo archivo, cada uno más caro que un plan previo.
- **NUNCA** leer `references/templates.md` en load/done/update — solo se necesita en init; cargarlo en otros comandos desperdicia ~900 tok.
- **NUNCA** usar `old_string` grande en Edit de checkbox — incluir contexto circundante causa fallos de unicidad y edits fallidos.
- **NUNCA** hacer 3+ Edits al mismo archivo — Write es 6x más barato cuando hay múltiples cambios (Edit reenvía el archivo entero en cada call).
- **NUNCA** crear milestone para trabajo de <1 hora — TodoWrite existe para eso; un milestone vacío ensucia el listing y nadie lo mantiene.
- **NUNCA** crear milestone sin verificar que no existe uno similar — dos milestones para lo mismo causan split-brain: el trabajo se trackea en uno pero no en otro.
- **NUNCA** guardar subtareas pendientes sin confirmación del usuario — las subtareas `[x]` son hechos verificables, pero las `[ ]` son el plan del usuario, no el tuyo.
- **NUNCA** marcar `[x]` sin pasar la validación QA — código "que debería funcionar" es la fuente #1 de bugs que el usuario descubre después.
- **NUNCA** dejar snapshot de memoria desactualizado tras write — la siguiente sesión arrancará con datos obsoletos y tomará decisiones equivocadas.
- **NUNCA** exceder 10 milestones activos simultáneos — más de 10 significa que ninguno recibe atención suficiente y todos se quedan stale.
- **NUNCA** borrar entradas de `## Contexto` — es append-only porque las sesiones futuras necesitan entender qué se intentó y por qué, incluyendo los errores.
