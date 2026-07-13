---
name: milestone
description: "Use when tracking multi-session development work, resuming context from previous conversations, planning phased features, or capturing architectural decisions. Triggers: 'milestone', 'retomar', 'dónde lo dejé', 'seguimos con', 'estado del proyecto', 'qué falta', 'siguiente tarea', 'qué hicimos la última vez', 'pendientes', 'resume where we left off', 'what's left', 'mark as done', 'close milestone', 'sync milestones', 'audit the project', phased feature planning, subtask tracking, work-in-progress recovery. Portable across projects — no external dependencies. Commands: /milestone, /milestone <name>, /milestone init, /milestone sync, /milestone start, /milestone done, /milestone update."
allowed-tools: Read Write Edit Glob Grep Bash
---

# Milestone v2 — Persistent Development Context

**Pattern**: SKILL.md = **Process** (state machine, checkpoints). `references/` = **Tool** (exact procedures, decision trees). Body teaches WHEN; references teach HOW.

## Overview

Portable skill for multi-session development tracking. Manages state (`[ ]`/`[>]`/`[~]`/`[x]`/`[-]`), history (`## Contexto`), decisions, and memory snapshots. Zero external dependencies. Integrations (Monday/Jira/Linear/Slack) live in separate skills that observe `.milestones/*.md` via hooks. **Optional team mode (R13 + R14)**: opt-in via `.milestones/config.yml` makes the milestone a single shared source of truth git-synced to a canonical branch (R13) AND requires an atomic claim before starting any subtask so two members can never accidentally pick the same one (R14) — degrades to no-op when not configured, so the zero-dependency promise still holds. **Optional central storage (R13 §2b)**: opt-in by placing the config in the central memories repo (`~/.claude/projects/<key>/milestones/config.yml`) instead of the project repo — the client repo stays 100% clean of internal planning.

**Use when**: multi-session work OR need to resume context OR architectural decisions to remember. Otherwise → TodoWrite/Plan.

## Critical anti-patterns (TOP 3 — full list → [`references/anti-patterns.md`](references/anti-patterns.md))

1. **NEVER mark `[x]` without explicit human approval post-QA.** "pasa a la siguiente" / "ok" / "listo" are NOT approval — only "apruebo X.Y" / "marca como terminada" / "confirmed" count. Failed QA → stays `[~]`, never reverts.
2. **NEVER flip state based on intent.** Only advance AFTER verified evidence on disk (grep confirms symbol/route/method, git status lists file, phpcs/test pass). Prevents phantom progress when sessions get cut mid-work.
3. **NEVER close session with code changes without R11 session-end protocol.** Drift inherits to next start. Verify evidence → Edit milestone → `## Contexto` entry → refresh snapshot.

Los 14 anti-patterns restantes (read/tokens, rendering, sessions, numeración, archivos, git-sync) → [`references/anti-patterns.md`](references/anti-patterns.md).

## Subtask states (one-liner — full model → [`references/states.md`](references/states.md))

| Estado | Significado | Quién marca |
|--------|-------------|-------------|
| `[ ]` | No iniciada — sin evidencia | init / sync |
| `[>]` | En curso — ≥1 wave/archivo verificado, faltan otras. En team mode: claim atómico vía `🔒 <handle>` antes de tocar código (R14) | update / sync / R11 / R14 claim |
| `[~]` | Code-complete — pendiente aprobación post-QA | update / sync / R11 |
| `[x]` | Aprobada explícitamente por el usuario post-QA | done (solo con aprobación) |
| `[-]` | Cancelada | user only |

Transiciones legales, edge cases (dependencia en cadena, wave parcial, session crash, abandoned start) y downgrade rules → [`references/states.md`](references/states.md).

## Rules (R1–R14)

**R1. Two-tier storage**: `~/.claude/projects/<project>/memory/milestone_<slug>.md` (HOT ~100 tok) + AUTHORITATIVE en `<root>/.milestones/<slug>.md` (clásico) **o**, en modo central, `~/.claude/projects/<key>/milestones/<slug>.md` (repo central de memorias — el repo del proyecto queda limpio; discovery automático, detalle → [`references/git-sync.md`](references/git-sync.md) §2b). Si existen ambos, gana el clásico (migración pendiente). Every write to auth → refresh snapshot.

**R2. 5-state model** → [`references/states.md`](references/states.md).

**R3. Numbering `X.Y`**: `X`=phase, `Y`=position (sequential, no gaps). Insert → renumber siblings. Legacy sin numeración → añadir en siguiente `/milestone update`.

**R4. Hours prohibited on subtask lines.** `[Dept]` label carries context. Hours go in `.milestones/plans/` o `## Contexto`. Exception: user explicit request.

**R5. Complexity**: `[simple]` (1 file, sin dependencias) → execute. `[complejo]` (2+ files, refactor, integración) → BLOCKING plan in `.milestones/plans/<slug>-<subtask>.md` first.

**R6. Project config** (MANDATORY): `.milestones/config.yml` (o `<key>/milestones/config.yml` en modo central) define `project_type` (drupal/laravel/react/…) + `roles` (lista válida). Si no existe → Step 0→A→D en `/milestone init` antes de crear subtareas. Presets → [`references/roles-presets.md`](references/roles-presets.md).

**R7. Listing rendering** (two blocks): (A) summary table con `YYYY-MM-DD HH:MM`, (B) per-milestone breakdown. MANDATORY load [`references/rendering-rules.md`](references/rendering-rules.md). En team mode (R14) → OBLIGATORIO ejecutar `milestone-sync.sh claims` para enriquecer el render con claimers visibles.

**R8. Session discipline**: 1 subtask = 1 new window (fuera de IDE). Pre-start sync OBLIGATORIO antes de `/milestone start`. IDE → solo texto `/milestone start <slug>`, nunca bash script. En team mode (R14): claim atómico en sesión origen ANTES de mostrar el comando para nueva ventana.

**R9. QA gate for `[x]`**: MANDATORY load [`references/qa-validation.md`](references/qa-validation.md) antes de `/milestone done`. Falla QA → stays `[~]`.

**R10. Freedom calibration**: init=alta, sync/load=media, update=media-baja, done=baja, start=baja, R11=muy baja, R12=media, R13=baja (sync mecánico, sin decisiones de estado), R14=baja (claim mecánico, atomicidad delegada a git FF).

**R11. Session-end protocol (si hubo código)**: detect evidence → adjust checkbox → `## Contexto` entry → refresh snapshot → optional commit → R13 git-sync si team mode → R14 release del claim (al promover `[>]`→`[~]` la anotación 🔒 se retira). Detalle → [`references/session-protocol.md`](references/session-protocol.md).

**R12. Session-start recovery**: trigger si snapshot >2h o sin cierre limpio. Mini-sync (git log + grep) → compare con checkbox → downgrade/upgrade con confirmación. Detalle → [`references/session-protocol.md`](references/session-protocol.md).

**R13. Git-synced milestone (opt-in, team mode)**: si `config.yml` define `milestone_sync.enabled: true`, el milestone es propiedad compartida en una rama canónica (`milestone_sync.branch`, default `develop`; en modo central, la rama del repo central — default su HEAD, normalmente `main`). Lectura comprueba versión remota antes de mostrar/auditar; escritura sincroniza vía worktree aislado tras refrescar snapshot; un PR sella la subtarea `[~]` con `` `⏳ PR #<n>` ``. **Modo central (§2b)**: config y archivos autoritativos en `~/.claude/projects/<key>/milestones/` — el sync y los claims serializan contra el repo central de memorias, no contra el repo del cliente. **Degrada a no-op** sin git/remoto/rama o si el bloque está ausente (retrocompat total — la skill sigue portable y zero-dep). Detalle → [`references/git-sync.md`](references/git-sync.md).

**R14. Claim atómico (opt-in, requiere R13 team mode)**: arrancar una subtarea en team mode **exige un claim previo en la rama canónica antes de tocar código**. El claim sucede en la **sesión origen** (terminal padre o IDE Modo A) ANTES de abrir ventana nueva, no dentro de ella — así no queda ventana de carrera entre "el usuario ve el comando" y "abre la nueva ventana". `/milestone start` invoca `milestone-sync.sh claim <root> <slug> <X.Y>` que pone `[ ]`→`[>]` y añade `` `🔒 <handle> · YYYY-MM-DD HH:MM` `` inline, commiteando atómicamente en `<branch>`. Git fast-forward push es el lock: dos miembros que claimean a la vez serializan; el perdedor recibe `race-lost:<handle>` y elige otra. **`/milestone` (list) en team mode es OBLIGATORIO consultar `milestone-sync.sh claims` antes de renderizar** — sin eso, el listing puede mostrar como libre algo ya reservado por otro. Subcomandos: `claim`/`release`/`claims`/`stale`. Sin team mode → no-op, modelo clásico de estados sigue válido. Detalle → [`references/git-sync.md`](references/git-sync.md) §11 y [`references/states.md`](references/states.md) "Claim atómico".

## Workflow

7 commands × 4 phases. Full specs → [`references/commands.md`](references/commands.md).

| Phase | Command | Purpose | MANDATORY refs |
|-------|---------|---------|----------------|
| Discovery | `/milestone` (list) | Two-block output con (A)+(B); team mode → consulta `claims` antes de render | `rendering-rules.md` + `git-sync.md` si team mode |
| Discovery | `/milestone <name>` | Load context; trigger R12 si stale; R13 check + R14 claims si team mode | `session-protocol.md` si R12; `git-sync.md` si team mode |
| Planning | `/milestone sync` | Audit code vs milestones | `project-audit.md` + `roles-presets.md` si legacy + `git-sync.md` si team mode |
| Planning | `/milestone init <name>` | Create new; verify codebase antes de asignar estados | `templates.md` + `roles-presets.md` si no hay config |
| Execution | `/milestone start <name>` | Claim en sesión origen (team mode) → nueva sesión limpia | `session-protocol.md` si R12 triggered; `git-sync.md` si team mode |
| Execution | `/milestone done <name> <X.Y>` | Close subtarea; solo con aprobación explícita; retira `🔒` y `⏳ PR` | `qa-validation.md` |
| Execution | `/milestone release <name> <X.Y>` | (R14 team mode) liberar claim propio o ajeno (`--force`) | `git-sync.md` |
| Review | `/milestone update <name>` | Promote estados on evidence, normalize numbering | Ninguna — contexto ya cargado |

Ejemplo end-to-end (R11+R12, modo A/B del IDE, wave counter) → [`references/examples.md`](references/examples.md).

## Reference Loading Guide

| Comando | Cargar | Do NOT load |
|---------|--------|-------------|
| `/milestone` (list) | Solo snapshots ya en contexto; si team mode → OBLIGATORIO ejecutar `milestone-sync.sh claims` antes de render | All references, `.milestones/` completos |
| `/milestone <name>` | Snapshot; `session-protocol.md` si R12 triggered; `git-sync.md` si team mode; ejecutar `check` + `claims` | `.milestones/` si memoria suficiente |
| `/milestone init` | `templates.md` + `roles-presets.md` si no hay config + `project-audit.md` si hay doc | `qa-validation.md`, `errors.md` |
| `/milestone sync` | `project-audit.md` + `roles-presets.md` si legacy + `git-sync.md` si team mode | `templates.md`, `errors.md` |
| `/milestone start` | `git-sync.md` si team mode (claim antes de abrir ventana nueva) | Others |
| `/milestone done` | `qa-validation.md` | `templates.md`, `errors.md` |
| `/milestone release` | `git-sync.md` (sólo aplica en team mode) | Others |
| `/milestone update` | Ninguna | All references |
| Rendering listing | `rendering-rules.md` | `commands.md` si solo render |
| Detalle de flujos | `commands.md` | `rendering-rules.md` |
| Modificar checkbox states | `states.md` | `examples.md` si transición clara |
| Cierre sesión con código | `session-protocol.md` | Others |
| Inicio sesión milestone stale | `session-protocol.md` | Others |
| Trigger detection dudosa | `triggers-catalog.md` | Others |
| Crear/regenerar snapshot | `snapshot-format.md` | Others |
| Anti-pattern check | `anti-patterns.md` | Others |
| Git-sync milestone (team mode: lectura/escritura/sello PR/claim; modo central §2b) | `git-sync.md` | Others |
| install context-guard | `context-guard.sh` | Others |
| Corrupción detectada | `errors.md` | Others |

## Snapshot format

Formato compacto (~100 tok) y expandido (para >6 subtareas o fases) + destino del archivo + pointer en `MEMORY.md` → [`references/snapshot-format.md`](references/snapshot-format.md).

## Context Guard & Errors

- [`references/context-guard.sh`](references/context-guard.sh) — PreToolUse hook, warns at 20+/40+ tool calls. Install: `cp` + `chmod +x` + register in `settings.json`.
- [`references/milestone-sync.sh`](references/milestone-sync.sh) — R13/R14 helper (opt-in team mode; resuelve solo el modo central §2b). Subcomandos: `check`/`pull`/`push`/`stamp` (R13) + `claim`/`release`/`claims`/`stale` (R14). Auto-install on first sync: `cp ~/.claude/skills/milestone/references/milestone-sync.sh ~/.claude/milestone-sync.sh` + `chmod +x`. No-op si ninguna config trae `milestone_sync.enabled`.
- [`references/team-bootstrap.sh`](references/team-bootstrap.sh) — alta de un miembro del equipo en modo central: clona/actualiza el repo central de memorias, instala skill + helper y verifica la identidad git para los claims.
- [`references/errors.md`](references/errors.md) — format corruption, broken snapshots, missing frontmatter recovery.
- Common failure modes (troubleshooting table: síntoma → causa → fix) → [`references/errors.md`](references/errors.md).
