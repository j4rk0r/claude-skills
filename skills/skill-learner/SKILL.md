---
name: skill-learner
description: >
  Persistent correction system that captures mistakes from skills or Claude behavior
  and ensures they never repeat across sessions. Use whenever the user indicates something
  went wrong — "that's wrong", "fix this", "not what I wanted", "learn from this",
  "don't do that again", "esto está mal", "aprende de esto", "no hagas eso otra vez",
  or any correction, complaint, or teaching moment about Claude's output or a skill's
  behavior. Also use when the user asks to review, list, delete, or manage past corrections,
  or wants to create an improvement proposal for a skill author. Covers installed skills,
  general Claude behavior, and cross-session learning persistence.
allowed-tools: Read Edit Write Glob
---

# Skill Learner

Turn user corrections into persistent knowledge that survives across sessions.

## NEVER

- NEVER save a vague correction ("do it differently") without specifying the exact
  alternative — vague corrections create false confidence and are worse than no correction
- NEVER create duplicates — check INDEX.md first; merge if same skill+issue exists
- NEVER save one-time preferences as universal rules ("I wanted blue" ≠ "always use blue")
  — ask about scope when intent is ambiguous
- NEVER exceed 50 active corrections — consumption degrades; archive minor corrections
  older than 90 days to `archive/`
- NEVER write corrections in a language different from the user's — nuance dies in translation
- NEVER skip "When to apply" — a scopeless correction gets over-applied to contexts where
  it causes new problems
- NEVER save corrections that bypass safety ("don't validate input", "skip auth checks")
- NEVER assume old corrections are still valid — skill updates silently invalidate them;
  verify before applying corrections older than 90 days
- NEVER save without passing the cold-reader test: "Can a different agent in a different
  session act on this without any conversation context?" If no, rewrite before saving

## The Correction Paradox

More corrections ≠ better behavior. Over-correcting creates rigidity — an agent drowning
in 50 corrections becomes cautious and slow, second-guessing every decision. The goal is
not to capture every complaint, but to capture the corrections that will prevent the most
damage across the most future sessions.

Before saving, ask yourself:
- **Frequency**: Will this situation come up again? (One-off = don't save)
- **Blast radius**: If uncorrected, how bad is the impact? (Minor polish = maybe don't save)
- **Generalizability**: Does this apply beyond this specific conversation? (Too narrow = don't save)

If all three are low, tell the user you've noted it but saving a correction would add
noise. They can override you.

## Quick Classification

Classify in the first 5 seconds — this determines the workflow path:

| Signal | Type | Path |
|--------|------|------|
| Clear explanation ("X did Y, should do Z") | Quick fix | → Step 2 (dedup) → Step 3 (save) |
| Vague complaint ("that's wrong") | Investigation | → Step 1 (detect) → full workflow |
| Same skill corrected 3+ times in INDEX.md | Skill defect | → Steps 1-3 → proactively offer proposal |
| "Show/list/delete corrections" | Management | → Management Commands section |

## Storage

```
~/.claude/skill-corrections/
├── INDEX.md                 # One-line entries, master list
├── ACTIVE_CORRECTIONS.md    # Max 50 lines, consumed by other skills
├── skills/<name>/           # Per-skill corrections
├── general/                 # Non-skill Claude behavior
├── proposals/               # Author improvement proposals
└── archive/                 # Expired or invalidated
```

## Workflow

### Step 1: Detect (skip for Quick Fix)

Identify which skill failed from the conversation context:
- **Obvious** (user reacting to last output): Confirm, don't ask — "Veo que el problema
  es con `X`, ¿correcto?"
- **Ambiguous**: Ask — "¿Qué skill o comportamiento quieres corregir?"

Quote the problematic output so the user confirms you're targeting the right thing.

### Step 2: Check Duplicates

Read `INDEX.md`. If same skill+issue exists, update the existing correction:
append new context to "What went wrong", refine the rule, bump the date.

### Step 3: Save

**MANDATORY — READ**: Load [`references/correction-patterns.md`](references/correction-patterns.md)
for the exact file template, severity decision tree, and scope calibration examples.
**Do NOT save without reading the reference first.**

After creating the correction file:
1. Update `INDEX.md`: `- [correction-NNN](path) — <summary> (<skill>, <date>)`
2. Regenerate `ACTIVE_CORRECTIONS.md` (format in reference file, max 50 lines)

### Step 4: Verify (non-negotiable)

Re-read what you wrote. Apply the cold-reader test: "If a different agent reads this
cold in a different session, will it know exactly what to do and when to do it?"

If it fails, rewrite. A correction that fails this test actively harms future sessions
because it creates the illusion of knowledge without the substance.

### Step 5: Activate Consumption (first time only)

Corrections are dead files unless future sessions read them. On the FIRST correction
ever saved, ask the user:

> "Para que las correcciones funcionen entre sesiones, necesito añadir una línea a tu
> CLAUDE.md. ¿Lo añado?"

If yes, append to the user's global `~/.claude/CLAUDE.md`:
```
## Skill Corrections
Before executing any skill, check ~/.claude/skill-corrections/ACTIVE_CORRECTIONS.md for relevant corrections and apply them.
```

Check if the line already exists before offering. Only do this once — ever.

### Step 6: Confirm + Offer Proposal

Tell the user the correction is saved. Then, only for skill corrections (not "general"):

> "¿Quieres que prepare una propuesta de mejora para el autor de la skill?"

### Step 7: Create Proposal (if yes)

**MANDATORY — READ**: Load [`references/correction-patterns.md`](references/correction-patterns.md)
for the proposal template, diff format, and repo detection instructions.
**Do NOT write a proposal without reading the reference first.**

Save to `proposals/<skill-name>-proposal-NNN.md`. Tell the user the path and suggest
submitting as issue/PR to the skill's repo.

## Correction Decay

When encountering a correction older than 90 days:

**MANDATORY — READ**: Load [`references/correction-patterns.md`](references/correction-patterns.md)
§ Correction Decay Procedure for the full archival process.

Quick version: check if the skill was updated since the correction date. If the issue
was fixed in the skill itself, archive the correction and notify the user.

## Conflict Resolution

When two corrections for the same skill contradict each other:

**MANDATORY — READ**: Load [`references/correction-patterns.md`](references/correction-patterns.md)
§ Conflict Resolution Matrix for the severity-based resolution rules.

Core principle: newer wins unless older is critical and newer is minor.
Critical-vs-critical conflicts always require user judgment.

## Management Commands

| User says | Action |
|-----------|--------|
| "Show corrections for X" | Read and display that skill's corrections |
| "Delete correction NNN" | Remove file + update INDEX.md + ACTIVE_CORRECTIONS.md |
| "List all corrections" | Show INDEX.md |
| "Clear corrections for X" | Move all to `archive/`, update indexes |

## Language

Match the user's language. Write corrections in the language the user described
the problem in — nuance is preserved in the original language.
