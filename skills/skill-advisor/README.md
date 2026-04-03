# skill-advisor

> The routing brain for your skill ecosystem.

Pre-action + post-action skill recommendation engine. Analyzes every instruction to suggest the best skill(s) before execution, and recommends next steps after task completion.

## Install

```bash
npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global
```

## How it works

```
Your instruction --> skill-advisor analyzes --> Recommends 1-5 skills --> You confirm --> Skill executes
                                            --> You decline --> Claude proceeds without skill
```

## Features

- **Intent detection** — Parses your words to match against 70+ skills
- **Combo patterns** — Recommends skill pipelines (e.g., brainstorming -> writing-plans -> subagent-driven-development)
- **Prioritization** — Ranks by: prevents damage > unblocks next step > improves quality
- **Anti-annoyance** — Won't interrupt simple tasks or recommend irrelevant skills
- **Post-action triggers** — After code changes, always suggests QA/testing
- **Quality self-check** — Verifies its own recommendations before presenting them

## Evaluation

Scored **115/120 (96%) — Grade A+** using [skill-judge](https://github.com/softaworks/agent-toolkit).

| Dimension | Score | Max |
|-----------|-------|-----|
| Knowledge Delta | 19 | 20 |
| Mindset + Procedures | 14 | 15 |
| Anti-Pattern Quality | 15 | 15 |
| Specification Compliance | 15 | 15 |
| Progressive Disclosure | 13 | 15 |
| Freedom Calibration | 14 | 15 |
| Pattern Recognition | 9 | 10 |
| Practical Usability | 15 | 15 |

## License

MIT
