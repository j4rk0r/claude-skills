# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Your manual code review finds 29 issues. You run PHPStan and PHPCS by hand. You ask a reviewer for security and standards. 45 minutes later you finally have a consolidated view — and you missed 140 JS violations because nobody ran PHPCS against the module's JavaScript.**

`lint-drupal-module` is a Drupal 11 lint review skill that runs **four sources in parallel** — PHPStan level 5 (with `phpstan-drupal`), PHPCS (Drupal/DrupalPractice), a `drupal-qa` agent for standards, and a `drupal-security` agent for OWASP vectors — and consolidates the findings into a single actionable report. What used to be 12 manual steps and 30 minutes is now one invocation that finishes in the time the slowest source takes (2-5 min in full mode, 30s-1min in diff mode).

## Install

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## How it works

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
Detects the environment (DDEV with ddev exec, or local composer)
        |
        v
Installs PHPStan + phpstan-drupal if missing (asks first)
        |
        v
Loads references/prompts-agentes.md (mandatory before invoking agents)
        |
        v
Launches 4 sources in parallel, in the same message:
  • Agent drupal-qa   (standards)
  • Agent drupal-security (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Loads references/plantilla-informe.md (mandatory before writing)
        |
        v
Consolidates all four outputs into one markdown report
        |
        v
Auto-detects the IDE (Antigravity / Cursor / VS Code)
        |
        v
Writes to <ide>/Lint reviews/lint-review-<module>-<mode>-<branch>.md
        |
        v
Summarizes the top blockers in chat and asks:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## Two modes

**Full (default)** — analyzes every file in the module. More thorough, slower (~2-5 min). Use before a release, on newly created modules, or for periodic audits.

**Diff** — analyzes only the files changed in the current branch against `origin/develop`. Faster (~30s-1min). Use for mid-development reviews, pre-push validation, or when you only care about what's new.

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<name>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## What it catches that manual reviews miss

The skill was validated against a real Drupal 11 module (32 files). A manual agent-only review flagged 29 issues. Running the skill's full parallelized pipeline surfaced **65 issues** — including 166 PHPCS violations on the module's JavaScript (most auto-fixable with `phpcbf`) that the manual reviewer never checked because JS was outside its scope.

That's the point: a lint review is only as good as its weakest layer. Combining static analysis (PHPStan), style enforcement (PHPCS) and expert agents in parallel catches things no single source sees.

## The report structure

Every report follows the same fixed template (so the team can read reports across modules without re-learning):

1. **Executive summary** — table of findings per source, top 5 blockers, categorical verdict (`APT`, `APT with minor corrections`, `APT with critical corrections`, `NOT APT`)
2. **PHPStan level 5** — errors grouped by file
3. **PHPCS Drupal/DrupalPractice** — violations grouped by file
4. **Standards (drupal-qa)** — findings by severity with fix suggestions
5. **Security (drupal-security)** — vulnerabilities classified 🔴 CRITICAL / 🟠 HIGH / 🟡 MEDIUM / 🟢 LOW / ℹ️ INFO
6. **Prioritized actions** — P0 (blockers), P1 (recommended), P2 (improvements)
7. **Best practices coverage** — checklist of strict_types, OOP hooks, DI, CSRF in routing, cache metadata, config schema, permissions, translation, behaviors, tests
8. **Verification commands** — exact commands to re-run locally

## NEVER (lessons learned the hard way)

- **Never modifies files during the skill.** Reports only. Fixes are a separate phase with explicit user confirmation.
- **Never runs the 4 sources in separate messages.** Parallelization is the core value; serial execution takes 4× longer.
- **Never marks the verdict as "APT" with unresolved HIGH/CRITICAL findings.**
- **Never lists `Unsafe usage of new static()` in Controllers as a blocker** — known false positive of phpstan-drupal with Drupal's standard pattern.
- **Never removes FQCN aliases in `services.yml` without checking whether Hook OOP uses them via type-hint.** Known way to break `drush cr`.
- **Never assumes functional tests pass just because PHPUnit doesn't fail.** If PHPStan reports non-existent methods (`getClient()`, `post()`) in the `tests/` directory, the test is probably failing silently in CI.
- **Never writes the report in English.** Code, commands and class names in English; explanations in Spanish.

## Relation with sister skills

- **`codex-diff-develop`** — reviews business logic on the diff using the Codex 18-rules methodology. Complements this skill (which does static analysis and standards) by catching logic bugs.
- **`codex-pr-review`** — architectural review of a complete PR. One level above this skill.
- **Ideal pre-merge workflow:**
  1. `lint-drupal-module` → mechanical fixes (types, standards, security vectors)
  2. `codex-diff-develop` → business logic fixes
  3. `codex-pr-review` → final architectural review before merging

## Requirements

- Drupal 11 project (detects module via `Glob "**/web/modules/custom/*/*.info.yml"`)
- DDEV recommended (the skill runs tools inside the container via `ddev exec`)
- `drupal-qa` and `drupal-security` subagents available (degrades gracefully to PHPStan + PHPCS only if missing)
- Anthropic Claude with parallel tool use (sequential execution works but is 4× slower)

## License

MIT. See the repo LICENSE.
