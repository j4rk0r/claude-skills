# skill-advisor

> You install 50 skills. You use 5. skill-advisor makes sure you use all of them — and tells you which ones you're missing.

Builds a full execution plan with installed skills (✅) AND uninstalled gaps (❌) before every task. Offers to search and install missing skills one by one.

## Install

```bash
npx skills add j4rk0r/claude-skills --skill skill-advisor --yes --global
```

## How It Works

Before any multi-step task, skill-advisor asks three questions:

1. **"What professionals would you hire for this project?"** — Each role without a matching skill = ❌ gap
2. **"Where does this project lose money/users with code alone?"** — No SEO = invisible, no analytics = blind
3. **"What would a product owner demand that a developer would forget?"** — Conversion, retention, compliance

Then presents a numbered execution plan:

```
## Plan de ejecución completo

1. ✅ /brainstorming — definir tipo de web, audiencia, objetivos
2. ✅ /writing-plans — planificar implementación paso a paso
3. ✅ /design-system-starter — tokens de diseño y componentes
4. ❌ Copywriting — textos y CTAs definen la conversión
5. ❌ SEO — sin SEO la web será invisible para buscadores
6. ✅ /frontend-design — interfaces production-grade
7. ✅ /web-design-guidelines — accesibilidad y buenas prácticas
8. ❌ Analytics — sin medición no sabrás si cumple objetivos

---
Instaladas listas: 1, 2, 3, 6, 7
Por instalar (recomendado): 4, 5, 8

¿Qué prefieres?
- "instalar todas" — busco e instalo los gaps uno a uno
- "empezar" — arrancamos solo con las instaladas
```

## Features

- **Execution plan with gaps** — Every recommendation shows both ✅ installed and ❌ missing skills in execution order
- **Gap installation flow** — Say "instalar todas" and it searches, recommends, and installs gaps one by one via `npx skills find/add`
- **Mindset framework** — Three thinking questions that identify gaps Claude wouldn't catch on its own
- **Progressive disclosure** — Reference files for domain-specific gap maps (6 domains) and pipelines (10 project types), loaded on demand
- **Two modes** — PRE-ACTION (before task) and POST-ACTION (after completing work)
- **Aggressiveness calibration** — Always recommends after code changes; stays silent for simple tasks
- **Anti-annoyance** — Won't interrupt flow, won't repeat rejected skills, knows when to be silent
- **Community fallback** — If no local skill matches, suggests `npx skills find`
- **First-run scan** — Reports your full ecosystem on explicit `/skill-advisor` invocation

## Evaluation

Scored **115/120 — Grade A** with [skill-judge](https://github.com/softaworks/agent-toolkit).

| Dimension | Score |
|-----------|-------|
| Knowledge Delta | 18/20 |
| Mindset + Procedures | 14/15 |
| Anti-Pattern Quality | 14/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 14/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## License

MIT
