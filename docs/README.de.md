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
| **[skill-advisor](../skills/skill-advisor/)** | Analysiert jede Anweisung und empfiehlt den richtigen Skill vor der Ausfuehrung. Verpassen Sie nie wieder einen installierten Skill. | 120/120 |
| **[skill-guard](../skills/skill-guard/)** | Sicherheitsauditor — 9-Schichten-Bedrohungserkennung fuer Skills vor der Installation. Gemeinschaftliches Audit-Register. | 120/120 |

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

## Qualitaetsstandards

Jeder Skill wird mit [skill-judge](https://github.com/softaworks/agent-toolkit) bewertet — 8 Dimensionen, 120 Punkte max. **Minimum: B (96/120).**

## Beitragen

1. Fork dieses Repo
2. Skill in `skills/<name>/SKILL.md` erstellen
3. `/skill-judge` ausfuehren — muss B oder hoeher erreichen
4. PR mit Bewertung oeffnen

## Lizenz

[MIT](../LICENSE)
