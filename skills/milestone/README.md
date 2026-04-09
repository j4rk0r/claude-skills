# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **You finished a feature across 3 conversations. The 4th conversation starts from zero because context doesn't survive.**

milestone is a persistent development tracker that stores full context as markdown files in your project. Each milestone is a self-contained capsule: objective, subtasks with status, architectural decisions, code references, and a running log of what was done and why. Load it in any conversation and pick up exactly where you left off.

## Install

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## How it works

```
You: "/milestone dashboard"
        |
        v
Fuzzy-matches milestone file in .milestones/
        |
        v
Displays: objective, pending subtasks, decisions, context log, file references
        |
        v
Discovers available planning tools (Plan mode, /writing-plans, /gepetto...)
        |
        v
Suggests next subtask + offers to unify plans from all available planners
        |
        v
After work: auto-updates subtasks, context log, and references
        |
        v
Next conversation: /milestone dashboard → full context, ready to continue
```

## Commands

| Command | Description |
|---------|-------------|
| `/milestone` | List all milestones with status, progress, and quick-load links |
| `/milestone <name>` | Load full context of a milestone (fuzzy match) |
| `/milestone init <name>` | Create a new milestone with objective and subtasks |
| `/milestone add <name> <content>` | Add subtask, decision, note, or reference |
| `/milestone done <name> <subtask>` | Mark a subtask as completed |
| `/milestone update <name>` | Bulk-update context after a work session |

## Key features

- **Persistent across conversations** — milestone files live in `.milestones/` and survive any session
- **Self-contained context** — each file has everything needed to resume work
- **Planning tool discovery** — automatically detects installed planners and offers to unify their outputs
- **Auto-status** — status recalculates from subtask checkboxes
- **Fuzzy matching** — type "dash" to load "dashboard-propietario"
- **Append-only context log** — reverse-chronological record of what happened and why
- **Global skill, local data** — installed once, creates project-specific data

## What makes it different

Unlike task lists or TODO tools, a milestone captures the **narrative** of development: not just what's pending, but what was tried, what was decided, and why. It's the difference between a checklist and a briefing.

## File structure

```
.milestones/
├── dashboard-propietario.md
├── auth-module.md
└── catalog-products.md
```

Each file contains: frontmatter (status, dates), objective, subtasks with checkboxes, decisions with reasoning, a chronological context log, and file references.

## Security

- Skill-Guard audited: **92/100 GREEN**
- No scripts, no network calls, no MCP access
- Only reads/writes local `.milestones/*.md` files
- `allowed-tools: Read Write Edit Glob Grep`
