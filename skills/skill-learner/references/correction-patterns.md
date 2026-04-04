# Correction Patterns Reference

Load this file when saving a correction (Step 3) or creating a proposal (Step 7).
Do NOT load for quick classification, listing, or deleting corrections.

## Table of Contents

1. [Correction File Template](#correction-file-template)
2. [Severity Decision Tree](#severity-decision-tree)
3. [Scope Calibration Examples](#scope-calibration-examples)
4. [Proposal Template](#proposal-template)
5. [ACTIVE_CORRECTIONS.md Format](#active-corrections-format)
6. [Correction Decay Procedure](#correction-decay-procedure)
7. [Conflict Resolution Matrix](#conflict-resolution-matrix)
8. [Edge Cases](#edge-cases)

---

## Correction File Template

```markdown
---
id: correction-NNN
skill: <skill-name or "general">
date: YYYY-MM-DD
summary: <one-line imperative: what to do differently>
severity: <minor|moderate|critical>
---

## What went wrong

<Incorrect behavior. MUST include a concrete example — not abstract description.>

**Example**: When asked to "genera un PDF con el informe mensual", the skill produced
a document with 0px margins, causing text to touch all four edges of the page.

## What should happen instead

<Correct behavior. Specific enough that a cold reader knows exactly what to do.>

Generate PDFs with minimum 2cm margins on all sides (56px at 72dpi) unless the user
explicitly specifies different margins.

## Why

<Reasoning that helps judge edge cases where the rule might or might not apply.>

Margins are fundamental to document readability. Without them: (1) text is hard to read
because the eye lacks breathing room, (2) printers clip content in the non-printable zone,
(3) the document looks unprofessional. The 2cm default matches ISO standard for business docs.

## When to apply

<Scope boundaries. Be explicit about what IS and IS NOT covered.>

Always when generating PDFs with text content. Does NOT apply to:
- Full-bleed image PDFs (posters, photos)
- PDFs where the user explicitly requests "no margins" or "edge to edge"
```

### Common Summary Mistakes

| Bad summary (vague) | Good summary (actionable) |
|---------------------|--------------------------|
| "Fix the PDF issue" | "Apply 2cm default margins to all generated PDFs" |
| "Don't do that again" | "Match commit message language to user's conversation language" |
| "Handle errors better" | "Return structured error with code+message, never swallow silently" |

The summary should read as an imperative instruction a different agent can follow
without reading the rest of the file.

---

## Severity Decision Tree

```
Is the output fundamentally WRONG (broken file, incorrect data, security risk)?
├─ YES → critical
└─ NO → Does it WORK but miss the mark meaningfully?
         ├─ YES → moderate (wrong tone, poor formatting, missing context)
         └─ NO → minor (style preference, polish, wording choice)
```

### Severity Boundary Cases

| Scenario | Severity | Why |
|----------|----------|-----|
| Commit message in wrong language | moderate | Works but causes team confusion |
| PDF without margins | critical | Renders document unusable for printing |
| Used "you" instead of "tú" | minor | Style preference, no functional impact |
| Forgot to include error handling | critical | Broken behavior in production |
| Created 3 files instead of 1 | moderate | Works but adds unnecessary complexity |
| Used camelCase instead of snake_case | minor | Convention preference |

---

## Scope Calibration Examples

The "When to apply" field is the most dangerous to get wrong. Too broad = over-applied.
Too narrow = useless.

### Too broad (dangerous)
```
When to apply: Always when using any skill.
```
This will interfere with every skill invocation. Almost never correct.

### Too narrow (useless)
```
When to apply: Only when generating a PDF report about monthly sales for the ACME Corp
project using the pdf skill with Python reportlab on macOS.
```
So specific it will never match another situation.

### Just right
```
When to apply: When the pdf skill generates any document with text content. Does NOT
apply to full-bleed image exports or when user explicitly requests no margins.
```
Clear scope with explicit exclusions.

### The Scope Test
Ask: "Will this correction help in a DIFFERENT conversation about a SIMILAR problem?"
- Yes → scope is right
- No, it's too specific → broaden it
- It would cause problems in unrelated contexts → narrow it with exclusions

---

## Proposal Template

```markdown
# Improvement Proposal: <skill-name>

## Problem

<Clear description. Include the user's original complaint and the skill's actual output.>

## Suggested Fix

<Specific changes to SKILL.md. Use diff format when possible:>

```diff
+ ## Default Page Setup
+
+ Always apply these defaults unless the user specifies otherwise:
+ - Page margins: 2cm on all sides
```

<If the fix requires changes to scripts or reference files, specify which files and what
to change in each.>

## Rationale

<Why this helps ALL users, not just this one case. Reference standards or common
expectations when available.>

## Reproduction

<Minimal steps to trigger the bug:>
1. Ask Claude with the skill to [specific action]
2. Open the output
3. Observe [specific problem]
```

### Detecting the Skill's Repo

Check these locations in order:
1. `~/.claude/skills/<skill-name>/package.json` → `repository` field
2. `~/.claude/skills/<skill-name>/SKILL.md` → comments or metadata mentioning repo
3. `~/.claude/skills/<skill-name>/.git/config` → remote origin
4. Glob for README files that might mention the repo URL

If none found, tell the user: "No pude detectar el repo de la skill. ¿Sabes dónde
está alojada?"

---

## ACTIVE_CORRECTIONS Format

Max 50 lines. One line per correction. Group by skill.

```markdown
# Active Corrections

## Skills
- **commit-work**: Match commit message language to user's conversation language (correction-001, 2026-04-04)
- **pdf**: Apply 2cm default margins to all generated PDFs (correction-001, 2026-04-04)
- **pdf**: Include page numbers in multi-page documents (correction-002, 2026-04-10)

## General
- Don't create multiple helper files when one suffices (correction-001, 2026-04-04)
- Prefer editing existing files over creating new ones (correction-002, 2026-04-05)
```

When a skill has 3+ corrections, that's the signal to suggest a proposal — the skill
itself needs patching, not just more corrections piling up.

---

## Correction Decay Procedure

Run this check when reading a correction older than 90 days:

1. Read the skill's current SKILL.md
2. Check if the issue the correction addresses was fixed in the skill itself
3. If fixed → archive:
   ```bash
   # Move to archive with timestamp
   mv correction-NNN.md ../archive/correction-NNN-archived-YYYY-MM-DD.md
   ```
4. Update INDEX.md (remove entry) and ACTIVE_CORRECTIONS.md (remove line)
5. Tell user: "La corrección X fue archivada — la skill ya fue actualizada para corregir esto."

If the skill was NOT updated but the correction is stale (90+ days, severity:minor):
- Ask user: "Esta corrección tiene más de 90 días. ¿Sigue siendo relevante?"
- Archive if user says no

---

## Conflict Resolution Matrix

| Existing | New | Resolution |
|----------|-----|------------|
| critical | critical | Flag to user — contradicting critical rules need human judgment |
| critical | moderate | Keep critical, archive moderate with note "superseded by correction-NNN" |
| critical | minor | Keep critical, archive minor |
| moderate | critical | Replace: update existing to critical, merge content |
| moderate | moderate | Merge: combine into single correction, keep newer date |
| minor | any higher | Replace: upgrade severity, merge content |

After resolving, document in the surviving correction's "When to apply":
```
Note: This supersedes correction-NNN which [describe what it said and why it was replaced].
```

---

## Edge Cases

### User corrects something that's actually correct
Sometimes the user is wrong. If you believe the skill's behavior was correct:
1. Explain why you think the current behavior is right
2. Ask: "¿Quieres que lo guarde como corrección de todas formas?"
3. If yes, save it — the user knows their context better than you

### Correction applies to multiple skills
Save it under the PRIMARY skill, but mention others in "When to apply":
```
When to apply: Primarily for pdf skill, but also applies to marp-slide
and any other skill that generates printable documents.
```

### User wants to correct a correction
Update the existing correction file. Don't create a correction-about-a-correction.
Bump the date and add a note: "Updated YYYY-MM-DD: [what changed]"

### No skill involved — pure Claude behavior
Save under `general/`. These are the most valuable corrections because they apply
across all sessions regardless of which skills are loaded.

### Bulk corrections ("everything about this was wrong")
Break into separate corrections. Each file should address ONE specific behavior change.
A correction that says "do everything differently" is useless — it fails the cold-reader test.
