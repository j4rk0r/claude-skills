# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Sie haben ein Feature in 3 Gesprachen fertiggestellt. Das 4. Gesprach beginnt bei null, weil der Kontext nicht uberlebt.**

milestone ist ein persistenter Entwicklungs-Tracker, der den vollstandigen Kontext als Markdown-Dateien in Ihrem Projekt speichert. Jeder Meilenstein ist eine eigenstandige Kapsel: Ziel, Teilaufgaben mit Status, Architekturentscheidungen, Code-Referenzen und ein Protokoll dessen, was getan wurde und warum. Laden Sie ihn in jedem Gesprach und machen Sie genau dort weiter, wo Sie aufgehort haben.

## Installieren

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Befehle

| Befehl | Beschreibung |
|--------|-------------|
| `/milestone` | Alle Meilensteine mit Status, Fortschritt und Schnelllade-Links auflisten |
| `/milestone <name>` | Vollstandigen Kontext eines Meilensteins laden (unscharfe Suche) |
| `/milestone init <name>` | Neuen Meilenstein mit Ziel und Teilaufgaben erstellen |
| `/milestone add <name> <inhalt>` | Teilaufgabe, Entscheidung, Notiz oder Referenz hinzufugen |
| `/milestone done <name> <teilaufgabe>` | Teilaufgabe als abgeschlossen markieren |
| `/milestone update <name>` | Kontext nach einer Arbeitssitzung gesammelt aktualisieren |

## Hauptmerkmale

- **Persistent uber Gesprache hinweg** — Dateien leben in `.milestones/` und uberleben jede Sitzung
- **Eigenstandiger Kontext** — jede Datei enthalt alles Notige zur Wiederaufnahme der Arbeit
- **Planungstool-Erkennung** — erkennt automatisch installierte Planungstools und bietet an, deren Ergebnisse zu vereinen
- **Auto-Status** — Status berechnet sich aus den Teilaufgaben-Checkboxen
- **Unscharfe Suche** — tippen Sie "dash" um "dashboard-propietario" zu laden
- **Append-only Kontextlog** — umgekehrt chronologisches Protokoll was passiert ist und warum
- **Globaler Skill, lokale Daten** — einmal installiert, erstellt projektspezifische Daten

## Sicherheit

- Skill-Guard gepruft: **92/100 GREEN**
- Keine Skripte, keine Netzwerkaufrufe, kein MCP-Zugriff
- `allowed-tools: Read Write Edit Glob Grep`
