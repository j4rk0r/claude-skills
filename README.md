# j4rk0r/claude-skills

**[English](README.md)** | **[Español](docs/README.es.md)** | **[Français](docs/README.fr.md)** | **[Deutsch](docs/README.de.md)** | **[Português](docs/README.pt.md)** | **[中文](docs/README.zh.md)** | **[日本語](docs/README.ja.md)**

Expert-grade skills for Claude Code. Every skill scored **A+ (120/120)** before shipping.

## Install all

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

Or install individually:

```bash
npx skills add j4rk0r/claude-skills@skill-guard -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-advisor -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-learner -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review -y -g
```

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module -y -g
```

```bash
npx skills add j4rk0r/claude-skills@milestone -y -g
```

```bash
npx skills add j4rk0r/claude-skills@usage-tracker -y -g
```

## Skills

| Skill | What it does |
|-------|-------------|
| **[skill-guard](skills/skill-guard/)** | Security auditor — 9-layer threat detection for skills before installation. Community audit registry. |
| **[skill-advisor](skills/skill-advisor/)** | Builds execution plans that combine your installed skills with gaps you're missing — then offers to install them. Never start a task under-equipped. |
| **[skill-learner](skills/skill-learner/)** | Captures mistakes and persists corrections so the same error never happens twice. Works for skills AND general Claude behavior. Optionally generates improvement proposals for skill authors. |
| **[codex-diff-develop](skills/codex-diff-develop/)** | Drupal 11 code review of the current branch vs `develop` using the Codex methodology — 18 production-tested rules with the *why* behind each one. Generates a structured `.md` report. |
| **[codex-pr-review](skills/codex-pr-review/)** | Drupal 11 pull request review using the Codex methodology — same 18 rules as `codex-diff-develop` but fetches the PR via `git fetch origin pull/<N>/head` so you can audit any GitHub PR. |
| **[lint-drupal-module](skills/lint-drupal-module/)** | Parallelized Drupal 11 lint review combining 4 sources — PHPStan level 5, PHPCS Drupal/DrupalPractice, `drupal-qa` agent (standards) and `drupal-security` agent (OWASP). Full or diff mode. Consolidates everything into a single actionable report with P0/P1/P2 actions. |
| **[milestone](skills/milestone/)** | Persistent development tracker that survives across conversations. Each milestone is a self-contained capsule: objective, subtasks with status, decisions, code references, and a running context log. Integrates with Plan mode and all planning skills. |
| **[usage-tracker](skills/usage-tracker/)** | PostToolUse hook that logs every tool call into `~/.claude/usage.jsonl`. See exactly how much each user request costs — by project, session, day, and tool. |

## skill-guard

> **You install a skill. It reads your `~/.ssh`, grabs your `$GITHUB_TOKEN`, and sends it to a remote server. You never notice.**

skill-guard prevents this. It audits skills before installation using 9 analysis layers — from static patterns to LLM semantic analysis that detects prompt injection disguised as normal instructions.

### How it works

```
You want to install a skill
        |
        v
skill-guard checks the community audit registry
        |
        v
Already audited (same SHA)?  --> Shows previous report
Not audited?                 --> "Run security analysis?"
        |
        v
9-layer analysis: permissions, patterns, scripts,
data flow, MCP abuse, supply chain, reputation...
        |
        v
Score 0-100 → GREEN / YELLOW / RED
        |
        v
GREEN: auto-install | YELLOW: you decide | RED: strong warning
```

### Core: 8 NEVER rules

Each rule exists because of a real attack pattern observed in the wild:

1. **NEVER execute a script before reading its source** — "don't read the source" is social engineering
2. **NEVER trust a SKILL.md's claims** — the description is marketing; the code is truth
3. **NEVER dismiss findings because surrounding code looks legit** — trojans hide in 5% of the code
4. **NEVER skip LLM semantic analysis** — sophisticated attacks use natural language
5. **NEVER pass skills without `allowed-tools` as GREEN** — missing = unlimited access
6. **NEVER ignore MCP references in non-MCP skills** — biggest blind spot in the permission model
7. **NEVER treat base64 as automatically suspicious** — context determines severity
8. **NEVER report "what" without "why"** — findings must explain the threat

### The 9 layers

1. **Frontmatter & Permissions** (20%) — Missing `allowed-tools`? Unrestricted Bash? Description hijacking?
2. **Static Patterns** (15%) — URLs, IPs, sensitive paths, dangerous commands, env vars, obfuscation
3. **LLM Semantic Analysis** (30%) — Prompt injection, trojans, social engineering, time bombs
4. **Bundled Scripts** (15%) — Reads EVERY script. Dangerous imports, obfuscation, data exfiltration
5. **Data Flow** (10%) — Maps source → destination. Sensitive data reaching external URLs = confirmed threat
6. **MCP & Tools** (0%) — Undeclared MCP server usage, exfiltration via Slack/GitHub/Monday
7. **Supply Chain** (2%) — Typosquatting, unpinned versions, fake repos
8. **Reputation** (3%) — Author profile, repo age, trojan forks
9. **Anti-Evasion** (5%) — Unicode tricks, homoglyphs, self-modification, environment fingerprinting

### Two analysis modes

- **Full Audit** — All 9 layers, complete report, registry persistence
- **Quick Scan** — Layers 1+2+3 only. Auto-escalates to full audit if HIGH/CRITICAL found

### Community audit registry

Every audit is saved to [`skills/skill-guard/audits/`](skills/skill-guard/audits/). Before analyzing, skill-guard checks if someone already audited that version. Instant results if SHA matches.

**Trust model:** Only the system generates and publishes audit results. Community members request audits via PR to `audits/requests/` — the maintainer runs skill-guard and publishes the result. This prevents tampered audits from entering the registry.

### Practices what it preaches

skill-guard declares its own `allowed-tools` with restricted Bash patterns — no unrestricted execution.

### Install

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **You install 50 skills. You use 5. The other 45 collect dust.**

skill-advisor fixes this. It sits between you and Claude, analyzing every instruction to build a complete execution plan — matching installed skills AND identifying gaps you're missing — before any work begins.

### How it works

```
You type an instruction
        |
        v
skill-advisor scans your installed skills
        |
        v
Matches found? --> Builds plan with 3-12 steps, ranked by impact
Gaps found?    --> Marks them with ❌, offers to install
No match?      --> Proceeds silently
```

### Two modes

**Pre-action** — Before Claude starts working, recommends skills that would improve the outcome:

```
> "fix this login bug"

Skill evaluation:
1. /systematic-debugging — matches "bug, test failure, unexpected behavior"
2. /webapp-testing — verify the fix after

Proceed with these? Or directly without skill?
```

**Post-action** — After completing work, suggests the logical next step:

```
> [code modified]

Recommended skills:
1. /webapp-testing — code was modified, tests needed
2. /verification-before-completion — before claiming done
```

### What makes it different

- **Reads YOUR skills** — No hardcoded list. Scans the system-reminder dynamically. Install a new skill and skill-advisor sees it immediately.
- **Thinks laterally** — "make it look better" matches design skills, animation skills, AND accessibility audit skills. Not just literal keyword matching.
- **Knows when to shut up** — Simple tasks (rename a variable, read a file) get no recommendations. It asks itself: "would the user thank me or be annoyed?"
- **Recommends pipelines** — Detects multi-step scenarios and suggests the full combo: brainstorming → writing-plans → subagent-driven-development.
- **Gap analysis is mandatory** — Every plan shows installed skills (✅) AND missing skills (❌) side by side. Offers to install gaps one by one.

### First run

On first explicit invocation (`/skill-advisor`), it scans your ecosystem and reports what it found:

```
Ecosystem detected:
- 47 skills installed (global + project)
- Categories: debugging, testing, frontend, docs, planning, ...
- Ready to recommend on every instruction.
```

### Install

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude apologizes, promises to do better — then makes the exact same mistake next session.**

skill-learner breaks that cycle. When a skill or Claude itself gets something wrong, it captures what went wrong, why, and what to do instead — as a persistent correction file that survives across sessions.

### How it works

```
Something went wrong
        |
        v
skill-learner detects which skill (or general behavior) failed
        |
        v
Asks focused questions until it understands the mistake
        |
        v
Saves a structured correction to ~/.claude/skill-corrections/
        |
        v
Next time that skill runs → correction is available
        |
        v
Optionally: generates an improvement proposal for the skill author
```

### Key features

- **Auto-detects the failing skill** from conversation context — doesn't ask if obvious
- **Deduplicates** — checks INDEX.md before creating, merges if same issue exists
- **9 NEVER rules** — prevents vague corrections, duplicates, scope creep, and security bypass
- **Cold-reader test** — verifies each correction is clear enough for a different agent in a different session
- **Improvement proposals** — generates author-ready proposals with diffs, saved locally for the user to submit
- **Bilingual** — writes corrections in the user's language to preserve nuance

### Install

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **Your linter says "looks good" — and three weeks later production breaks because of a hook that only runs on update, not on insert.**

codex-diff-develop is a Drupal 11 code review skill that audits the diff of your current branch against `develop` using the **Codex methodology**: 18 production-tested rules with the *why* behind each one. It catches the bugs your linter misses — the ones that only show up at 3am after deploy.

### How it works

```
You: "revisión diff develop"
        |
        v
Detects context: branch, drupal/ subdir, file types in diff
        |
        v
Loads MANDATORY references (18 Codex rules + 14 finding templates)
        |
        v
Applies the 5-question Codex framework
        |
        v
Decision tree picks Codex rules per file type
        |
        v
Reviews ONLY the diff, no out-of-scope suggestions
        |
        v
Auto-detects IDE → writes report to .vscode/.cursor/.antigravity
        |
        v
Self-verifies against 12-item checklist before delivering
```

### The 18 Codex rules — each with a scar

Each rule includes the **why** (the production incident that taught it). A few examples:

1. **`hook_entity_insert` vs `_update` completeness** — logic only in `_update` skips brand-new entities until someone edits them
2. **Aggregates (MAX/MIN/COUNT) on empty tables return NULL, not 0** — `$max + 1` becomes incoherent on the first record
6. **External APIs without `connect_timeout`** — slow provider blocks queue workers and exhausts PHP-FPM
7. **Unjustified `accessCheck(FALSE)`** — silent permission bypass nobody reviews in future PRs
9. **Idempotency on retry/double-click** — duplicate orders, duplicate emails, duplicate charges
11. **No kill-switch** — 3am incidents with no time to redeploy
14. **Custom blocks/formatters without `getCacheableMetadata()`** — silently breaks BigPipe and Dynamic Page Cache

Full list with detailed *why* in [`references/metodologia-codex-completa.md`](skills/codex-diff-develop/references/metodologia-codex-completa.md).

### NEVER list — 15 Drupal-specific anti-patterns

Things you only learn from real incidents:

- **NEVER** mark a style finding as "Alta" — dilutes severity, the team stops reading
- **NEVER** suggest refactors outside the diff except for critical security
- **NEVER** approve `loadMultiple([])` — returns ALL entities (memory leak classic)
- **NEVER** approve Batch API without `finished` callback handling failure
- **NEVER** approve `EntityFieldManagerInterface::getFieldStorageDefinitions()` without verifying field exists — zombie field storage after delete

### Five-question Codex framework

Before reviewing any chunk:

1. **What kind of change is this?** — determines applicable Codex rules
2. **What's the worst-case in production?** — sets the severity floor
3. **What does the change assume that's outside the diff?** — schema, permissions, indexes
4. **Is it idempotent?** — retry, double-click, re-deploy
5. **Can it be turned off?** — kill-switch for 3am incidents

A worked mini-example walks through applying these to a hypothetical diff.

### Output

Structured `.md` report with:
- Executive summary + severity counts
- Findings by category (Security, Codex logic, Standards/DI, Performance, A11y/i18n, Tests/CI)
- Risks table
- Prioritized action list
- "Lo positivo" section (because praise belongs in PRs too)
- Final checklist

Each finding follows **Problema (Severidad)** → **Riesgo** → **Solución** with adapted code from 14 templates in `references/`.

### IDE auto-detection

Reads `CLAUDE_CODE_ENTRYPOINT` first. Falls back to folder existence only if env var is inconclusive. This prevents writing reports to a legacy `.cursor/` folder when you're actually in VS Code.

### Evaluation

- **`/skill-judge`**: 120/120 (Grade A+)
- **`/skill-guard`**: 100/100 (GREEN) — declares minimal `allowed-tools`, zero network, zero MCP

### Install

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **Your reviewer says "LGTM" — and three weeks later production breaks because of a hook that only fires on update.**

codex-pr-review is the sister skill of `codex-diff-develop` for **remote pull requests**. Same Codex methodology, same 18 rules, same finding templates — but fetches the PR via `git fetch origin pull/<N>/head` so you can audit any GitHub PR by number.

### How it works

```
You: "revisión Codex PR #42 develop ← feature/alejandro"
        |
        v
Confirms PR number and branches (asks if missing)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Loads MANDATORY references (same as codex-diff-develop)
        |
        v
Applies 5-question Codex framework + decision tree
        |
        v
Reviews ONLY the PR diff
        |
        v
Auto-detects IDE → writes report to <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Self-verifies against 13-item checklist before delivering
```

### What's different from codex-diff-develop

The two skills are functional twins. The differences:

| Aspect | codex-diff-develop | codex-pr-review |
|---|---|---|
| Source of diff | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| Output folder | `Revisiones diff/` | `Revisiones PRs/` |
| File name | `lint-review-diff-develop-<branch>.md` | `lint-review-pr<N>.md` |
| Triggers | "diff develop", "codex diff" | "revisión PR", "revisar PR #N", "codex PR" |
| Extra NEVER | — | "**NUNCA** referenciar otros PRs en el documento" — classic of reviewers who mix discussions |
| Extra edge cases | — | GitLab fallback (`merge-requests/<N>/head`), PR already merged, missing PR number |
| Pre-requisite | — | Asks for PR number if not provided |

### When to use which

- **`codex-diff-develop`**: you're working locally on a branch and want to review your own changes before pushing or opening a PR
- **`codex-pr-review`**: you want to review someone else's PR (or your own after pushing it) without checking out the branch locally

### Evaluation

- **`/skill-judge`**: 120/120 (Grade A+)
- **`/skill-guard`**: 100/100 (GREEN) — declares minimal `allowed-tools`, zero network upload, zero MCP

### Install

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## lint-drupal-module

> **Your manual code review finds 29 issues. You run PHPStan and PHPCS by hand. You ask a reviewer for security and standards. 45 minutes later you finally have a consolidated view — and you missed 140 JS violations because nobody ran PHPCS against the module's JavaScript.**

lint-drupal-module runs **four sources in parallel** — PHPStan level 5 (with `phpstan-drupal`), PHPCS Drupal/DrupalPractice, a `drupal-qa` agent for standards, and a `drupal-security` agent for OWASP vectors — and consolidates the findings into a single actionable report. What used to be 12 manual steps and 30 minutes is now one invocation that finishes in the time the slowest source takes (2-5 min full, 30s-1min diff).

### How it works

```
You: "lint review del módulo chat_soporte_tecnico_ia"
        |
        v
Identifies the module (by name, path, or Glob)
        |
        v
Picks the mode: full (default) | diff (vs develop)
        |
        v
Detects DDEV / local composer, installs PHPStan if missing (asks first)
        |
        v
Loads references/prompts-agentes.md (mandatory before invoking agents)
        |
        v
Launches 4 sources in parallel, same message:
  • Agent drupal-qa       (standards)
  • Agent drupal-security (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Consolidates all four outputs into one markdown report
        |
        v
Auto-detects IDE → <ide>/Lint reviews/lint-review-<module>-<mode>-<branch>.md
        |
        v
Summarizes top blockers and asks:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

### Two modes

| Mode | When to use | Speed |
|---|---|---|
| **Full** (default) | Before release, new modules, periodic audits | ~2-5 min |
| **Diff** | Mid-development, pre-push, only new changes vs `develop` | ~30s-1min |

### What it catches that manual reviews miss

Validated against a real Drupal 11 module (32 files). A manual agent-only review flagged 29 issues. Running the skill's full parallelized pipeline surfaced **65 issues** — including 166 PHPCS violations on the module's JavaScript (most auto-fixable with `phpcbf`) that the manual reviewer never checked because JS was outside its scope.

That's the point: a lint review is only as good as its weakest layer. Combining static analysis, style enforcement and expert agents in parallel catches things no single source sees.

### Report structure (fixed)

1. **Executive summary** — findings per source, top 5 blockers, categorical verdict
2. **PHPStan level 5** — errors grouped by file
3. **PHPCS Drupal/DrupalPractice** — violations grouped by file
4. **Standards (drupal-qa)** — findings by severity with fix suggestions
5. **Security (drupal-security)** — vulnerabilities classified 🔴 CRITICAL / 🟠 HIGH / 🟡 MEDIUM / 🟢 LOW / ℹ️ INFO
6. **Prioritized actions** — P0 blockers, P1 recommended, P2 improvements
7. **Best practices coverage** — checklist of strict_types, OOP hooks, DI, CSRF, cache metadata, etc.
8. **Verification commands** — exact commands to re-run locally

### Core NEVER rules

1. **NEVER modifies files during the skill.** Reports only. Fixes are a separate phase with explicit user confirmation.
2. **NEVER runs the 4 sources in separate messages.** Parallelization is the core value; serial is 4× slower.
3. **NEVER lists `Unsafe usage of new static()` in Controllers as a blocker** — known false positive of phpstan-drupal.
4. **NEVER removes FQCN aliases in `services.yml` without checking Hook OOP type-hint usage** — known way to break `drush cr`.
5. **NEVER runs `phpcbf` over JavaScript files** — the Drupal standard converts `null`/`true`/`false` to `NULL`/`TRUE`/`FALSE` in JS, breaking the code at runtime. Always use `--extensions=php,module,inc,install,profile,theme` and `--ignore='*/js/*'`.

### Relation with sister skills

- **`codex-diff-develop`** → reviews business logic on the diff (complements this skill)
- **`codex-pr-review`** → architectural PR review (one level above)
- **Ideal pre-merge workflow:** `lint-drupal-module` → mechanical fixes → `codex-diff-develop` → logic fixes → `codex-pr-review` → merge

### Install

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

---

## milestone

> **You finished a feature across 3 conversations. The 4th conversation starts from zero because context doesn't survive.**

milestone stores everything needed to resume development work in any future conversation — objective, subtasks with status, architectural decisions, code references, and a reverse-chronological log of what was done and why. Load a milestone by name and start working immediately.

### How it works

```
You: "/milestone dashboard"
        |
        v
Fuzzy-matches milestone file in .milestones/
        |
        v
Displays full context: objective, subtasks, decisions, log, references
        |
        v
Discovers available planners (Plan mode, /writing-plans, /gepetto...)
        |
        v
"Use all planners and unify?" or pick one
        |
        v
After work: updates subtasks, context log, references
        |
        v
Next conversation: /milestone dashboard → full picture, ready to continue
```

### Commands

| Command | What it does |
|---------|-------------|
| `/milestone` | List all milestones with status, progress, and quick-load commands |
| `/milestone <name>` | Load full context (fuzzy match — "dash" finds "dashboard-propietario") |
| `/milestone init <name>` | Create new milestone with objective + codebase-aware subtask proposals |
| `/milestone add <name> <content>` | Add subtask, decision, note, or file reference |
| `/milestone done <name> <subtask>` | Mark subtask complete, log context, recalculate status |
| `/milestone update <name>` | Bulk session update — mark tasks, log decisions, add references |

### Key design decisions

- **Append-only context log** — never delete history, only add corrections. Future sessions need the narrative.
- **Planning tool discovery** — automatically detects all installed planners and offers to run them all, then unifies into a single subtask list.
- **Global skill, local data** — installed once globally, creates `.milestones/` per project. Each project's milestones are independent.
- **8 NEVER rules** — no milestones for <1h tasks, no duplicates, no stale milestones, no vague subtasks, max 10 active.

### Evaluation

- **`/skill-guard`**: 92/100 (GREEN) — no scripts, no network, no MCP. Only local file I/O.

### Install

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

---

## usage-tracker

> **You're on Claude Max. No per-token billing. But you have no idea which project, conversation, or request is burning through your context limits.**

usage-tracker fixes this. A PostToolUse hook captures every tool call with its tokens, project, and the user request that triggered it — turning an opaque usage history into an actionable breakdown by request, project, session, tool, and day.

### How it works

```
User: "review the auth module"
  └─ Read auth.module           → 1,200 tok   ┐
  └─ Grep hook                  →    80 tok   │ same "request"
  └─ Read AuthService.php       → 2,400 tok   │ → total: 4,980 tok
  └─ Bash lint auth/            → 1,300 tok   ┘
```

Each entry stores: timestamp, session, project, tool, model, label, request text, tokens. The report script aggregates into breakdowns you can actually act on.

### The non-obvious part

The hook captures tool calls in isolation — but Claude sends the entire conversation history with every request. This creates a **non-linear underestimation**:

| Message | Actual underestimation |
|---------|----------------------|
| 5       | ~20%                 |
| 20      | ~60%                 |
| 40+     | ~80–90%              |

Use it as a **relative index** for comparing projects, sessions, and request types — not as an absolute cost.

Biggest blind spots:
- **Agent calls** — subagent conversations are completely invisible (500 log tokens = potentially 20,000+ actual)
- **Long conversations** — context accumulates quadratically; start new conversations for independent tasks
- **Active skills** — every loaded SKILL.md adds fixed overhead per request

### Commands

```bash
/usage-tracker install        # Set up hook + scripts
/usage-tracker report hoy     # Today's report
/usage-tracker report semana  # Last 7 days
/usage-tracker top-requests   # Top 15 most expensive requests
/usage-tracker status         # Verify hook is active
```

### Install

```bash
npx skills add j4rk0r/claude-skills@usage-tracker --yes --global
```

---

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

