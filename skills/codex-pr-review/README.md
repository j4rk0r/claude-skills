# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Your reviewer says "LGTM" — and three weeks later production breaks because the hook only fires on update, not on insert.**

codex-pr-review is a Drupal 11 pull request review skill that fetches the PR from GitHub and audits it using the **Codex methodology**: 18 production-tested rules with the *why* behind each one. It catches the bugs your linter misses — the ones that only show up at 3am after deploy.

## Install

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## How it works

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
Loads MANDATORY references (18 Codex rules + 14 finding templates)
        |
        v
Applies the 5-question Codex framework to the PR
        |
        v
Decision tree picks the relevant Codex rules per file type
        |
        v
Reviews ONLY the PR diff (no out-of-scope suggestions)
        |
        v
Auto-detects your IDE (Antigravity / Cursor / VS Code)
        |
        v
Writes a structured report to <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Self-verifies against a 13-item checklist before delivering
```

## The Codex methodology — 18 rules with scars

Each rule includes the **why** (the production incident that taught it):

1. **`hook_entity_insert` vs `_update` completeness** — logic that lives only in `_update` skips brand-new entities
2. **Aggregates (MAX/MIN/COUNT) on empty tables return NULL, not 0**
3. **Direct SQL interpolation** — SQL injection plus apostrophes break queries
4. **Hook recursion without static guard** — infinite loops only detected by cron
5. **Multiple writes without transaction** — partial failures = inconsistent state
6. **External APIs without `connect_timeout`** — slow provider blocks queue workers
7. **Unjustified `accessCheck(FALSE)`** — silent permission bypass
8. **Insufficient cache invalidation** — "works locally" classic after deploy
9. **Idempotency on retry/double-click** — duplicate orders, duplicate emails
10. **Type coherence** between code, schema and DB
11. **No kill-switch** — 3am incidents with no time to redeploy
12. **AJAX form alters without `#process`** — alter lost on AJAX rebuild
13. **`\Drupal::service()` in new classes** — blocks unit and kernel tests
14. **Custom blocks/formatters without `getCacheableMetadata()`** — breaks BigPipe
15. **Outdated config schema** — `drush cim` fails in other environments
16. **Migrations without clean `id_map`** — corrupted rollbacks
17. **Non-idempotent update hooks** — re-execution after partial failure makes DB worse
18. **`settings.php` overrides clashing with config split** — silently lost on deploy

## NEVER list — 15 Drupal-specific anti-patterns

A real PR reviewer learns these the hard way. PR-specific examples:

- **NEVER** mark a style finding (typo, whitespace) as "Alta" — dilutes severity
- **NEVER** suggest refactors outside the PR diff except for critical security or data loss
- **NEVER** reference or name other PRs in the document — the reviewer loses focus and mixes discussions (unique to PR review, not present in diff-develop)
- **NEVER** approve `\Drupal::service()` in new classes
- **NEVER** approve `accessCheck(FALSE)` without justifying inline comment
- **NEVER** approve `|raw` in Twig without verifying source is system-controlled
- **NEVER** approve `loadMultiple()` without empty-array guard
- **NEVER** approve Batch API without `finished` callback handling failure
- **NEVER** mark the report "OK" if any High severity finding remains unresolved

## Five-question Codex framework

Before reviewing any chunk, ask yourself:

1. **What kind of change is this?** Hook, refactor, hotfix, migration, config
2. **What's the worst-case in production?** Sets the severity floor
3. **What does the change assume that's outside the diff?** Schema, indexes, permissions
4. **Is it idempotent?** Retry, double-click, re-deploy
5. **Can it be turned off?** Kill-switch via config/setting/feature flag

A worked example walks through applying these to a hypothetical mini-PR.

## Report structure

```markdown
Español confirmado.

# Revisión de código — PR #<N> (<base> ← <head>)

## Resumen ejecutivo
## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI
## Riesgos (tabla)
## Sugerencias accionables
## Checklist final
```

Each finding follows **Problema (Severidad)** → **Riesgo** → **Solución** with adapted code from the 14 finding templates in `references/`.

## IDE auto-detection

Reads `CLAUDE_CODE_ENTRYPOINT` first (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Falls back to folder existence detection only if the env var is not conclusive.

| Detection | Output folder |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (none / CLI) | `docs/revisiones-prs/` |

## Self-verification checklist

Before delivering, walks through 13 checks: first line correct, file in right folder, references loaded this session, every finding has Problema/Riesgo/Solución, no Alta is just a style nit, **no other PRs referenced**, no out-of-scope suggestions, all explanations in Spanish + code in English, etc.

## Recovery — what to do when things fail

| Symptom | Action |
|---|---|
| `references/*.md` missing | Warn user, do not invent Codex points |
| `git fetch origin pull/<N>/head` fails | Verify PR number, repo, or fall back to GitLab `merge-requests/<N>/head` |
| Base branch missing locally | `git fetch origin <base>:<base>` |
| `.cursor/` not creatable | Ask user to create folder |
| PR > 200 files | Ask confirmation before continuing |
| PR already merged | Warn and confirm review of historical diff |
| User did not provide PR number | Ask, do not assume |

## Evaluation

- **`/skill-judge`**: 120/120 (Grade A+) — perfect score across all 8 dimensions
- **`/skill-guard`**: 100/100 (GREEN) — declares minimal `allowed-tools`, zero network, zero MCP, zero env var leaks

| Dimension | Score |
|-----------|-------|
| Knowledge Delta | 20/20 |
| Mindset + Procedures | 15/15 |
| Anti-Pattern Quality | 15/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 15/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## Sister skill

If you want to review the diff of your *current branch* against `develop` (not a remote PR), use [`codex-diff-develop`](../codex-diff-develop/) — same Codex methodology, same references, different git source.

## License

MIT
