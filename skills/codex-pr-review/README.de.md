# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Dein Reviewer sagt "LGTM" — und drei Wochen spaeter bricht die Produktion wegen eines Hooks zusammen, der nur bei Update laeuft, nicht bei Insert.**

codex-pr-review ist eine Drupal 11 Pull Request Review Skill, die den PR von GitHub holt und ihn mit der **Codex-Methodik** auditiert: 18 in der Produktion erprobte Regeln mit dem *warum* hinter jeder. Findet die Bugs, die dein Linter uebersieht — die, die nur um 3 Uhr nachts nach dem Deploy auftauchen.

## Installieren

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## Wie es funktioniert

```
Du: "revision Codex PR #42 develop ← feature/alejandro"
        |
        v
Bestaetigt PR-Nummer und Branches (fragt wenn fehlend)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Laedt MANDATORY die References (gleich wie codex-diff-develop)
        |
        v
Wendet Codex 5-Fragen-Framework + Decision Tree an
        |
        v
Reviewt NUR den PR-Diff
        |
        v
Auto-erkennt IDE → schreibt Report nach <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Selbstverifikation gegen 13-Punkte-Checkliste vor Auslieferung
```

## Die 18 Codex-Regeln — jede mit Narbe

Jede Regel enthaelt das **warum**:

1. **`hook_entity_insert` vs `_update` Vollstaendigkeit** — Logik nur in `_update` ueberspringt neue Entitaeten
2. **Aggregate (MAX/MIN/COUNT) auf leeren Tabellen geben NULL zurueck, nicht 0**
3. **Direkte SQL-Interpolation** — SQL Injection plus Apostrophe brechen Queries
4. **Hook-Rekursion ohne statischen Wachschalter** — Endlosschleifen nur von Cron erkannt
5. **Mehrere Schreibvorgaenge ohne Transaktion** — Teilausfaelle = inkonsistenter Zustand
6. **Externe APIs ohne `connect_timeout`** — langsamer Provider blockiert Queue Worker
7. **Unbegruendetes `accessCheck(FALSE)`** — stille Permission-Umgehung
8. **Unzureichende Cache-Invalidierung** — klassisches "funktioniert lokal"
9. **Idempotenz bei Retry/Doppelklick** — doppelte Bestellungen, doppelte E-Mails
10. **Typkohaerenz** zwischen Code, Schema und DB
11. **Kein Kill-Switch** — 3-Uhr-nachts-Vorfaelle ohne Zeit zum Redeploy
12. **AJAX Form-Alters ohne `#process`** — Alter geht beim AJAX-Rebuild verloren
13. **`\Drupal::service()` in neuen Klassen** — blockiert Unit- und Kernel-Tests
14. **Custom Bloecke/Formatter ohne `getCacheableMetadata()`** — bricht BigPipe
15. **Veraltetes Config-Schema** — `drush cim` schlaegt in anderen Umgebungen fehl
16. **Migrationen ohne sauberes `id_map`** — beschaedigte Rollbacks
17. **Nicht-idempotente Update-Hooks** — Re-Ausfuehrung verschlimmert die DB
18. **`settings.php` Overrides die mit Config Split kollidieren** — bei jedem Deploy verloren

## NEVER-Liste — 15 Drupal-spezifische Anti-Patterns

PR-Review-spezifisch:

- **NIEMALS** einen Stilbefund (Tippfehler, Leerzeichen) als "Alta" markieren — verwaessert die Schwere
- **NIEMALS** Refactorings ausserhalb des PRs vorschlagen ausser bei kritischer Sicherheit
- **NIEMALS** andere PRs im Dokument referenzieren oder benennen — der Reviewer verliert den Fokus und vermischt Diskussionen (einzigartig fuer PR-Review, nicht in diff-develop)
- **NIEMALS** `\Drupal::service()` in neuen Klassen genehmigen
- **NIEMALS** `accessCheck(FALSE)` ohne Inline-Kommentar als gut betrachten
- **NIEMALS** `|raw` in Twig genehmigen ohne zu pruefen dass die Quelle systemkontrolliert ist
- **NIEMALS** `loadMultiple([])` ohne Empty-Array-Wachschalter genehmigen
- **NIEMALS** Batch API ohne `finished` Callback der Fehler behandelt genehmigen
- **NIEMALS** den Report als "OK" markieren wenn ein High-Finding ungeloest bleibt

## Codex 5-Fragen-Framework

Vor jedem Review-Block:

1. **Welche Art von Aenderung ist das?** Hook, Refactoring, Hotfix, Migration, Config
2. **Was ist das Worst Case in der Produktion?** Setzt die Schwere-Untergrenze
3. **Was nimmt die Aenderung ausserhalb des Diffs an?** Schema, Indizes, Permissions
4. **Ist sie idempotent?** Retry, Doppelklick, Re-Deploy
5. **Kann sie deaktiviert werden?** Kill-Switch via Config/Setting/Feature Flag

Ein durchgearbeitetes Beispiel zeigt die Anwendung auf einen hypothetischen Mini-PR.

## Report-Struktur

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

Jeder Finding folgt **Problem (Schwere)** → **Risiko** → **Loesung** mit Code aus 14 Vorlagen in `references/`.

## IDE Auto-Erkennung

Liest `CLAUDE_CODE_ENTRYPOINT` zuerst. Faellt nur auf Ordner-Erkennung zurueck wenn die Env-Variable nicht eindeutig ist.

| Erkennung | Ausgabe-Ordner |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (keiner / CLI) | `docs/revisiones-prs/` |

## Selbstverifikations-Checkliste

Vor der Auslieferung durchlaeuft 13 Pruefungen: erste Zeile korrekt, Datei im richtigen Ordner, References in dieser Session geladen, jeder Finding mit Problem/Risiko/Loesung, kein Alta ist nur ein Stil-Nit, **keine anderen PRs referenziert**, etc.

## Recovery — was tun wenn etwas fehlschlaegt

| Symptom | Aktion |
|---|---|
| `references/*.md` fehlt | Benutzer warnen, keine Codex-Punkte erfinden |
| `git fetch origin pull/<N>/head` schlaegt fehl | PR-Nummer und Repo pruefen, oder GitLab-Fallback `merge-requests/<N>/head` |
| Base-Branch lokal nicht vorhanden | `git fetch origin <base>:<base>` |
| `.cursor/` nicht erstellbar | Benutzer bitten den Ordner zu erstellen |
| PR > 200 Dateien | Bestaetigung anfordern bevor weitergemacht wird |
| PR bereits gemerged | Warnen und Review der Historie bestaetigen |
| Benutzer gibt keine PR-Nummer | Fragen, nicht annehmen |

## Bewertung

- **`/skill-judge`**: 120/120 (Note A+) — perfekte Punktzahl in allen 8 Dimensionen
- **`/skill-guard`**: 100/100 (GRUEN) — deklariert minimale `allowed-tools`, kein Netzwerk, kein MCP

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

## Schwester-Skill

Wenn du den Diff deiner *aktuellen Branch* gegen `develop` reviewen willst (kein Remote-PR), verwende [`codex-diff-develop`](../codex-diff-develop/) — gleiche Codex-Methodik, gleiche References, andere Diff-Quelle.

## Lizenz

MIT
