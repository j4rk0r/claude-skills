# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills auf Expertenniveau fuer Claude Code. Jeder Skill mit **A+ (120/120)** bewertet vor der Veroeffentlichung.

## Alles installieren

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

Oder einzeln installieren:

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

## Skills

| Skill | Beschreibung |
|-------|-------------|
| **[skill-guard](../skills/skill-guard/)** | Erkennt schaedliche Skills, bevor sie Ihre Dateien, Tokens oder Schluessel beruehren. 9-Schichten-Analyse + verifiziertes Audit-Register. |
| **[skill-advisor](../skills/skill-advisor/)** | Erstellt Ausfuehrungsplaene die installierte Skills mit fehlenden Luecken kombinieren — und bietet an, sie zu installieren. Starten Sie nie unterausgeruestet. |
| **[skill-learner](../skills/skill-learner/)** | Erfasst Fehler und speichert Korrekturen dauerhaft, damit derselbe Fehler nie wieder passiert. Funktioniert fuer Skills UND allgemeines Claude-Verhalten. Erstellt optional Verbesserungsvorschlaege fuer Skill-Autoren. |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Drupal 11 Code-Review der aktuellen Branch gegen `develop` mit der Codex-Methodik — 18 in der Produktion erprobte Regeln mit dem *warum* hinter jeder. Erstellt einen strukturierten `.md` Report. |
| **[codex-pr-review](../skills/codex-pr-review/)** | Drupal 11 Pull Request Review mit der Codex-Methodik — gleiche 18 Regeln wie `codex-diff-develop` aber holt den PR via `git fetch origin pull/<N>/head` um beliebige GitHub PRs zu auditieren. |

## skill-guard

> **Sie installieren einen Skill. Er liest Ihre `~/.ssh`, greift Ihren `$GITHUB_TOKEN` und sendet ihn an einen Remote-Server. Sie bemerken nichts.**

skill-guard verhindert das. Er auditiert Skills vor der Installation mit 9 Analyse-Schichten — von statischen Mustern bis zur LLM-Semantikanalyse, die Prompt-Injection erkennt, die als normale Anweisungen getarnt ist.

### Wie es funktioniert

```
Sie moechten einen Skill installieren
        |
        v
skill-guard prueft das gemeinschaftliche Audit-Register
        |
        v
Bereits auditiert (gleicher SHA)?  --> Zeigt vorherigen Bericht
Nicht auditiert?                   --> "Sicherheitsanalyse vor Installation?"
        |
        v
9-Schichten-Analyse: Berechtigungen, Muster, Scripts,
Datenfluss, MCP-Missbrauch, Supply Chain, Reputation...
        |
        v
Score 0-100 → GRUEN / GELB / ROT
        |
        v
GRUEN: auto-installiert | GELB: Sie entscheiden | ROT: starke Warnung
```

### Die 9 Schichten

1. **Frontmatter und Berechtigungen** (20%) — Kein `allowed-tools`? Bash uneingeschraenkt?
2. **Statische Muster** (15%) — URLs, IPs, sensible Pfade, gefaehrliche Befehle
3. **LLM-Semantikanalyse** (30%) — Prompt-Injection, Trojaner, Social Engineering
4. **Gebundelte Scripts** (15%) — Liest JEDES Script. Gefaehrliche Imports, Verschleierung
5. **Datenfluss** (10%) — Mappt Quelle → Ziel. Sensible Daten an externe URLs = Bedrohung
6. **MCP und Tools** — Nicht deklarierte MCP-Nutzung, Exfiltration ueber Slack/GitHub/Monday
7. **Supply Chain** (2%) — Typosquatting, ungepinnte Versionen, Fake-Repos
8. **Reputation** (3%) — Autorenprofil, Repo-Alter, Trojaner-Forks
9. **Anti-Evasion** (5%) — Unicode-Tricks, Homoglyphen, Selbst-Modifikation

### Zwei Analysemodi

- **Vollstaendiges Audit** — 9 Schichten, kompletter Bericht, Register-Persistenz
- **Schnellscan** — Nur Schichten 1+2+3. Auto-Eskalation bei HIGH/CRITICAL-Befunden

### Gemeinschaftliches Audit-Register

Jedes Audit wird in [`skills/skill-guard/audits/`](../skills/skill-guard/audits/) gespeichert, organisiert nach verifiziertem Autor (anthropic, obra, softaworks, etc.). Vor der Analyse prueft skill-guard, ob jemand diese Version bereits auditiert hat. Sofortergebnisse bei SHA-Uebereinstimmung.

**Vertrauensmodell:** Nur das System erstellt und veroeffentlicht Audit-Ergebnisse. Community-Mitglieder beantragen Audits per PR in `audits/requests/` — der Maintainer fuehrt skill-guard aus und veroeffentlicht das Ergebnis. Das verhindert, dass manipulierte Audits in das Register gelangen.

### Installieren

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **Sie installieren 50 Skills. Sie nutzen 5. Die anderen 45 verstauben.**

skill-advisor loest dieses Problem. Er sitzt zwischen Ihnen und Claude, analysiert jede Anweisung und findet den besten Skill aus IHRER installierten Sammlung — bevor die Arbeit beginnt.

### Wie es funktioniert

```
Sie geben eine Anweisung ein
        |
        v
skill-advisor scannt Ihre installierten Skills
        |
        v
Treffer?       --> Empfiehlt 1-5, nach Impact sortiert
Kein Treffer?  --> Faehrt still fort (oder schlaegt einen zum Installieren vor)
```

### Zwei Modi

**Pre-Action** — Bevor Claude beginnt, empfiehlt Skills die das Ergebnis verbessern wuerden.

**Post-Action** — Nach Abschluss der Arbeit, schlaegt den logischen naechsten Schritt vor.

### Was ihn besonders macht

- **Liest IHRE Skills** — Keine hartcodierte Liste. Scannt den System-Reminder dynamisch.
- **Denkt lateral** — "mach es schoener" findet Design-, Animations- UND Accessibility-Audit-Skills.
- **Weiss wann Stille angebracht ist** — Einfache Aufgaben erhalten keine Empfehlungen.
- **Empfiehlt Pipelines** — Erkennt mehrstufige Szenarien und schlaegt die vollstaendige Combo vor.
- **Community-Fallback** — Wenn nichts lokal passt, schlaegt installierbare Skills vor.

### Installieren

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude entschuldigt sich, verspricht Besserung — und macht in der naechsten Sitzung genau denselben Fehler.**

skill-learner durchbricht diesen Kreislauf. Wenn ein Skill oder Claude selbst einen Fehler macht, erfasst es was schiefging, warum, und was stattdessen zu tun ist — als persistente Korrekturdatei die sitzungsuebergreifend erhalten bleibt.

### Hauptmerkmale

- **Erkennt den fehlerhaften Skill automatisch** aus dem Gespraechskontext
- **Dedupliziert** — prueft INDEX.md vor dem Erstellen, fusioniert bei gleichem Problem
- **9 NEVER-Regeln** — verhindert vage Korrekturen, Duplikate und Sicherheits-Bypass
- **Kaltlesetest** — stellt sicher, dass jede Korrektur fuer einen anderen Agenten verstaendlich ist
- **Verbesserungsvorschlaege** — erstellt Vorschlaege mit Diffs fuer den Skill-Autor
- **Zweisprachig** — schreibt Korrekturen in der Sprache des Benutzers

### Installieren

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

### Wie es funktioniert

```
Etwas ist schiefgelaufen
        |
        v
skill-learner erkennt welcher Skill (oder allgemeines Verhalten) fehlschlug
        |
        v
Stellt gezielte Fragen bis der Fehler verstanden ist
        |
        v
Speichert eine strukturierte Korrektur in ~/.claude/skill-corrections/
        |
        v
Naechste Ausfuehrung dieses Skills → Korrektur ist verfuegbar
        |
        v
Optional: erstellt einen Verbesserungsvorschlag fuer den Skill-Autor
```

### Hauptmerkmale

- **Erkennt den fehlerhaften Skill automatisch** aus dem Gespraechskontext
- **Dedupliziert** — prueft INDEX.md vor dem Erstellen, fusioniert bei gleichem Problem
- **9 NEVER-Regeln** — verhindert vage Korrekturen, Duplikate und Sicherheits-Bypass
- **Kaltlesetest** — stellt sicher, dass jede Korrektur fuer einen anderen Agenten verstaendlich ist
- **Verbesserungsvorschlaege** — erstellt Vorschlaege mit Diffs fuer den Skill-Autor
- **Zweisprachig** — schreibt Korrekturen in der Sprache des Benutzers

### Installieren

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **Dein Linter sagt "sieht gut aus" — und drei Wochen spaeter bricht die Produktion wegen eines Hooks zusammen, der nur bei Update laeuft, nicht bei Insert.**

codex-diff-develop ist eine Drupal 11 Code-Review-Skill, die den Diff deiner aktuellen Branch gegen `develop` mit der **Codex-Methodik** auditiert: 18 in der Produktion erprobte Regeln mit dem *warum* hinter jeder. Findet die Bugs, die dein Linter uebersieht — die, die nur um 3 Uhr nachts nach dem Deploy auftauchen.

### Wie es funktioniert

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

### Die 18 Codex-Regeln — jede mit Narbe

Jede Regel enthaelt das **warum** (der Produktionsvorfall, der sie gelehrt hat):

1. **`hook_entity_insert` vs `_update` Vollstaendigkeit** — Logik nur in `_update` ueberspringt brandneue Entitaeten
2. **Aggregate (MAX/MIN/COUNT) auf leeren Tabellen geben NULL zurueck, nicht 0**
6. **Externe APIs ohne `connect_timeout`** — langsamer Provider blockiert Queue Worker
7. **Unbegruendetes `accessCheck(FALSE)`** — stille Permission-Umgehung
9. **Idempotenz bei Retry/Doppelklick** — doppelte Bestellungen, doppelte Mails
11. **Kein Kill-Switch** — 3-Uhr-nachts-Vorfaelle ohne Zeit zum Redeploy
14. **Custom Bloecke/Formatter ohne `getCacheableMetadata()`** — bricht BigPipe still

Vollstaendige Liste mit dem *warum* in [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md).

### NEVER-Liste — 15 Drupal-spezifische Anti-Patterns

- **NIEMALS** einen Stilbefund als "Alta" markieren — verwaessert die Schwere
- **NIEMALS** Refactorings ausserhalb des Diffs vorschlagen ausser bei kritischer Sicherheit
- **NIEMALS** `loadMultiple([])` genehmigen — gibt ALLE Entitaeten zurueck (klassisches Memory Leak)
- **NIEMALS** Batch API ohne `finished` Callback der Fehler behandelt genehmigen

### Codex 5-Fragen-Framework

1. **Welche Art von Aenderung ist das?**
2. **Was ist das Worst Case in der Produktion?**
3. **Was nimmt die Aenderung ausserhalb des Diffs an?**
4. **Ist sie idempotent?**
5. **Kann sie deaktiviert werden?**

### Output

Strukturierter `.md` Report: Executive Summary, Findings nach Kategorie (Sicherheit, Codex-Logik, Standards/DI, Performance, A11y/i18n, Tests/CI), Risiko-Tabelle, Aktionsliste, "Das Positive" Sektion, Final Checklist. Jeder Finding folgt **Problem (Schwere)** → **Risiko** → **Loesung**.

### IDE Auto-Erkennung

Liest `CLAUDE_CODE_ENTRYPOINT` zuerst. Faellt nur auf Ordner-Erkennung zurueck, wenn die Env-Variable nicht eindeutig ist.

### Bewertung

- **`/skill-judge`**: 120/120 (Note A+)
- **`/skill-guard`**: 100/100 (GRUEN) — deklariert minimale `allowed-tools`, kein Netzwerk, kein MCP

### Installieren

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **Dein Reviewer sagt "LGTM" — und drei Wochen spaeter bricht die Produktion wegen eines Hooks zusammen, der nur bei Update laeuft.**

codex-pr-review ist die Schwester-Skill von `codex-diff-develop` fuer **remote Pull Requests**. Gleiche Codex-Methodik, gleiche 18 Regeln, gleiche Vorlagen — aber holt den PR via `git fetch origin pull/<N>/head` um beliebige GitHub PRs nach Nummer zu auditieren.

### Unterschiede zu codex-diff-develop

| Aspekt | codex-diff-develop | codex-pr-review |
|---|---|---|
| Diff-Quelle | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| Output-Ordner | `Revisiones diff/` | `Revisiones PRs/` |
| Dateiname | `lint-review-diff-develop-<branch>.md` | `lint-review-pr<N>.md` |
| Trigger | "diff develop", "codex diff" | "revision PR", "revisar PR #N", "codex PR" |
| Extra NEVER | — | "**NIEMALS** andere PRs im Dokument referenzieren" |
| Extra Edge Cases | — | GitLab-Fallback, PR bereits gemerged, fehlende PR-Nummer |

### Wann was verwenden

- **`codex-diff-develop`**: du arbeitest lokal an einer Branch und willst deine eigenen Aenderungen vor dem Push reviewen
- **`codex-pr-review`**: du willst den PR von jemand anderem (oder deinen nach dem Push) ohne lokalen Checkout reviewen

### Bewertung

- **`/skill-judge`**: 120/120 (Note A+)
- **`/skill-guard`**: 100/100 (GRUEN)

### Installieren

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## Qualitaetsstandards

Jeder Skill wird mit [skill-judge](https://github.com/softaworks/agent-toolkit) bewertet — 8 Dimensionen, 120 Punkte max. **Minimum: B (96/120).**

## Beitragen

1. Fork dieses Repo
2. Skill in `skills/<name>/SKILL.md` erstellen
3. `/skill-judge` ausfuehren — muss B oder hoeher erreichen
4. PR mit Bewertung oeffnen

## Lizenz

[MIT](../LICENSE)
