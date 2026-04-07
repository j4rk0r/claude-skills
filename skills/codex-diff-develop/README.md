# codex-diff-develop

> **Your code review tool says "looks good" — and three weeks later production breaks because of a hook that only runs on update, not on insert.**

codex-diff-develop is a Drupal 11 code review skill that audits the diff of your current branch against `develop` using the **Codex methodology**: 18 production-tested rules with the *why* behind each one. It catches the bugs your linter misses — the ones that only show up at 3am after deploy.

## Install

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## How it works

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
Applies the 5-question Codex framework to the diff
        |
        v
Decision tree picks the relevant Codex rules per file type
        |
        v
Reviews ONLY the diff (no out-of-scope suggestions)
        |
        v
Auto-detects your IDE (Antigravity / Cursor / VS Code)
        |
        v
Writes a structured report to <ide>/Revisiones diff/
        |
        v
Self-verifies against a 12-item checklist before delivering
```

## The Codex methodology — 18 rules with scars

Each rule includes the **why** (the production incident that taught it):

1. **`hook_entity_insert` vs `_update` completeness** — logic that lives only in `_update` skips brand-new entities until someone edits them
2. **Aggregates (MAX/MIN/COUNT) on empty tables return NULL, not 0** — `$max + 1` becomes incoherent on the very first record
3. **Direct SQL interpolation** — SQL injection plus apostrophes in real names break the query before reaching production
4. **Hook recursion without static guard** — infinite loops only detected by cron, never in manual testing
5. **Multiple writes without transaction** — partial failures leave inconsistent state, support nightmare
6. **External APIs without `connect_timeout`** — slow provider blocks queue workers and exhausts PHP-FPM
7. **Unjustified `accessCheck(FALSE)`** — silent permission bypass that nobody reviews in future PRs
8. **Insufficient cache invalidation** — "works locally" classic after multi-instance deploy
9. **Idempotency on retry/double-click operations** — duplicate orders, duplicate emails, duplicate charges
10. **Type coherence** between code, schema and DB — `===` fails silently in MySQL strict mode
11. **No kill-switch** — 3am incidents with no time to redeploy
12. **AJAX form alters without `#process`** — alter applies on first render only, lost on AJAX rebuild
13. **`\Drupal::service()` in new classes** — blocks unit tests and kernel tests
14. **Custom blocks/formatters without `getCacheableMetadata()`** — silently breaks BigPipe and Dynamic Page Cache
15. **Outdated config schema** — `drush cim` fails in other environments
16. **Migrations without clean `id_map`** — corrupted rollbacks detected months later
17. **Non-idempotent update hooks** — manual re-execution after partial failure makes the DB worse
18. **`settings.php` overrides clashing with config split** — silently lost on every deploy

## NEVER list — 15 Drupal-specific anti-patterns

A real code reviewer learns these the hard way. Examples:

- **NEVER** mark a style finding (typo, whitespace, comment) as "Alta" — dilutes severity, the team stops reading the real Altas
- **NEVER** suggest refactors outside the diff except for critical security or data loss — breaks PR scope
- **NEVER** approve `\Drupal::service()` in new classes with the argument "it was already there" — perpetuates debt
- **NEVER** approve `accessCheck(FALSE)` without an inline `// accessCheck OK because...` comment
- **NEVER** approve `|raw` in Twig without verifying the source is 100% system-controlled
- **NEVER** approve `entityTypeManager->getStorage()->loadMultiple()` without an empty-array guard — `loadMultiple([])` returns ALL entities (memory leak classic)
- **NEVER** approve Batch API without a `finished` callback handling `$success === FALSE`
- **NEVER** approve `EntityFieldManagerInterface::getFieldStorageDefinitions()` without verifying field exists first — zombie field storage after delete + before `field_purge_batch`
- **NEVER** mark the report "OK" if any High severity finding remains unresolved

## Five-question Codex framework

Before reviewing any chunk, ask yourself:

1. **What kind of change is this?** Hook, refactor, hotfix, migration, config — determines applicable Codex rules
2. **What's the worst-case in production?** Sets the severity floor
3. **What does the change assume that's outside the diff?** Schema, indexes, permissions — omissions live in what you can't see
4. **Is it idempotent?** Retry, double-click, re-deploy, re-import — does anything bad happen?
5. **Can it be turned off?** Kill-switch via config/setting/feature flag for 3am incidents

A worked example walks through applying these to a hypothetical mini-diff.

## Report structure

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branch>)

## Resumen ejecutivo
<2-4 sentences: scope, severity counts, verdict>

## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI

## Riesgos (tabla)
| Área | Riesgo | Severidad | Mitigación |

## Sugerencias accionables (priorizado)
## Lo positivo (because that also belongs in the PR)
## Checklist final
```

Each finding follows **Problema (Severidad)** → **Riesgo** → **Solución** with adapted code from the 14 finding templates in `references/`.

## IDE auto-detection

Reads `CLAUDE_CODE_ENTRYPOINT` first (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Falls back to folder existence detection only if the env var is not conclusive. This prevents the bug of writing reports to a legacy `.cursor/` folder when you're actually in VS Code.

| Detection | Output folder |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (none / CLI) | `docs/revisiones-diff/` |

## Self-verification checklist

Before delivering the report, the skill walks through 12 checks: first line correct, file in the right folder, references actually loaded this session, every finding has Problema/Riesgo/Solución, no Alta is just a style nit, no out-of-scope suggestions, all explanations in Spanish + code in English, etc. If any box stays unchecked, it goes back to fix it.

## Recovery — what to do when things fail

| Symptom | Action |
|---|---|
| `references/*.md` missing | Warn user, do not invent Codex points |
| `git fetch` fails (network) | Continue with local `develop` + note in report |
| `.cursor/` not creatable | Ask user to create folder and retry |
| Diff > 200 files | Ask confirmation before continuing |
| User is on `develop` branch | Abort with clear message |

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

If you want to review a remote PR instead of your current branch, use [`codex-pr-review`](../codex-pr-review/) — same Codex methodology, same references, fetches the PR via `git fetch origin pull/<N>/head`.

## License

MIT
