# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **You finished a feature across 3 conversations. The 4th starts from zero because context doesn't survive. And your teammate is working off a stale to-do list.**

milestone v2 is a persistent development tracker with a **two-tier cache**: compact memory snapshots (~100 tokens, auto-loaded) for instant status, and full authoritative files for deep history. It classifies subtasks as `[simple]` or `[complex]`, requiring a plan before executing complex work — preventing the expensive trial-and-error cycle of 6+ iterative edits on the same file. **Optional team mode (R13)** makes the milestone a single shared source of truth, git-synced to a canonical branch so the whole team always sees the same up-to-date list.

## Install

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## How it works

```
You: "/milestone dashboard"
        |
        v
(team mode) check canonical branch for a newer milestone first
        |
        v
Reads memory snapshot (zero file reads — already in context)
        |
        v
Displays: objective, pending subtasks, decisions, last context entry
        |
        v
Classifies subtasks: [simple] -> execute | [complex] -> plan first
        |
        v
After work: updates milestone file + regenerates memory snapshot
        |
        v
(team mode) git-syncs .milestones/ to the canonical branch
        |
        v
Next conversation / next teammate: instant, current context
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
- **Team mode (R13, opt-in)** — one shared milestone, git-synced to a canonical branch (default `develop`) via an isolated worktree, so the whole team reads/writes the same live list. Off by default.
- **Fuzzy matching** — type partial names to load milestones
- **Append-only context log** — reverse-chronological record of what happened and why
- **17 NEVER rules** — covering split-brain prevention, stale snapshots, edit anti-patterns, and team git-sync hazards

## Team mode (R13) — opt-in

Without this, the milestone is a per-machine local file. On a team that degrades into duplicated lists (every feature branch edits the same file) and stale to-do lists. Team mode makes the milestone a **single shared source of truth on a canonical branch**, edited only against that branch via a dedicated worktree — never inside code branches.

Enable per project in `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # absent or false -> the whole of R13 is a silent no-op
  branch: develop      # canonical branch (default: develop)
  path: .milestones     # synced subdir (default: .milestones)
```

- **On read** (`/milestone <name>`, `/milestone sync`): fetches the canonical branch and, if a teammate advanced the milestone, warns and offers to adopt it before you work.
- **On write** (init / update / done / session-end): after refreshing the snapshot, commits **only** `<path>/<slug>.md` and pushes it to the canonical branch through an isolated worktree under `.git/` — your code branch and working tree are never touched.
- **PR stamping**: a subtask whose work is in an open PR keeps its `[~]` state with an inline `` `⏳ PR #N` `` annotation (not a new state — `[~]` already means "code-complete, pending approval"; the PR is that approval's vehicle).
- **Graceful degradation**: no git / no remote / no canonical branch / block absent → silent no-op. The zero-dependency promise still holds.
- **Never bypasses guards**: if a push is blocked by a security guard or auth, the commit stays in the worktree and you get the exact command to run — it never silences the failure or blocks your work.

## Architecture

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-loaded, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTHORITATIVE (full history)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Plans for [complex] subtasks
<project-root>/.git/milestone-sync-wt/                     ← R13 isolated worktree (team mode only)
```

## What makes it different from v1

| Aspect | v1 | v2 |
|--------|----|----|
| Load cost | ~8,300 tok (Read full file + templates) | ~100 tok (memory snapshot) |
| Listing cost | ~8,750 tok (Read all files) | ~400 tok (frontmatter only, limit:8) |
| Complex subtasks | No gate — trial-and-error | Plan required before execution |
| Session management | Same conversation (context accumulates) | `/milestone start` opens fresh session |
| Reference loading | Always loads templates.md | Only on `/milestone init` |
| Team collaboration | None — local file only | Opt-in git-synced shared milestone (R13) |

## Evaluation

- **`/skill-judge`**: 120/120 (Grade A+)
- **`/skill-guard`**: 92/100 (GREEN) — no scripts executed during normal operation, no network, no MCP. R13 (opt-in, off by default) is the only path that performs git operations.

## Security

- By default, only reads/writes local `.milestones/*.md` and memory snapshot files. No network, no scripts during normal operation.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash is used for `/milestone start` (auto-installs script on first use) and, **only when team mode is explicitly enabled**, for `milestone-sync.sh` — which performs `git fetch`/`git push` limited to `<path>/` against the canonical branch via an isolated worktree. Disabled by default; never pushes code; never bypasses security guards (blocked push → reported, not silenced).
