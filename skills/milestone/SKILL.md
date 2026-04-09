---
name: milestone
description: "Persistent development milestone tracker with full context that survives across conversations. Each milestone is a self-contained development capsule: objective, subtasks with status, architectural decisions, code references, and a running log of what was done and why. Use this skill whenever the user says '/milestone', mentions tracking development progress, wants to plan a feature with subtasks, asks 'what's left to do on X', wants to break work into trackable pieces, needs to resume work from a previous conversation, or references a specific milestone by name. Also trigger after completing significant work to update the active milestone's context and task status."
allowed-tools: Read Write Edit Glob Grep
---

# Milestone — Persistent Development Context

A milestone is a **development capsule**, not a task list. It persists the full context of a development effort across conversations: objective, subtasks, decisions, code references, and a running log of what happened and why. Loading a milestone in a new chat is like having the previous developer brief you in person.

## Core mindset

Before any milestone operation, think:

- **"Will the next conversation understand this?"** — Every update should make the file more useful for a future session that has zero context.
- **"Is this worth a milestone?"** — Milestones are for work that spans multiple sessions. Single-session tasks belong in Plan mode or TodoWrite.
- **"What would I wish I'd written down?"** — The decisions and dead-ends matter as much as the completed tasks.

## Scope: global skill, project-local data

Milestone data lives in `<project-root>/.milestones/`. Each project has independent milestones — never cross-pollinate. On first invocation, create the directory and suggest `/milestone init <nombre>`.

## NEVER

- **NEVER create a milestone for tasks under 1 hour** — use TodoWrite or Plan mode. Milestones are for multi-session work. Creating trivial milestones dilutes the system and nobody will maintain them.
- **NEVER duplicate an existing milestone** — search first. If a similar one exists, add subtasks to it. Duplicate milestones cause split-brain: work gets tracked in one but not the other, and both become unreliable.
- **NEVER delete context entries** — the log is append-only. If something was wrong, add a correction entry. Deleting history breaks the narrative for future sessions that need to understand what was tried and why it failed.
- **NEVER leave a milestone without updated context after work** — a stale milestone is worse than no milestone. It gives false confidence about the state of things. If you did work, log it.
- **NEVER hardcode absolute paths in Referencias** — always relative to project root. Absolute paths break when the project moves or another developer clones it.
- **NEVER exceed 10 active milestones** — if there are more, some should be closed or merged. Too many milestones means none get maintained properly.
- **NEVER modify frontmatter status manually** — let auto-status calculate it from subtask checkboxes. Manual status diverges from reality.
- **NEVER create subtasks without a clear "done" definition** — "work on dashboard" is useless. "Implement routing with dynamic MenuTree links" tells you exactly when it's done.

## Integration with planning tools

The milestone defines **WHAT** needs doing. Planning tools define **HOW**.

### Workflow: milestone → plan → execute → update milestone

1. Load milestone → pick a pending subtask
2. Before planning, **discover available planners** — scan installed skills for:
   - **Plan mode** (Claude built-in) — interactive checklist, good for medium subtasks
   - **`/writing-plans`** — structured step-by-step from specs
   - **`/gepetto`** — multi-LLM review, for complex subtasks
   - **`/brainstorming`** — explore requirements first, for ambiguous subtasks
   - **`/subagent-driven-development`** — parallel execution of independent pieces
3. Present available planners:
   ```
   Sistemas de planificacion disponibles:
   1. Plan mode (Claude) — ideal para subtareas medianas
   2. /writing-plans — ideal con spec clara
   3. /gepetto — ideal para subtareas complejas
   ¿Quieres que use todos y unifique en un unico listado? ¿O prefieres uno?
   ```
4. If user says "todos" → run each planner, merge outputs into deduplicated subtask list, mark which planner proposed each item, present for approval
5. After execution: mark subtasks `[x]`, add context entry, update references

### With other skills

Record outcomes from `/qa-test-planner`, `/codex-pr-review`, `/commit-work`, `/monday-sync`, etc. as context entries. The milestone is the persistent record; other skills are transient.

### The golden rule

After meaningful work on an active milestone, **always update**: subtasks `[x]`, new decisions in `## Decisiones`, modified files in `## Referencias`, and a dated entry in `## Contexto`.

## Commands

### `/milestone` (no arguments) — List all

Read `.milestones/*.md`, parse frontmatter and subtasks, display:

```
## Hitos del proyecto

| Estado | Hito | Objetivo | Progreso | Actualizado | |
|--------|------|----------|----------|-------------|-|
| 🟡 | Dashboard Propietario | Panel con links dinamicos | 3/7 | 2026-04-09 | → `/milestone dashboard-propietario` |
| 🔴 | Catalogo Productos | Listado filtrable | 0/5 | 2026-04-07 | → `/milestone catalogo-productos` |
```

Status: 🟢 completed, 🟡 in-progress, 🔴 not-started. Flag milestones with `updated` >30 days ago: "⚠️ sin actividad".

### `/milestone <name>` — Load context

Fuzzy match against filename/name field. Display all sections, then suggest next subtask with available planners. If all done: *"Todas completadas. ¿Cerramos el hito?"*

**This is the most critical command.** The output must be a complete briefing — enough for a developer with zero prior context to start working immediately.

**MANDATORY**: Read [`references/templates.md`](references/templates.md) for the exact display format when loading a milestone for the first time in a session.

On ambiguous match → show options. On no match → list available milestones.

### `/milestone init <name>` — Create new

1. Create `.milestones/` if needed
2. Extract or ask for objective
3. Analyze codebase for current state relevant to the objective
4. Propose subtasks (each with clear "done" definition)
5. Let user adjust, then save

**MANDATORY**: Read [`references/templates.md`](references/templates.md) for the file structure.

### `/milestone add <name> <content>` — Add content

Detect type: `tarea:` → subtask, `decision:` → decision with date, `nota:` → context entry, `ref:` → reference. Ambiguous → ask. Auto-recalculate status.

### `/milestone done <name> <subtask>` — Complete subtask

Fuzzy match both milestone and subtask text. Mark `[x]`, add context entry with what was done, recalculate status. Show updated progress.

### `/milestone update <name>` — Bulk session update

After a work session: read milestone, infer or ask what was accomplished, mark subtasks, add context entries, update references. This is the end-of-session command.

## Auto-status

Recalculate on every write: all `[x]` → `completed`, some → `in-progress`, none → `not-started`.

**MANDATORY**: On any file issue (corrupted frontmatter, malformed checkboxes, status mismatch), read [`references/errors.md`](references/errors.md) for the recovery procedure. Do NOT guess — the error handling covers all common cases.

## Critical behaviors

1. **Read before write** — never assume current state.
2. **Fuzzy match** — "dash" matches "dashboard-propietario". Ambiguous → show options.
3. **Append-only context** — never delete, only add corrections.
4. **Track references** — every file created/modified gets added to `## Referencias`.
5. **Suggest next actions** — after loading, recommend which subtask to tackle based on logical dependencies.
6. **Capture outcomes** — when Plan mode or other skills produce results, persist them in the milestone.
