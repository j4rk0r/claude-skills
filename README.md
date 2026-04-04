# j4rk0r/claude-skills

**[English](README.md)** | **[Español](docs/README.es.md)** | **[Français](docs/README.fr.md)** | **[Deutsch](docs/README.de.md)** | **[Português](docs/README.pt.md)** | **[中文](docs/README.zh.md)** | **[日本語](docs/README.ja.md)**

Expert-grade skills for Claude Code. Every skill scored **A+ (120/120)** before shipping.

## Install

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | What it does | Score |
|-------|-------------|-------|
| **[skill-advisor](skills/skill-advisor/)** | Analyzes every instruction and recommends the right skill before execution. Never miss an installed skill again. | 120/120 |

## skill-advisor

> **You install 50 skills. You use 5. The other 45 collect dust.**

skill-advisor fixes this. It sits between you and Claude, analyzing every instruction to find the best skill match from YOUR installed collection — before any work begins.

### How it works

```
You type an instruction
        |
        v
skill-advisor scans your installed skills
        |
        v
Matches found? --> Recommends 1-5, ranked by impact
No match?      --> Proceeds silently (or suggests one to install)
```

### Two modes

**Pre-action** — Before Claude starts working, recommends skills that would improve the outcome:

```
> "fix this login bug"

Evaluacion de skills:
1. /systematic-debugging — matches "bug, test failure, unexpected behavior"
2. /webapp-testing — verify the fix after

Procedo con estas? O directamente sin skill?
```

**Post-action** — After completing work, suggests the logical next step:

```
> [code modified]

Skills recomendadas:
1. /webapp-testing — code was modified, tests needed
2. /verification-before-completion — before claiming done
```

### What makes it different

- **Reads YOUR skills** — No hardcoded list. Scans the system-reminder dynamically. Install a new skill today, skill-advisor sees it tomorrow.
- **Thinks laterally** — "make it look better" matches design skills, animation skills, AND accessibility audit skills. Not just literal keyword matching.
- **Knows when to shut up** — Simple tasks (rename a variable, read a file) get no recommendations. It asks itself: "would the user thank me or be annoyed?"
- **Recommends pipelines** — Detects multi-step scenarios and suggests the full combo: brainstorming → writing-plans → subagent-driven-development.
- **Fallback to community** — If nothing local matches, suggests installable skills via `find-skills` or `npx skills find`.

### First run

On first explicit invocation (`/skill-advisor`), it scans your ecosystem and reports what it found:

```
Ecosystem detectado:
- 47 skills instaladas (global + proyecto)
- Categorias: debugging, testing, frontend, docs, planning, ...
- Listo para recomendar en cada instruccion.
```

### Project-level overrides

Customize behavior per project without modifying the global skill:

```yaml
# .claude/skills/skill-advisor/SKILL.md
---
name: skill-advisor
description: "Project overrides for skill-advisor"
user-invocable: false
---

## Stack Context
This is a Django project. Only recommend Python/Django skills.

## Post-QA Workflow
After QA passes, always create PR on branch `feature/my-name`.
```

## Quality Standards

Every skill is evaluated with the [skill-judge](https://github.com/softaworks/agent-toolkit) framework — 8 dimensions, 120 points max.

| Dimension | What it measures |
|-----------|-----------------|
| Knowledge Delta | Expert knowledge Claude doesn't have by default |
| Mindset | Thinking patterns, not just procedures |
| Anti-Patterns | Specific NEVER rules with real reasons |
| Description | Optimized for automatic skill activation |
| Disclosure | Concise body, references on demand |
| Freedom | Right constraint level for the task type |
| Pattern | Follows proven skill design patterns |
| Usability | Agent can act on it immediately |

**Minimum for inclusion: B (96/120).** Current collection: all A+ (120/120).

## Contributing

1. Fork this repo
2. Add your skill to `skills/<name>/SKILL.md`
3. Run `/skill-judge` — must score B or higher
4. Open a PR with your score

```
skills/
  your-skill-name/
    SKILL.md          # Required
    README.md         # Recommended
    references/       # Optional: loaded on demand
```

## License

[MIT](LICENSE)
