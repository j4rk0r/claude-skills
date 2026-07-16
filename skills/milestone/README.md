# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **You finished a feature across 3 conversations. The 4th starts from zero because context doesn't survive. And your teammate is working off a stale to-do list.**

milestone v2 is a persistent development tracker with a **two-tier cache**: compact memory snapshots (~100 tokens, auto-loaded) for instant status, and full authoritative files for deep history. It classifies subtasks as `[simple]` or `[complex]`, requiring a plan before executing complex work — preventing the expensive trial-and-error cycle of 6+ iterative edits on the same file. **Optional team mode (R13 + R14)** makes the milestone a single shared source of truth, git-synced to a canonical branch so the whole team always sees the same up-to-date list — and **atomically reserves subtasks via the canonical branch BEFORE anyone touches code**, so two members can never accidentally pick the same one.

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
- **Central storage mode (v1.2.0, opt-in)** — config and authoritative files live in the central memories repo (`~/.claude/projects/<key>/milestones/`) instead of the project repo: **client repos carry zero internal planning**. Auto-discovered; classic local mode always takes precedence. Team onboarding via `references/team-bootstrap.sh`.

## Team mode (R13 + R14) — opt-in

Without this, the milestone is a per-machine local file. On a team that degrades into duplicated lists (every feature branch edits the same file) and stale to-do lists. Team mode makes the milestone a **single shared source of truth on a canonical branch**, edited only against that branch via a dedicated worktree — never inside code branches. It **discovers milestones other members created** before you list or create one (so you never duplicate `foo` when a teammate made it a minute ago), and it **reserves each subtask atomically** the moment someone starts working on it — so two people never end up doing the same thing, and the system tells you *who* got there first.

Enable per project in `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # absent or false -> the whole of team mode is a silent no-op
  branch: develop      # canonical branch (default: develop)
  path: .milestones     # synced subdir (default: .milestones)
```

### R13 — shared source of truth

- **On read** (`/milestone <name>`, `/milestone sync`): fetches the canonical branch and, if a teammate advanced the milestone, warns and offers to adopt it before you work.
- **On write** (init / update / done / session-end): after refreshing the snapshot, commits **only** `<path>/<slug>.md` and pushes it to the canonical branch through an isolated worktree under `.git/` — your code branch and working tree are never touched.
- **PR stamping**: a subtask whose work is in an open PR keeps its `[~]` state with an inline `` `⏳ PR #N` `` annotation.

### R14 — atomic claim before touching code

When you run `/milestone start`, the system **reserves the subtask in the canonical branch BEFORE you touch any code**. The line becomes `[>]` with an inline annotation:

```
- [>] 1.4 [complex] Stripe integration — `🔒 Jane Doe (jdoe) · 2026-05-26 15:01` [Backend]
```

- **Atomic via `git push --fast-forward`**: if two members try to claim the same subtask at the same time, only one fast-forward push wins. The loser fetches, re-validates, sees the winner's claim and aborts with `race-lost:<winner>` — it tells you exactly who took it. If the other member had already published the claim, you get `already-claimed:<winner>` up front. Impossible to double-claim.
- **Retry loop, not a single try**: on a lost fast-forward the claim rebases and re-validates up to 5 times, so with 3+ simultaneous claimers a misleading `commit-pending-push` never shows up — that status now means only a real push problem (auth / protected branch / network).
- **Live verification mandatory**: `claim` does `git fetch` and aborts with `noop:fetch-failed` if the network check fails. No claiming against stale local data.
- **`/milestone` listing in team mode must consult claims**: the list of milestones shows who has what reserved. A subtask claimed by someone else can never appear as "free" for you.
- **Audit trail**: every claim/release is a dedicated commit on `<branch>` (`chore(milestone): claim <slug> <X.Y> by <Jane Doe (jdoe)>`). The branch history *is* the team's coordination log.
- **Stale claims surfaced on start**: if everything free is taken but a claim is older than 24h, `/milestone start` suggests the conscious override (`release --force` + re-claim) instead of only listing it.
- **Handover via `/milestone release <slug> <X.Y> --force`** when needed (vacation, machine down, refusal). Add a note in `## Contexto` justifying the forced release; the original claimer sees `not-claimed` next time.

### Index sync — never create a duplicate (H4)

R13/R14 sync one `<slug>.md` at a time, but that alone can't reveal **new milestones a teammate created that you don't have locally**. The index sync closes that gap by reading the whole catalogue of published milestones before you list or create:

- **`milestone-sync.sh index <root>`** lists every milestone on the canonical branch as `<slug>` · `<created_by>` · `<created_at>` · `<updated_at>` (author/date from the commit that *added* the file).
- **On `/milestone init`**: the proposed name is matched against the index (exact and "near-miss" ignoring `-`/`_`/case). If it collides → it does **not** create; it tells you **who created it and when**, and offers to load it instead of duplicating.
- **On `/milestone` (list)**: milestones present on the branch but not local are shown as `🆕 remote · created by <handle>`, so you see at a glance what others started even before pulling.

### Helper auto-update (H1)

The helper installs at `~/.claude/milestone-sync.sh`. To stop two machines from running different claim logic, it is **versioned**: the skill compares the installed `version` against the reference copy and re-copies when they differ (or when it's missing), on the first sync of each session.

### Central mode & onboarding

In central mode (v1.2.0) the config and authoritative files live in the shared memories repo, keeping the client repo clean. `references/team-bootstrap.sh` onboards a new member: clones/updates that repo, installs the skill + helper, and verifies the git identity that signs claims.

### Limit — honest boundary

Git is distributed: the index and claims only see what's **on the canonical branch**. A claim someone holds without pushing is invisible, just like any local commit. That's exactly why R14 forces the claim to be **published the instant you start** (before the first line of code) — "starting a task" and "everyone seeing it" become the same atomic act.

### Common behavior

- **Graceful degradation**: no git / no remote / no canonical branch / block absent → silent no-op. The zero-dependency promise still holds.
- **Never bypasses guards**: if a push is blocked by a security guard or auth, the commit stays in the worktree and you get the exact command to run — it never silences the failure or blocks your work.

## Architecture

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-loaded, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTHORITATIVE (full history)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Plans for [complex] subtasks
<project-root>/.git/milestone-sync-wt/                     ← R13 isolated worktree (team mode only)

# Central mode (v1.2.0 — the client repo stays clean):
~/.claude/projects/<key>/milestones/config.yml            ← config (discovery marker)
~/.claude/projects/<key>/milestones/<slug>.md             ← AUTHORITATIVE (central)
```

## What makes it different from v1

| Aspect | v1 | v2 |
|--------|----|----|
| Load cost | ~8,300 tok (Read full file + templates) | ~100 tok (memory snapshot) |
| Listing cost | ~8,750 tok (Read all files) | ~400 tok (frontmatter only, limit:8) |
| Complex subtasks | No gate — trial-and-error | Plan required before execution |
| Session management | Same conversation (context accumulates) | `/milestone start` opens fresh session |
| Reference loading | Always loads templates.md | Only on `/milestone init` |
| Team collaboration | None — local file only | Opt-in git-synced shared milestone (R13) + atomic claim before touching code (R14) |
| Race protection | None | Git fast-forward push as serialization lock — impossible to double-claim a subtask (R14) |

## Evaluation

- **`/skill-judge`**: 120/120 (Grade A+)
- **`/skill-guard`**: 92/100 (GREEN) — no scripts executed during normal operation, no network, no MCP. R13 (opt-in, off by default) is the only path that performs git operations.

## Security

- By default, only reads/writes local `.milestones/*.md` and memory snapshot files. No network, no scripts during normal operation.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash is used for `/milestone start` (auto-installs script on first use) and, **only when team mode is explicitly enabled**, for `milestone-sync.sh` — which performs `git fetch`/`git push` limited to `<path>/` against the canonical branch via an isolated worktree. Disabled by default; never pushes code; never bypasses security guards (blocked push → reported, not silenced).
