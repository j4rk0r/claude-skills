# Milestone Commands

Detalle completo de cada slash command.

## Phase 1 — Discovery

### `/milestone` — Listar todos

**Step 0 (R14 team mode) — OBLIGATORIO antes de renderizar**: Para CADA milestone listado, si `.milestones/config.yml` trae `milestone_sync.enabled: true`, ejecutar `milestone-sync.sh claims <root> <slug>`. Capturar el TSV `X.Y\thandle\tts` y usarlo en Step 3 para:
- Columna "Progreso": añadir `(K in flight by @h1, @h2, …)` con los claimers únicos.
- Render del bloque (B): cada `[>]` con `🔒` ajeno NO puede ser "siguiente sugerida"; el render añade `` `⚠️ no claimeable por ti` `` si el claimer ≠ tu handle (`git config user.email` substring antes de `@`).
- Si `claims` devuelve vacío → render normal sin marcas.
- Si `claims` devuelve `noop:disabled` (team mode off) → silencioso, render clásico.

SIN este Step 0 en team mode, el listing miente: dos personas pueden ver la misma subtarea como libre. NO es opcional.

**Step 1**: Si `.milestones/` no existe → sugerir `/milestone init <nombre>`.

**Step 2**: Usar snapshots de memoria (ya en contexto vía `MEMORY.md`) como fuente primaria. Si falta alguno, leer solo frontmatter (`limit:8`) de `.milestones/<slug>.md`. NUNCA leer archivo completo aquí.

**Step 3**: Renderizar (A) tabla resumen + (B) desglose por milestone según [`rendering-rules.md`](rendering-rules.md), incorporando los claims detectados en Step 0.

**Step 4**: Si hay >3 milestones en progreso → advertir dispersión, sugerir priorizar.

**Step 5**: Si última auditoría >14 días → sugerir `/milestone sync`.

### `/milestone <name>` — Cargar contexto

Fuzzy match: "dash" → "dashboard-propietario". Ambiguo → opciones numeradas. Sin match → listar disponibles.

**Step 0 (R13 team mode)**: si `.milestones/config.yml` trae `milestone_sync.enabled: true`, ejecutar `milestone-sync.sh check <root> <slug>` ANTES de mostrar contexto. `up-to-date`/`local-only`/`noop:*` → continuar. `remote-newer` → avisar ("otro miembro avanzó el milestone") y ofrecer `pull` antes de seguir. `diverged` → mostrar ambas cabeceras de `## Contexto` y pedir reconciliación; NUNCA auto-merge ni pisar la canónica. Detalle → [`git-sync.md`](git-sync.md) §4.

**Step 0b (R14 team mode)**: tras el `check`, ejecutar `milestone-sync.sh claims <root> <slug>`. Usar para enriquecer el contexto mostrado en Step 3-6: cada `[>]` claimeada por otro lleva visible "🔒 <handle> desde <ts>"; las propias también pero sin warning.

**Step 1**: Leer snapshot de memoria (zero reads — ya en contexto).
**Step 2**: Si no hay snapshot o desactualizado → leer `.milestones/<slug>.md`.
**Step 3**: Mostrar objetivo, progreso, pendientes `X.Y` (sin horas), último contexto, siguiente acción.
**Step 4**: Para `[complejo]` pendientes, indicar si tiene plan o hay que crearlo.
**Step 5**: Mostrar `[~]` como "pendiente de aprobación" y preguntar si aprueba.
**Step 6**: Verificar dependencias entre pendientes antes de sugerir siguiente. NUNCA sugerir una `[>]` con `🔒` ajeno como siguiente (es trabajo claimeado por otro miembro).

## Phase 2 — Planning

### `/milestone sync` — Auditoría proyecto vs milestones

**MANDATORY**: Cargar [`project-audit.md`](project-audit.md).

**R13 team mode**: si `.milestones/config.yml` trae `milestone_sync.enabled: true`, ejecutar `milestone-sync.sh check <root> <slug>` ANTES de auditar. Si `remote-newer`/`diverged`, reconciliar primero (adoptar la canónica o fusionar `## Contexto` —append-only por fecha, intercalar nunca borrar—). Auditar sobre la copia desactualizada produce un informe falso. Detalle → [`git-sync.md`](git-sync.md) §4.

**Si no existe `.milestones/config.yml`** o si existe `.milestones/roles.yml` (legacy): cargar también [`roles-presets.md`](roles-presets.md) y ejecutar migración Step 0→A→C antes de continuar.

Cruza doc técnico + codebase + milestones existentes para detectar:
- Milestones desactualizados (subtareas completadas sin marcar, código nuevo sin reflejar)
- Funcionalidades en doc técnico sin milestone
- Deuda técnica no trackeada
- Subtareas sin numeración `X.Y` (añadir, preservar orden)
- Horas en líneas de subtarea (limpiar, mover al plan si aporta)
- Subtareas sin etiqueta `[Dept]` (añadir)
- `[Dept]` con roles no presentes en `config.yml` (renombrar o añadir al config)
- Fases sin descripción breve en lenguaje llano (generar, sin prefijo, sin blockquote)
- Listings sin línea en blanco antes de primera fase (corregir)
- `[~]` con nota sin backticks inline (migrar a `` `⏳ pendiente aprobación (…)` ``)
- `roles.yml` legacy sin `project_type` → migrar a `config.yml` con defaults `project_type: drupal` + `industry: software-dev`
- (R14) Claims stale (>24h) → `milestone-sync.sh stale <root> <slug>` y reportarlos al usuario para decidir si liberar.

**Step 1 — Validar config**: Si falta `config.yml`, proponer al usuario: (a) aceptar defaults drupal + software-dev, (b) ejecutar flujo Step 0→A→D de roles-presets.md. No continuar sin config válida.

**Step 2 — Verificación de estados**: Para cada `[ ]`, grep/lectura del codebase usando patrones del `project_type` (ver roles-presets.md Step 0). Si hay evidencia de "done" → promover a `[~]`. Para `project_type: non-code`, verificar entregables listados en `## Referencias` en vez de código.

**Step 3 — Informe**: tabla ✅/🟡/🔴/⚠️ — qué milestones al día, cuáles desactualizados, qué falta. Incluir fila "config.yml" con ✅ válida / 🟡 migrada / 🔴 ausente. En team mode, incluir fila "claims stale" con lista de subtareas con claim >24h.

**Step 4**: ESPERAR confirmación antes de crear/modificar nada.

**Trigger automático**: `/milestone` list con >14 días desde última auditoría → sugerir sync.

### `/milestone init <name>` — Crear nuevo

Verificar no existe similar (nombre u objetivo) → si existe, sugerir añadir subtareas al existente.

**MANDATORY**: Cargar [`templates.md`](templates.md).

**Step 0 — Bootstrap de config** (si no existe `.milestones/config.yml`): Cargar [`roles-presets.md`](roles-presets.md) y ejecutar flujo Step 0→A→D:
- Step 0: preguntar/inferir `project_type` (drupal por defecto si no hay señal clara)
- Step A: para `project_type` software dev, proponer roles del preset del stack
- Step B: si `project_type: non-code` o usuario rechaza roles del stack, preguntar industria y proponer preset
- Step C: guardar `config.yml` tras confirmación
- Step D: a partir de aquí, todo `[Dept]` se valida contra `config.yml`

Sin `config.yml` válido → NO continuar a Step 1.

**Si hay doc técnico** (CLAUDE.md, docs/, spec): cargar [`project-audit.md`](project-audit.md) y ofrecer crear milestones necesarios de una vez.

**Step 1**: Extraer objetivo o preguntar.
**Step 2 — OBLIGATORIO Verificar codebase**: Para cada subtarea propuesta, grep/lectura usando patrones del `project_type` (roles-presets.md Step 0):
- Código cumple "done" → `[~]` (pendiente aprobación)
- Código parcial → `[~]` con nota "(parcial)" en Contexto
- Sin evidencia → `[ ]`
- `project_type: non-code` → verificar entregables (docs/, outputs/, archivos del dominio) en vez de código

**Step 3**: Proponer subtareas con `[simple]`/`[complejo]`, estado verificado, numeración `X.Y` en negrita, etiqueta `[Dept1, Dept2]` validada contra `config.yml`, definición de "done" verificable. Sin horas en líneas.

**Step 4**: Para cada fase, proponer descripción breve en lenguaje llano (1 línea, sin prefijo, sin blockquote, en cursiva).

**Step 5**: Para `[complejo]`, proponer plan antes de confirmar (el plan SÍ admite horas).

**Step 6**: ESPERAR confirmación.

**Step 7**: Crear `.milestones/<slug>.md` + snapshot de memoria + pointer en `MEMORY.md`. Si team mode (`milestone_sync.enabled`) → tras crear, `milestone-sync.sh push <root> <slug>` (ver "Sync de memoria tras cada write" → R13).

**Checkpoint final**: cada subtarea tiene "done" verificable, numeración `X.Y`, `[Dept]` presente en `config.yml`; cada fase tiene descripción; sin horas.

## Phase 3 — Execution

### Regla de sesión: 1 subtarea = 1 ventana nueva

**OBLIGATORIO fuera del IDE**: terminal nativo → cada subtarea abre ventana nueva ANTES de código.

**Detección IDE**: `TERM_PROGRAM=vscode`, `CURSOR_TRACE_ID`, `VSCODE_*`, o sección "VSCode Extension Context" en system prompt → NO mostrar comando bash, solo texto `/milestone start <slug>`.

**Flujo fuera del IDE** (terminal nativo):
1. Usuario pide trabajar subtarea (o Claude la sugiere).
2. **OBLIGATORIO Pre-start sync**: `/milestone update <slug>` SIEMPRE antes del start.
3. **R14 team mode — claim en sesión origen** ANTES de abrir ventana:
   a. `milestone-sync.sh check <root> <slug>` → reconciliar si `remote-newer`/`diverged`.
   b. `milestone-sync.sh claims <root> <slug>` → render libres vs claimeadas.
   c. Usuario elige una libre `X.Y`. Las claimeadas por otro NO son elegibles (warning).
   d. `milestone-sync.sh claim <root> <slug> <X.Y>` → si `claimed` continuar; si `race-lost` volver a (b).
4. `bash ~/.claude/milestone-new-session.sh "$(pwd)" "<slug>"` → abre ventana nueva con la subtarea YA claimeada.
5. Nueva sesión arranca con snapshot fresco (~100 tok) y ejecuta sobre la subtarea reservada.
6. Al terminar: `/milestone done` o `/milestone update`. El `done` libera implícitamente el claim al promover `[>]`→`[~]`.

**Flujo en IDE — dos modos**:

**Modo A — Sesión origen** (hay historial real previo al `/milestone start`):
1. `/milestone update <slug>` (refrescar `updated`, normalizar `X.Y`, regenerar snapshot).
2. **R14 team mode (si `milestone_sync.enabled: true`)** — claim en sesión origen:
   a. `milestone-sync.sh check <root> <slug>` → si `remote-newer`/`diverged`, reconciliar primero.
   b. `milestone-sync.sh claims <root> <slug>` → render de libres vs claimeadas.
   c. Preguntar al usuario qué subtarea libre `X.Y` quiere arrancar (`AskUserQuestion` con la lista).
   d. `milestone-sync.sh claim <root> <slug> <X.Y>` → `claimed` continúa; `race-lost:<handle>` o `already-claimed:<handle>` → avisar al usuario y volver a (b); `not-claimable:[~]` → aprobar primero con `/milestone done`.
3. Mostrar `/milestone start <slug>` para pegar en nueva ventana del plugin, con la subtarea YA claimeada en `develop` (visible para el equipo).
4. STOP — no cargar contexto aquí; la ventana nueva lo hará.

**Modo B — Sesión nueva** (este `/milestone start` es el primer mensaje real):
1. NO re-ejecutar pre-start sync (`updated` reciente de hace <10 min + entrada "Pre-start sync" en Contexto → confiar).
2. **R14 team mode**: cargar contexto con el claim ya hecho desde Modo A — la subtarea elegida aparece `[>]` con `🔒 <tu_handle>`. Si NO hay claim propio (caso raro: usuario forzó el comando sin pasar por Modo A), entonces ejecutar el flujo de claim aquí mismo igual que Modo A pasos (a-d) antes de arrancar.
3. Cargar contexto del snapshot (ya en `MEMORY.md`).
4. Mostrar: objetivo, `[~]` pendientes, subtarea claimeada actual, plan de trabajo.
5. NUNCA volver a mostrar "pegar en nueva ventana" — bucle infinito.

**Desempate A/B**: leer `updated`. <10 min + entrada "Pre-start sync" reciente → B. >1h o conversación con historial → A.

**Por qué pre-start sync obligatorio**: la nueva ventana solo ve el snapshot. Si está obsoleto, arranca con contexto malo. Sync refresca `updated`, recalcula status, normaliza `X.Y`, limpia horas, regenera snapshot.

**Por qué claim en sesión origen (Modo A)**: si el claim se hiciera en la ventana nueva, entre el momento en que el usuario ve el texto `/milestone start` y lo pega habría una ventana de carrera donde otro miembro puede claimear. Haciéndolo en origen, **la subtarea queda reservada en `develop` antes incluso de cambiar de ventana** — la nueva sesión solo trabaja sobre algo ya suyo.

**Por qué ventana nueva fuera de IDE**: contexto crece cuadráticamente; a 40 tool calls cada operación cuesta ~2x. Ventana nueva elimina esa inflación.

**Excepciones**:
- Subtarea a 1-2 tools de terminar → terminarla primero.
- "sigue aquí" explícito → respetar, advertir coste.
- Pre-start sync **NO tiene excepciones**.
- Claim en team mode **NO tiene excepciones**: sin claim previo, no se toca código.

### `/milestone start <name>` — Nueva sesión limpia

Precondición: `/milestone update <slug>` ANTES + (si team mode) claim atómico antes de abrir ventana nueva.

Script en [`milestone-new-session.sh`](milestone-new-session.sh). Auto-install: si `~/.claude/milestone-new-session.sh` no existe → copiar + `chmod +x`.

**R14 — Claim atómico ANTES de la nueva ventana (team mode)**: el claim sucede en la sesión origen (terminal padre o IDE Modo A) ANTES de abrir/mostrar la ventana nueva. La ventana nueva nunca se ve obligada a elegir subtarea — recibe una ya reservada. Si por excepción la ventana nueva arranca sin claim previo (Modo B sin Modo A), entonces ejecuta el flujo de claim antes de la primera línea de código. Detalle → [`git-sync.md`](git-sync.md) §11.

| Entorno | Modo | Acción |
|---------|------|--------|
| Terminal nativo | A | (1) `/milestone update` → (2) check + claims + claim → (3) `bash ~/.claude/milestone-new-session.sh "$(pwd)" "<slug>"` |
| IDE — sesión origen | A | (1) `/milestone update` → (2) check + claims + AskUserQuestion + claim → (3) NO script. Mostrar solo `/milestone start <slug>` |
| IDE — sesión nueva | B | NO pre-start sync. Snapshot trae claim ya hecho; cargar contexto y arrancar. Si no hay claim propio, ejecutar flujo de claim como excepción |

Salida IDE Modo A (con team mode + claim exitoso):
```
✓ Milestone actualizado.
✓ Subtarea X.Y claimeada en `develop` por @<tu_handle> · <ts>
  → otros miembros que abran el milestone ahora verán que la tienes tú.

El texto a pegar en una nueva ventana del plugin:

/milestone start <slug>
```

Salida IDE Modo A (claim fallido):
```
⚠️ No se pudo claimear X.Y:
   - already-claimed:<handle>   → @<handle> ya está trabajando en esto desde <ts>.
   - race-lost:<handle>          → @<handle> ganó la carrera mientras preparabas.
   - not-claimable:[~]/[x]       → la subtarea está más avanzada; revisa el listing.

Elige otra subtarea o ejecuta /milestone release <slug> X.Y --force si necesitas tomar el relevo.
```

Salida IDE Modo B:
```
📍 Milestone: <Nombre> — <status> — <done>/<total> (<pending> pending)
Objetivo: <primera línea>
🔒 Subtarea claimeada: X.Y — <nombre> (claimer @<tu_handle> desde <ts>)

Plan de trabajo para X.Y:
- ...
```

### `/milestone release <name> <X.Y> [--force]` — Liberar claim (R14)

Sólo aplica en team mode (R13 + R14). Quita la anotación `🔒` y devuelve la
subtarea de `[>]` a `[ ]`, sincronizando con la rama canónica.

- Sin `--force`: solo el claimer puede liberar su propio claim. Si lo intenta
  otro, `milestone-sync.sh release` devuelve `not-claimer:<handle>` y aborta.
- Con `--force`: cualquier miembro puede liberar el claim de otro (handover por
  abandono, vacaciones, etc.). Dejar entrada en `## Contexto` justificando el
  release forzado: a quién se le liberó, por qué.

Estados resultantes:
- `released` → confirmar.
- `not-claimed` → la subtarea no estaba `[>]` (probablemente race).
- `not-claimer:<handle>` → falta `--force` o handle equivocado.

Tras un `release`, el render del milestone refleja el cambio en el siguiente
listing/load. La subtarea queda lista para que otro la claimee.

### `/milestone done <name> <subtask>` — Completar

Fuzzy match. Preferible numeración `X.Y` (menos ambigua). Si ya `[x]` → advertir.

**MANDATORY**: Cargar [`qa-validation.md`](qa-validation.md) (3 fases: backend + frontend + diseño/Figma).

**NUNCA marcar `[x]` sin completar QA. Si falla, queda `[~]` (no `[ ]`).**

`[x]` solo tras confirmación humana explícita de aprobación. Si estaba en `[~]`, `/milestone done` es el cierre tras aprobación.

Edit mínimo: `old_string` solo la línea del checkbox. Si la línea tenía anotación `` `⏳ PR #<n>` `` (R13) o `` `🔒 <handle> · ts` `` (R14), retirarla en el mismo Edit. Añadir entrada en `## Contexto`. Actualizar snapshot. Si team mode → `milestone-sync.sh push <root> <slug>`.

Al promover `[>]`→`[~]` (cuando el trabajo termina pero aún sin aprobación
explícita), también retirar la anotación 🔒 — el claim ya cumplió su función
(coordinar el momento de arrancar). En `[~]` el contrato pasa a ser "pendiente
de aprobación / PR", y si abre PR se estampa con `⏳ PR #<n>`.

### Sello de PR (R13 — team mode)

Cuando se abre un PR que implementa una subtarea (y `milestone_sync.enabled: true`):
1. La subtarea debe estar `[~]` (si está `[>]`/`[ ]`, promover antes con evidencia — no saltar el modelo de estados).
2. `milestone-sync.sh stamp <root> <slug> <X.Y> <pr_number>` añade `` `⏳ PR #<n>` `` al final de la línea (parser-safe: no toca checkbox ni marcadores) y sincroniza a la rama canónica.
3. Al mergear el PR + aprobación humana explícita → `/milestone done` → `[x]` (la anotación se retira en ese Edit).

Ver [`git-sync.md`](git-sync.md) §7 y [`states.md`](states.md) (PR en vuelo).

## Phase 4 — Review

### `/milestone update <name>` — Actualizar tras sesión

Antes de actualizar, preguntar:
- ¿Cambios sin commitear? (`git status`) → en curso, no completado.
- ¿Usuario dijo qué hizo? Sí: usar input. No: inferir git log + archivos en contexto.
- ¿Subtarea completada con evidencia? Marcar `[~]` (NUNCA `[x]` — requiere aprobación).
- ¿Numeración `X.Y` intacta? Renumerar si hay huecos.
- ¿Horas en líneas? Limpiar.
- ¿Cada subtarea con `[Dept]`? Añadir si falta.
- ¿Cada fase con descripción breve? Generar si no.
- ¿Línea en blanco antes de cada fase? Corregir.
- ¿`[~]` con backticks inline? Migrar de `<sub>…</sub>`.

Tabla de señales:

| Señal | Acción |
|-------|--------|
| `[ ]` con código nuevo que cumple "done" | Promover `[~]` |
| `[~]` + usuario aprueba | Cargar qa-validation.md, QA, marcar `[x]` solo si pasa |
| Código parcial | `[~]` con nota "(parcial)" en Contexto |
| Decisión arquitectónica | Añadir `## Decisiones` con fecha + razón |
| Problema nuevo | Añadir subtarea con `X.Y` siguiente (pedir confirmación) |
| Archivos no referenciados | Añadir `## Referencias` |
| `X.Y` con huecos/duplicados | Renumerar secuencial |
| Horas en líneas | Eliminar; si hay valor histórico → `## Contexto` o plan |
| Subtareas sin `[Dept]` | Añadir |
| Fases sin descripción | Generar (sin prefijo, sin blockquote, cursiva pegada al título) |
| Blockquote o "Resumen sencillo:" en fase | Migrar al formato nuevo |
| Sin línea en blanco antes de primera fase | Añadir |
| `[~]` con `<sub>…</sub>` o sin realce | Migrar a `` `⏳ pendiente aprobación (…)` `` |
| (R14) `[>]` con `🔒` ajeno pero claimer no responde >24h | Sugerir `release --force` tras notificar |
| (R14) `[~]`/`[x]` con anotación `🔒` residual | Limpiar (la anotación 🔒 sólo aplica a `[>]`) |

Añadir `## Contexto`, actualizar `## Referencias`. Sync snapshot.

Frontmatter `updated` con **fecha + hora** ISO `YYYY-MM-DDTHH:MM`. Snapshot en formato `YYYY-MM-DD HH:MM`.

**Modo pre-start** (auto antes de `/milestone start`): Ejecutar aunque no haya trabajo aparente. Recalcular desde codebase, refrescar `updated`, normalizar `X.Y`, limpiar horas, regenerar snapshot. Si no hay cambios, dejar archivo pero SIEMPRE regenerar snapshot.

## Sync de memoria tras cada write

Regenerar snapshot compacto tras cualquier write/edit a `.milestones/`:
```
**<Nombre>** | <status> | <done>/<total> (<pending> pending) | <YYYY-MM-DD HH:MM>
Objetivo: <primera línea>
Pendiente aprobación [~]: <lista X.Y o "(ninguna)">
No iniciadas [ ]: <lista X.Y o "(ninguna)">
En curso por mí [>] (R14): <lista X.Y o "(ninguna)">
En curso por otros [>] (R14): <lista X.Y@handle o "(ninguna)">
Último avance: <primera línea del Contexto más reciente>
Archivos clave: <basenames, máx 6>
```

Marca temporal con hora siempre (`YYYY-MM-DDTHH:MM` en frontmatter; `YYYY-MM-DD HH:MM` en snapshot). Alimenta columna "Actualizado" del listing.

**Snapshot ampliado** (recomendado con >6 subtareas o agrupación por fases): incluir listado completo con `X.Y` + checkbox + complejidad + departamento + descripciones de fase. Permite renderizar bloque (B) sin leer `.milestones/`.

Destino: `~/.claude/projects/$(pwd | sed 's|/|-|g; s|^-||')/memory/milestone_<slug>.md`.
Crear pointer en `MEMORY.md` si es nuevo.

Si falla: `mkdir -p` → reintentar → persistir: advertir usuario (milestone funciona sin memoria, solo más lento).

### R13 — Sincronización al repo (opt-in team mode)

Si `.milestones/config.yml` trae `milestone_sync.enabled: true`, INMEDIATAMENTE después de regenerar el snapshot, ejecutar también `milestone-sync.sh push <root> <slug>`:

- `pushed` → confirmar en una línea ("milestone sincronizado a `<branch>`").
- `commit-pending-push:<cmd>` → el commit en el worktree está hecho; el push lo bloqueó el guard de seguridad / auth / protección. Avisar con el comando exacto; NO reintentar en bucle; NO bloquear ni revertir la operación de milestone.
- `noop:<razón>` → silencioso (degradación; ver matriz en [`git-sync.md`](git-sync.md) §8).

NO requiere confirmación del usuario (solo toca `.milestones/`, rama canónica, worktree aislado bajo `.git/`). El commit del **código** es aparte y SÍ requiere confirmación. Auto-install del helper en el primer uso: `cp ~/.claude/skills/milestone/references/milestone-sync.sh ~/.claude/milestone-sync.sh && chmod +x ~/.claude/milestone-sync.sh`. Detalle completo → [`git-sync.md`](git-sync.md).

## Auto-status (recalcular en cada write)

- Todos `[x]` → `completed`
- Mezcla `[x]`/`[~]`/`[ ]` → `in-progress`
- Todos `[ ]` sin `[~]` ni `[x]` → `not-started`
- `[~]` sin `[x]` sin `[ ]` → `in-progress` (hay evidencia, falta aprobación)

Actualizar frontmatter `status` y `updated`. Errores → [`errors.md`](errors.md).
