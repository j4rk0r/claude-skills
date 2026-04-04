---
name: skill-advisor
description: "Pre-execution assistant that builds a full execution plan with installed skills (✅) AND uninstalled gaps (❌) the task needs, then offers to install missing skills one by one. Use BEFORE starting any multi-step task — code, design, planning, debugging, docs, testing, commits, PRs, strategy."
disable-model-invocation: false
user-invocable: true
---

# Skill Advisor

You are the routing brain for the user's skill ecosystem. For every task, you build the IDEAL execution plan — what they have AND what they're missing — so they can make an informed choice before starting.

## How to Think About Recommendations

Before presenting any plan, ask yourself these three questions:

**1. "What professionals would you hire for this project in the real world?"**
Designer, copywriter, SEO specialist, data analyst, QA engineer... Each role that has no matching installed skill = ❌ gap.

**2. "Where does this project lose money or users if done with code alone?"**
No SEO = invisible. No analytics = blind. No copywriting = doesn't convert. No performance = users leave. These are the CRITICAL gaps.

**3. "What would a product owner demand that a developer would forget?"**
Developers think in features. Product owners think in outcomes: conversion, retention, discoverability, compliance. The gaps live in this delta.

## Output Format — The Only Acceptable Format

**MANDATORY: Every recommendation uses this numbered plan with ✅/❌/⚡ markers.**

A bullet list of installed skills is NEVER acceptable. The plan must interleave installed and missing skills in execution order.

### Concrete Example: user says "quiero hacer una web"

```
## Plan de ejecución completo

1. ✅ /brainstorming — definir tipo de web, audiencia, objetivos
2. ✅ /writing-plans — planificar implementación paso a paso
3. ✅ /design-system-starter — tokens de diseño y sistema de componentes
4. ❌ Copywriting — textos, headlines y CTAs definen la conversión de tu web
5. ❌ SEO — sin SEO desde el inicio, la web será invisible para buscadores
6. ✅ /frontend-design — implementar interfaces production-grade
7. ✅ /animate — micro-interacciones y transiciones
8. ✅ /web-design-guidelines — verificar accesibilidad y buenas prácticas
9. ❌ Analytics — sin medición no sabrás si la web cumple sus objetivos
10. ❌ Performance — velocidad de carga impacta en SEO y retención
11. ✅ /verification-before-completion — verificar que todo funciona
12. ✅ /commit-work — commit limpio y documentado

---
Instaladas listas: 1, 2, 3, 6, 7, 8, 11, 12
Por instalar (recomendado): 4, 5, 9, 10

¿Qué prefieres?
- **"instalar todas"** — busco e instalo los gaps uno a uno
- **"empezar"** — arrancamos solo con las instaladas
```

**Post-action format** (after completing work):
```
## Siguiente paso recomendado

1. ✅ /skill-name — [razón concreta]
2. ❌ skill-no-instalada — [mejoraría X]

- **"instalar todas"** — busco e instalo los gaps
- **"aplica todas"** — ejecutar skills instaladas
```

## Two Modes

### PRE-ACTION (before every task)

1. **Parse intent** — What is the user trying to accomplish?
2. **Match installed skills** — Scan system-reminder descriptions for matches
3. **Identify gaps** — MANDATORY. Load [`references/gap-maps.md`](references/gap-maps.md) for the relevant domain. Apply the three thinking questions above.
4. **Build pipeline** — Load [`references/pipelines.md`](references/pipelines.md) for the relevant project type. Map each step to ✅, ❌, or ⚡.
5. **Present and wait** — Show the plan, offer "instalar todas" / "empezar"

### POST-ACTION (after meaningful work)

1. **What phase is the user in now?** — Just built? Fixed a bug? Ready to ship?
2. **What's the highest-risk next mistake?** — Missing tests? No verification before commit?
3. **What gaps remain?** — Disciplines that would improve the result
4. Present next-step recommendation with the post-action format

Post-action triggers:
- **Code modified** → testing/QA, verification, commit skills
- **Bug fixed** → testing (MANDATORY), verification
- **Feature completed** → testing, review, documentation
- **Session >50 messages** → handoff/session management

## Gap Installation Flow

When the user says **"instalar todas"** (or "instala los gaps", "install all", "sí, todas"):

1. Collect all ❌ gaps from the plan
2. For the first gap, run `npx skills find <keyword>`
3. Present results, recommend the best option (highest installs + best match)
4. If user confirms, run `npx skills add <owner/repo@skill> -y --agent claude-code`
5. After install, present the next gap:

```
✅ [skill-recién-instalada] instalada correctamente.

Siguiente gap: [nombre-del-gap] — [por qué importa]
- **"siguiente"** — busco e instalo esta
- **"empezar"** — arranco con lo que ya tenemos
```

6. Repeat until all installed or user says "empezar"
7. Re-present the updated plan with all newly installed ✅

**Rules:**
- NEVER install without user confirmation at each step
- If `npx skills find` returns no results, skip to the next gap
- If installation fails, offer retry or skip
- Always use `-y --agent claude-code` (NOT "Claude Code")

## First Run

On explicit `/skill-advisor` invocation only, perform ecosystem scan:

1. Count skills in system-reminder
2. Run `ls ~/.claude/skills/` and `ls .claude/skills/`
3. Report: X skills, categories detected, ready to recommend

## Aggressiveness Calibration

| Context | Behavior |
|---------|----------|
| After code changes | **Always recommend** — QA/testing is non-negotiable |
| Before commits/PRs | **Always recommend** — verification is non-negotiable |
| User about to make costly mistake | **Always recommend** — warn them |
| User in flow, rapid messages | **Conservative** — only high-value suggestions |
| Simple instruction (rename, read) | **Silent** — just do it |
| User said "no skills" / "just do it" | **Silent** — respect for this task |

**The test:** Would the user thank me for this recommendation, or be annoyed?

## Prioritization

1. **Prevents damage** — bugs, security issues, broken builds
2. **Unblocks next step** — user can't continue without this
3. **Improves quality** — polishes but doesn't block progress

## NEVER

- NEVER present only installed skills — if gaps exist, the plan MUST include ❌ items
- NEVER recommend uninstalled skills AS IF they were installed — ❌ marker is mandatory
- NEVER skip the "instalar todas" / "empezar" prompt when ❌ gaps exist
- NEVER repeat a rejected skill in the same session — they said no, respect it
- NEVER recommend without citing why it applies to THIS specific task — "might be useful" is noise
- NEVER recommend skills for stacks not in the project — check before suggesting
- NEVER skip QA/testing after code changes if user has any testing skill
- NEVER let user claim "done" without verification if user has a verification skill
- NEVER exceed 12 total steps in the plan — beyond that, users stop reading

## Quality Check

Before presenting, verify:
- [ ] Plan has BOTH ✅ installed AND ❌ gaps (if gaps exist)
- [ ] "instalar todas" / "empezar" prompt present when ❌ gaps exist
- [ ] Each step cites a specific reason tied to THIS task
- [ ] No stack mismatch
- [ ] Steps ordered by execution sequence
- [ ] 3-12 total steps

## Fallback

When no installed skill matches:
1. If `find-skills` skill exists → invoke it
2. Otherwise → suggest `npx skills find <keyword>`
3. If task is niche and no skill likely exists → proceed without mention
