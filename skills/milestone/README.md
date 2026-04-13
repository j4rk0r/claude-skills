# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **You finished a feature across 3 conversations. The 4th starts from zero because context doesn't survive.**

milestone v2 is a persistent development tracker with a **two-tier cache**: compact memory snapshots (~100 tokens, auto-loaded) for instant status, and full authoritative files for deep history. It classifies subtasks as `[simple]` or `[complex]`, requiring a plan before executing complex work — preventing the expensive trial-and-error cycle of 6+ iterative edits on the same file.

## Install

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## How it works

```
You: "/milestone dashboard"
        |
        v
Reads memory snapshot (zero file reads — already in context)
        |
        v
Displays: objective, pending subtasks, decisions, last context entry
        |
        v
Classifies subtasks: [simple] → execute | [complex] → plan first
        |
        v
After work: updates milestone file + regenerates memory snapshot
        |
        v
Next conversation: instant context from memory, ready to continue
```

## Commands

| Phase | Command | Description |
|-------|---------|-------------|
| Discovery | `/milestone` | List all milestones with status and progress |
| Discovery | `/milestone <name>` | Load context (fuzzy match — "dash" finds "dashboard-propietario") |
| Planning | `/milestone init <name>` | Create new milestone with subtask proposals |
| Execution | `/milestone start <name>` | Open a fresh terminal session with compact context pre-loaded |
| Execution | `/milestone done <name> <subtask>` | Mark subtask complete with minimal edit |
| Review | `/milestone update <name>` | Bulk-update after a work session |

## Key features

- **Two-tier cache** — memory snapshot (~100 tok) for reads, authoritative file for full history. 99% cheaper than reading the full file every time.
- **Complexity classification** — `[simple]` (1 file, clear change) vs `[complex]` (multi-file, new logic). Complex subtasks are **blocked** until a plan exists.
- **Token efficiency rules** — 3+ changes to same file → single Write (10x cheaper than iterative Edits). No re-reading files already in context.
- **New session command** — `/milestone start` opens a fresh `claude` in a new terminal window with compact context, eliminating the 5-10x cost multiplier from accumulated conversation history.
- **Fuzzy matching** — type partial names to load milestones
- **Append-only context log** — reverse-chronological record of what happened and why
- **12 NEVER rules** — covering split-brain prevention, stale snapshots, and edit anti-patterns

## Architecture

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-loaded, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTHORITATIVE (full history)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Plans for [complex] subtasks
```

## What makes it different from v1

| Aspect | v1 | v2 |
|--------|----|----|
| Load cost | ~8,300 tok (Read full file + templates) | ~100 tok (memory snapshot) |
| Listing cost | ~8,750 tok (Read all files) | ~400 tok (frontmatter only, limit:8) |
| Complex subtasks | No gate — trial-and-error | Plan required before execution |
| Session management | Same conversation (context accumulates) | `/milestone start` opens fresh session |
| Reference loading | Always loads templates.md | Only on `/milestone init` |

## Evaluation

- **`/skill-judge`**: 120/120 (Grade A+)
- **`/skill-guard`**: 92/100 (GREEN) — no scripts executed during normal operation, no network, no MCP

## Security

- Only reads/writes local `.milestones/*.md` and memory snapshot files
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash only used for `/milestone start` (auto-installs script on first use)
