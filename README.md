# Claude Skills Collection

A curated set of high-quality skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — designed to make AI-assisted development smarter, not just faster.

## Available Skills

| Skill | Description | Score |
|-------|-------------|-------|
| [skill-advisor](skills/skill-advisor/) | Routes every instruction to the best skill before execution. Pre-action + post-action analysis for 70+ skill ecosystems. | A+ (96%) |

## Quick Install

Install a single skill:

```bash
npx skills add j4rk0r/claude-skills --skill skill-advisor
```

Install all skills:

```bash
npx skills add j4rk0r/claude-skills
```

### Install globally (recommended)

Add `--global` to make skills available across all your projects:

```bash
npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global
```

## Skills

### skill-advisor

**The routing brain for your skill ecosystem.**

Most Claude Code users install dozens of skills but forget to use them. The skill-advisor fixes this by analyzing every instruction you give and recommending the right skill(s) before execution begins.

**Two modes:**

- **Pre-action** — Before you start working, it suggests which skills would improve the outcome
- **Post-action** — After you finish, it suggests logical next steps (QA, commit, review, etc.)

**What it does NOT do:**
- List all 70 skills every time (max 5 recommendations)
- Interrupt simple tasks (rename a variable? just does it)
- Recommend skills for stacks not in your project

**Example:**

```
You: "fix this login bug"

skill-advisor:
  Evaluacion de skills:
  1. /systematic-debugging - bug report, antes de tocar codigo
  2. /webapp-testing - verificar el fix despues

  Procedo con estas? O directamente sin skill?
```

Read the full [SKILL.md](skills/skill-advisor/SKILL.md) for implementation details.

## Creating Project-Level Overrides

Skills can be customized per project. Create a `.claude/skills/skill-advisor/SKILL.md` in your project root with only the overrides:

```yaml
---
name: skill-advisor
description: "Project-level overrides for skill-advisor"
user-invocable: false
---

# Skill Advisor — Project Overrides

## Stack Context
This is a Django project. Recommend Python/Django skills, not React/Node.

## Post-QA Workflow
After QA passes, always create PR on branch `feature/my-name`.
```

The global skill provides the brain. The project override provides the context.

## Quality Standards

Every skill in this collection is evaluated using the [skill-judge](https://github.com/softaworks/agent-toolkit) framework across 8 dimensions:

| Dimension | What it measures |
|-----------|-----------------|
| Knowledge Delta | Does it add expert knowledge Claude doesn't have? |
| Mindset + Procedures | Does it transfer thinking patterns, not just steps? |
| Anti-Pattern Quality | Does it have specific NEVER rules with reasons? |
| Specification Compliance | Is the description optimized for skill activation? |
| Progressive Disclosure | Is it concise (<200 lines) with references when needed? |
| Freedom Calibration | Right level of constraint for the task type? |
| Pattern Recognition | Does it follow a proven skill design pattern? |
| Practical Usability | Can an agent actually use it effectively? |

**Minimum score for inclusion: B (80%+)**

## Contributing

1. Fork this repo
2. Create your skill in `skills/your-skill-name/SKILL.md`
3. Self-evaluate with `/skill-judge` — must score B or higher
4. Submit a PR with your evaluation score

### Skill structure

```
skills/
  your-skill-name/
    SKILL.md          # Required: the skill definition
    references/       # Optional: additional files loaded on demand
```

## License

MIT - see [LICENSE](LICENSE)
