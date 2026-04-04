# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills auf Expertenniveau fuer Claude Code. Jeder Skill mit **A+ (120/120)** bewertet vor der Veroeffentlichung.

## Installieren

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | Beschreibung | Bewertung |
|-------|-------------|-----------|
| **[skill-advisor](../skills/skill-advisor/)** | 50 Skills installiert — 5 davon genutzt. Verbindet jede Aufgabe mit dem besten Werkzeug, damit nichts verstaubt. | 120/120 |
| **[skill-guard](../skills/skill-guard/)** | Erkennt schaedliche Skills, bevor sie Ihre Dateien, Tokens oder Schluessel beruehren. 9-Schichten-Analyse + verifiziertes Audit-Register. | 120/120 |
| **[skill-learner](../skills/skill-learner/)** | Erfasst Fehler und speichert Korrekturen dauerhaft, damit derselbe Fehler nie wieder passiert. Funktioniert fuer Skills UND allgemeines Claude-Verhalten. Erstellt optional Verbesserungsvorschlaege fuer Skill-Autoren. | 120/120 |

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

## Qualitaetsstandards

Jeder Skill wird mit [skill-judge](https://github.com/softaworks/agent-toolkit) bewertet — 8 Dimensionen, 120 Punkte max. **Minimum: B (96/120).**

## Beitragen

1. Fork dieses Repo
2. Skill in `skills/<name>/SKILL.md` erstellen
3. `/skill-judge` ausfuehren — muss B oder hoeher erreichen
4. PR mit Bewertung oeffnen

## Lizenz

[MIT](../LICENSE)
