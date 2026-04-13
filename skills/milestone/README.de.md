# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Sie haben ein Feature in 3 Gesprachen fertiggestellt. Das 4. Gesprach beginnt bei null, weil der Kontext nicht uberlebt.**

milestone v2 ist ein persistenter Entwicklungs-Tracker mit **zweistufigem Cache**: kompakte Speicher-Snapshots (~100 Tokens, automatisch geladen) fuer sofortigen Status und autoritative Dateien fuer die vollstaendige Historie. Es klassifiziert Teilaufgaben als `[simple]` oder `[complex]`, und verlangt einen Plan vor der Ausfuehrung komplexer Arbeit — um den teuren Trial-and-Error-Zyklus von 6+ iterativen Edits zu verhindern.

## Installieren

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Befehle

| Phase | Befehl | Beschreibung |
|-------|--------|--------------|
| Entdeckung | `/milestone` | Alle Milestones mit Status und Fortschritt auflisten |
| Entdeckung | `/milestone <name>` | Kontext laden (Fuzzy-Matching) |
| Planung | `/milestone init <name>` | Neuen Milestone mit Teilaufgaben-Vorschlaegen erstellen |
| Ausfuehrung | `/milestone start <name>` | Neues Terminal mit kompaktem Kontext oeffnen |
| Ausfuehrung | `/milestone done <name> <aufgabe>` | Teilaufgabe als erledigt markieren |
| Review | `/milestone update <name>` | Massen-Update nach Arbeitssitzung |

## Hauptmerkmale

- **Zweistufiger Cache** — Speicher-Snapshot (~100 tok) fuer Lesezugriffe, autoritative Datei fuer Historie. 99% guenstiger.
- **Komplexitaetsklassifikation** — `[simple]` vs `[complex]`. Komplexe sind **blockiert** bis ein Plan existiert.
- **Token-Effizienzregeln** — 3+ Aenderungen gleiche Datei → einzelnes Write (10x guenstiger).
- **Neue Sitzung** — `/milestone start` oeffnet `claude` in neuem Terminal mit kompaktem Kontext.
- **12 NEVER-Regeln** — Split-Brain-Praevention, veraltete Snapshots, Edit-Anti-Patterns.

## Bewertung

- **`/skill-judge`**: 120/120 (Note A+)
- **`/skill-guard`**: 92/100 (GREEN)
