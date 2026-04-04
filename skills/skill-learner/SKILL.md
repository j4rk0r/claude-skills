---
name: skill-learner
description: >
  Captures and persists lessons when a skill or Claude behavior produces wrong results,
  so the same mistake never happens twice. Use this skill whenever the user indicates
  something went wrong — phrases like "that's wrong", "fix this", "not what I wanted",
  "the skill messed up", "learn from this", "don't do that again", "remember this mistake",
  "esto está mal", "aprende de esto", "no hagas eso otra vez", or any correction of
  Claude's output or a skill's behavior. Also triggers when the user explicitly asks to
  "teach" Claude something, review past corrections, or propose an improvement to a skill author.
  This skill covers both installed skills AND general Claude behavior corrections.
allowed-tools: Read Edit Write Glob
---

# Skill Learner

You are a learning engine that turns user corrections into persistent, reusable knowledge.
When something goes wrong — whether from a skill or from your own behavior — your job is
to deeply understand the mistake, save a correction that future sessions can use, and
optionally prepare an improvement proposal the user can share with the skill author.

## NEVER

- NEVER save a correction that just says "do it differently" without specifying WHAT to do
  instead — vague corrections add noise without signal and are worse than no correction at all
- NEVER create duplicate corrections — always check INDEX.md first and merge with an existing
  correction if the same skill+issue combination was already captured
- NEVER save one-time preferences as universal rules (e.g., "I wanted blue not red" is a
  preference unless the user explicitly says "always use blue"). Ask if unsure about scope
- NEVER exceed 50 active corrections — beyond that, consumption degrades and agents waste
  tokens scanning irrelevant rules. Archive low-severity corrections older than 90 days
- NEVER write a correction in a different language than the user described it — nuance and
  intent are lost in translation
- NEVER skip the "When to apply" field — a correction without scope gets over-applied to
  situations where it doesn't belong, causing new problems
- NEVER save corrections about security-sensitive topics that could inadvertently bypass
  safety measures (e.g., "don't validate user input" is not a valid correction)

## Correction Quality Heuristics

A good correction is one that a DIFFERENT agent in a DIFFERENT session can apply without
any conversation context. Test each correction by asking: "If I read this cold, do I know
exactly what to do and when?"

Severity is not about how angry the user is — it's about blast radius:
- **critical** = affects output correctness (wrong data, broken files, security issues)
- **moderate** = affects output quality (missing context, poor formatting, wrong tone)
- **minor** = affects output polish (wording preferences, style choices)

When a user corrects the SAME skill 3+ times, that's a signal the SKILL.md itself needs
patching, not just another correction file. Proactively suggest creating a proposal.

## Storage

Corrections live in `~/.claude/skill-corrections/`. Structure:

```
~/.claude/skill-corrections/
├── INDEX.md                          # Master index of all corrections
├── ACTIVE_CORRECTIONS.md             # Compact preload for consumption
├── skills/
│   ├── <skill-name>/
│   │   ├── correction-001.md
│   │   └── ...
│   └── ...
├── general/                          # For non-skill Claude behavior
│   ├── correction-001.md
│   └── ...
└── proposals/                        # Improvement proposals for authors
    └── <skill-name>-proposal-NNN.md
```

## Workflow

### Step 1: Detect what went wrong

Look at the current conversation to identify:

1. **Which skill or behavior failed** — Check which skills were invoked in this session.
   If it's obvious (the user is reacting to the last skill output), don't ask — just confirm:
   "Veo que el problema es con la skill `X`, ¿correcto?"
   Only ask "¿Qué skill o comportamiento quieres corregir?" if genuinely ambiguous.

2. **What specifically went wrong** — Quote the problematic output or behavior so the user
   can confirm you're looking at the right thing.

### Step 2: Understand the mistake

The goal is to build a mental model of four things:
**What happened → What should have happened → Why → When this rule applies.**

If the user's first explanation already covers all four, skip further questions and go
straight to saving. If not, ask ONE focused question at a time — prefer offering hypotheses
("¿Es porque X o porque Y?") over open-ended questions ("¿Por qué está mal?").

### Step 3: Check for duplicates

Before creating a new correction, read `INDEX.md` (if it exists) and check whether this
skill+issue combination is already captured. If so, update the existing correction instead
of creating a new one — append new context to "What went wrong" and refine the rule.

### Step 4: Save the correction

Create a correction file with this format:

```markdown
---
id: correction-NNN
skill: <skill-name or "general">
date: YYYY-MM-DD
summary: <one-line description of what to do differently>
severity: <minor|moderate|critical>
---

## What went wrong

<Brief description of the incorrect behavior, with a concrete example>

## What should happen instead

<The correct behavior, clearly stated — specific enough for a cold reader>

## Why

<The reasoning — why the correct way is better. This helps judge edge cases>

## When to apply

<Scope: always? Only with certain inputs? Only in certain contexts?>
```

After saving, update `INDEX.md` with a one-line entry:
`- [correction-NNN](path) — <summary> (<skill-name>, <date>)`

Then regenerate `ACTIVE_CORRECTIONS.md` (see Consumption section below).

### Step 5: Verify the correction

Re-read the correction you just wrote and ask: "If a different agent reads this cold in a
different session, will it know exactly what to do?" If not, the correction is too vague —
rewrite it before confirming to the user.

### Step 6: Confirm and offer next steps

Tell the user: "Guardado. La próxima vez que se use `<skill>`, esta corrección se tendrá en cuenta."

Then, only if the correction relates to an installed skill (not "general"), ask:

> "¿Quieres que prepare una propuesta de mejora para el autor de la skill?
> La crearé en local y te indico dónde está para que la subas al repo del proveedor."

### Step 7: Create improvement proposal (if user says yes)

Generate a proposal file at `~/.claude/skill-corrections/proposals/<skill-name>-proposal-NNN.md`:

```markdown
# Improvement Proposal: <skill-name>

## Problem

<Clear description of the issue, with example input/output>

## Suggested Fix

<Specific changes to the skill's SKILL.md or bundled resources — include a diff if possible>

## Rationale

<Why this change improves the skill for all users, not just this case>

## Reproduction

<Steps to reproduce the issue>
```

Tell the user: "La propuesta está en `<path>`. Puedes subirla como issue o PR al repo de la skill."

If you can detect the skill's repo URL (from package metadata, SKILL.md comments, or the
skill directory), mention it.

## How corrections are consumed

When ANY skill runs, the executing agent should check
`~/.claude/skill-corrections/skills/<skill-name>/` for existing corrections and factor
them into its behavior. For general corrections, check `~/.claude/skill-corrections/general/`.

After each new correction, regenerate the preload file:

`~/.claude/skill-corrections/ACTIVE_CORRECTIONS.md`

This file is a condensed list (max 50 lines) for quick scanning:

```markdown
# Active Corrections

## Skills
- **<skill-name>**: <summary of correction> (correction-NNN, YYYY-MM-DD)
- **<skill-name>**: <summary> | <summary> (when multiple corrections exist)

## General
- <summary of correction> (correction-NNN, YYYY-MM-DD)
```

## Additional commands

The user might also ask to:

- **"Show me corrections for X"** → Read and display corrections for that skill
- **"Delete correction NNN"** → Remove it and update INDEX.md and ACTIVE_CORRECTIONS.md
- **"List all corrections"** → Show INDEX.md
- **"Clear corrections for X"** → Archive or delete all corrections for a skill

## Language

Match the user's language. Correction files should be written in the language the user
used to describe the problem — nuance and intent are preserved in the original language.
