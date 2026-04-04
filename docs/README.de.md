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

## Qualitaetsstandards

Jeder Skill wird mit [skill-judge](https://github.com/softaworks/agent-toolkit) bewertet — 8 Dimensionen, 120 Punkte max. **Minimum: B (96/120).**

## Beitragen

1. Fork dieses Repo
2. Skill in `skills/<name>/SKILL.md` erstellen
3. `/skill-judge` ausfuehren — muss B oder hoeher erreichen
4. PR mit Bewertung oeffnen

## Lizenz

[MIT](../LICENSE)
