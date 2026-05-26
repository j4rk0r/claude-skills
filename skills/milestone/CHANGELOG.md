# Changelog — milestone skill

Cambios visibles a usuarios del skill. Cada versión documenta qué se añade, qué se modifica y qué hay que hacer para migrar.

## [1.1.0] — 2026-05-26 — R14 claim atómico (team mode)

### Añadido

- **R14: claim atómico de subtareas** (opt-in, requiere `milestone_sync.enabled: true` ya activado por R13).
  - Al ejecutar `/milestone start` en team mode, el sistema **reserva la subtarea en la rama canónica antes de tocar código**. La línea pasa de `[ ]` a `[>]` con anotación inline `` `🔒 <name> (<handle>) · YYYY-MM-DD HH:MM` ``.
  - Atomicidad garantizada por `git push --fast-forward`: dos miembros que claimean a la vez serializan. El perdedor recibe `race-lost:<handle>` tras rebase y elige otra subtarea. Imposible doble claim.
  - Live check obligatorio: `claim` hace `git fetch` antes de cualquier decisión; si el fetch falla (sin red) → `noop:fetch-failed`, NO claimea contra stale.
- **Nuevos subcomandos en `milestone-sync.sh`**:
  - `claim <root> <slug> <X.Y>` — reserva atómica.
  - `release <root> <slug> <X.Y> [--force]` — libera. Sin `--force` solo el claimer puede liberar.
  - `claims <root> <slug>` — TSV `X.Y\thandle\tts` de claims activos.
  - `stale <root> <slug> [hours]` — claims con edad > umbral (default 24h).
- **Comando nuevo `/milestone release <name> <X.Y>`** para liberación manual.
- **Documentación**:
  - SKILL.md: regla R14 + tabla Workflow actualizada con `/milestone release` + Reference Loading Guide.
  - `references/states.md` — sección "Claim atómico (R14)" con modelo claimer + claimed_at.
  - `references/git-sync.md` — §11 "Claim atómico" con flujo, carrera, release, stale, justificación de no usar lock external.
  - `references/commands.md` — `/milestone` (list) Step 0 OBLIGATORIO consulta `claims`; `/milestone <name>` Step 0b idem; `/milestone start` Modo A IDE hace claim ANTES de mostrar texto para nueva ventana.
  - `references/rendering-rules.md` — `[>]` con `🔒` ajeno marca `⚠️ no claimeable por ti`, columna Progreso muestra `(K in flight by @h1, @h2)`.
  - `references/session-protocol.md` — R11 paso 7 (manejo del claim al cerrar) + R12 paso 6 (stale claim detection).
  - `references/anti-patterns.md` — 3 nuevos NEVERs (#18 editar `🔒` a mano, #19 código sin claim, #20 `release --force` sin avisar).
  - `references/examples.md` — Ejemplos 5 y 6 (claim two-actor; handover con `release --force`).
  - `references/errors.md` — Tabla de outputs `claim`/`release`/`claims`/`stale`.

### Modificado

- Estado `[>]` ahora tiene dos variantes en team mode:
  - `[>]` sin `🔒` → en curso por trabajo verificado (modelo clásico, válido también sin team mode).
  - `[>]` con `🔒` → en curso y reservado explícitamente vía claim atómico.
- Formato del claimer ampliado de `<handle>` a `<nombre completo> (<handle>)` para identidad legible.
- `/milestone done` retira tanto `⏳ PR #<n>` (R13) como `🔒 <handle> · ts` (R14) en el Edit de cierre.

### Sin cambios

- Comportamiento offline / sin team mode → **idéntico al 1.0.x**. R14 degrada a no-op silencioso si `milestone_sync.enabled` no está activo.
- API de subcomandos antiguos (`check`, `pull`, `push`, `stamp`) — sin cambios de breaking.

### Cómo actualizar (para miembros del equipo)

1. `git pull` del repo donde vive el skill (`~/.claude/skills/milestone/`) o copia manual de los archivos.
2. La primera vez que se ejecute `/milestone start` o cualquier subcomando que necesite el helper, se auto-instala la nueva versión en `~/.claude/milestone-sync.sh`. Si quieres forzar manualmente:
   ```bash
   cp ~/.claude/skills/milestone/references/milestone-sync.sh ~/.claude/milestone-sync.sh
   chmod +x ~/.claude/milestone-sync.sh
   ```
3. Verificar que tu proyecto tiene `milestone_sync.enabled: true` en `.milestones/config.yml`. Si no, R14 será no-op (igual que R13).
4. Probar: `milestone-sync.sh claims <root> <slug>` → debe devolver vacío (o lista TSV si ya hay claims) sin errores.

### Prerequisitos

- `git`, `bash`, `python3` (para parseo UTF-8 robusto). Todos disponibles en macOS y Linux modernos por defecto.
- Repo del proyecto con remoto `origin` y rama canónica configurada (`milestone_sync.branch`, default `develop`).

### Migración desde 1.0.x

Ningún cambio destructivo. Los milestones existentes siguen funcionando idénticamente. Activación de R14:

- Si tu proyecto ya tiene `milestone_sync.enabled: true`, R14 se activa automáticamente.
- Si solo quieres R13 (sin claim atómico), no hay forma de desactivar R14 selectivamente — pero `claim` solo se invoca si tú llamas `/milestone start`; nunca actúa por su cuenta.

---

## [1.0.x] — 2026-05-19 y anteriores

Versión inicial con:
- 5-state model (`[ ]`, `[>]`, `[~]`, `[x]`, `[-]`).
- Two-tier storage (snapshot HOT + autoritative `.milestones/`).
- 7 comandos: `/milestone` listado, `<name>` load, `init`, `sync`, `start`, `done`, `update`.
- R11 (session-end) + R12 (session-start recovery).
- R13 (git-synced milestone, opt-in team mode) con `milestone-sync.sh`.

Para detalle de R1–R13 originales, ver SKILL.md y `references/states.md`.
