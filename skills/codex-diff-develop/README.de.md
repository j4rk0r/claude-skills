# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Dein Linter sagt "sieht gut aus" — und drei Wochen spaeter bricht die Produktion wegen eines Hooks zusammen, der nur bei Update laeuft, nicht bei Insert.**

codex-diff-develop ist eine Drupal 11 Code-Review-Skill, die den Diff deiner aktuellen Branch gegen `develop` mit der **Codex-Methodik** auditiert: 18 in der Produktion erprobte Regeln mit dem *warum* hinter jeder. Findet die Bugs, die dein Linter uebersieht — die, die nur um 3 Uhr nachts nach dem Deploy auftauchen.

## Installieren

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## Wie es funktioniert

```
Du: "revision diff develop"
        |
        v
Erkennt Kontext: Branch, drupal/ Unterordner, Dateitypen im Diff
        |
        v
Laedt MANDATORY die References (18 Codex-Regeln + 14 Vorlagen)
        |
        v
Wendet das Codex 5-Fragen-Framework an
        |
        v
Decision Tree waehlt Codex-Regeln pro Dateityp
        |
        v
Reviewt NUR den Diff, keine Vorschlaege ausserhalb des Scopes
        |
        v
Auto-erkennt IDE → schreibt Report nach .vscode/.cursor/.antigravity
        |
        v
Selbstverifikation gegen 12-Punkte-Checkliste vor Auslieferung
```

## Die 18 Codex-Regeln — jede mit Narbe

Jede Regel enthaelt das **warum** (der Produktionsvorfall, der sie gelehrt hat):

1. **`hook_entity_insert` vs `_update` Vollstaendigkeit** — Logik nur in `_update` ueberspringt brandneue Entitaeten
2. **Aggregate (MAX/MIN/COUNT) auf leeren Tabellen geben NULL zurueck, nicht 0**
3. **Direkte SQL-Interpolation** — SQL Injection plus Apostrophe in echten Namen brechen die Query
4. **Hook-Rekursion ohne statischen Wachschalter** — Endlosschleifen nur von Cron erkannt
5. **Mehrere Schreibvorgaenge ohne Transaktion** — Teilausfaelle = inkonsistenter Zustand
6. **Externe APIs ohne `connect_timeout`** — langsamer Provider blockiert Queue Worker
7. **Unbegruendetes `accessCheck(FALSE)`** — stille Permission-Umgehung
8. **Unzureichende Cache-Invalidierung** — klassisches "funktioniert lokal" nach Deploy
9. **Idempotenz bei Retry/Doppelklick** — doppelte Bestellungen, doppelte E-Mails
10. **Typkohaerenz** zwischen Code, Schema und DB
11. **Kein Kill-Switch** — 3-Uhr-nachts-Vorfaelle ohne Zeit zum Redeploy
12. **AJAX Form-Alters ohne `#process`** — Alter geht beim AJAX-Rebuild verloren
13. **`\Drupal::service()` in neuen Klassen** — blockiert Unit- und Kernel-Tests
14. **Custom Bloecke/Formatter ohne `getCacheableMetadata()`** — bricht BigPipe still
15. **Veraltetes Config-Schema** — `drush cim` schlaegt in anderen Umgebungen fehl
16. **Migrationen ohne sauberes `id_map`** — beschaedigte Rollbacks Monate spaeter erkannt
17. **Nicht-idempotente Update-Hooks** — Re-Ausfuehrung nach Teilausfall verschlimmert die DB
18. **`settings.php` Overrides die mit Config Split kollidieren** — bei jedem Deploy still verloren

## NEVER-Liste — 15 Drupal-spezifische Anti-Patterns

- **NIEMALS** einen Stilbefund (Tippfehler, Leerzeichen) als "Alta" markieren — verwaessert die Schwere
- **NIEMALS** Refactorings ausserhalb des Diffs vorschlagen ausser bei kritischer Sicherheit
- **NIEMALS** `\Drupal::service()` in neuen Klassen mit dem Argument "war schon da" genehmigen
- **NIEMALS** `accessCheck(FALSE)` ohne Inline-Kommentar als gut betrachten
- **NIEMALS** `|raw` in Twig genehmigen ohne zu pruefen dass die Quelle 100% systemkontrolliert ist
- **NIEMALS** `loadMultiple([])` genehmigen — gibt ALLE Entitaeten zurueck (klassisches Memory Leak)
- **NIEMALS** Batch API ohne `finished` Callback der `$success === FALSE` behandelt genehmigen
- **NIEMALS** `EntityFieldManagerInterface::getFieldStorageDefinitions()` ohne Pruefung dass das Field existiert
- **NIEMALS** den Report als "OK" markieren wenn ein High-Finding ungeloest bleibt

## Codex 5-Fragen-Framework

Vor jedem Review-Block:

1. **Welche Art von Aenderung ist das?** Hook, Refactoring, Hotfix, Migration, Config
2. **Was ist das Worst Case in der Produktion?** Setzt die Schwere-Untergrenze
3. **Was nimmt die Aenderung ausserhalb des Diffs an?** Schema, Indizes, Permissions
4. **Ist sie idempotent?** Retry, Doppelklick, Re-Deploy
5. **Kann sie deaktiviert werden?** Kill-Switch via Config/Setting/Feature Flag

Ein durchgearbeitetes Beispiel zeigt Schritt fuer Schritt die Anwendung auf einen hypothetischen Mini-Diff.

## Report-Struktur

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branch>)

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
## Lo positivo
## Checklist final
```

Jeder Finding folgt **Problem (Schwere)** → **Risiko** → **Loesung** mit Code aus 14 Vorlagen in `references/`.

## IDE Auto-Erkennung

Liest `CLAUDE_CODE_ENTRYPOINT` zuerst (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Faellt nur auf Ordner-Erkennung zurueck wenn die Env-Variable nicht eindeutig ist.

| Erkennung | Ausgabe-Ordner |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (keiner / CLI) | `docs/revisiones-diff/` |

## Selbstverifikations-Checkliste

Vor der Auslieferung durchlaeuft die Skill 12 Pruefungen: erste Zeile korrekt, Datei im richtigen Ordner, References in dieser Session geladen, jeder Finding mit Problem/Risiko/Loesung, kein Alta ist nur ein Stil-Nit, keine Vorschlaege ausserhalb des Scopes, etc.

## Recovery — was tun wenn etwas fehlschlaegt

| Symptom | Aktion |
|---|---|
| `references/*.md` fehlt | Benutzer warnen, keine Codex-Punkte erfinden |
| `git fetch` schlaegt fehl (Netzwerk) | Mit lokalem `develop` weitermachen + Notiz im Report |
| `.cursor/` nicht erstellbar | Benutzer bitten den Ordner zu erstellen |
| Diff > 200 Dateien | Bestaetigung anfordern bevor weitergemacht wird |
| Benutzer ist auf `develop` | Mit klarer Nachricht abbrechen |

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

Wenn du einen Remote-PR statt deiner aktuellen Branch reviewen willst, verwende [`codex-pr-review`](../codex-pr-review/) — gleiche Codex-Methodik, gleiche References, holt den PR via `git fetch origin pull/<N>/head`.

## Lizenz

MIT
