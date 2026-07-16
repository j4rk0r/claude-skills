# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**
> ⚠️ **v1.1.0 — atomic claim (R14) added.** This translated page may not yet reflect the latest team-mode improvements. See the [English README](README.md), [CHANGELOG.md](CHANGELOG.md) and [SKILL.md](SKILL.md) for full details on the R14 atomic claim.

> **Du hast ein Feature über 3 Konversationen hinweg fertiggestellt. Die 4. beginnt bei null, weil der Kontext nicht überlebt. Und dein Kollege arbeitet mit einer veralteten To-do-Liste.**

milestone v2 ist ein persistenter Entwicklungs-Tracker mit **zweistufigem Cache**: kompakte Memory-Snapshots (~100 Tokens, automatisch geladen) für sofortigen Status und vollständige autoritative Dateien für tiefe Historie. Er klassifiziert Teilaufgaben als `[simple]` oder `[complex]` und verlangt einen Plan, bevor komplexe Arbeit ausgeführt wird — was den teuren Trial-and-Error-Zyklus von 6+ iterativen Edits an derselben Datei verhindert. Der **optionale Team-Modus (R13)** macht das Milestone zu einer einzigen geteilten Quelle der Wahrheit, git-synchronisiert auf einen kanonischen Branch, sodass das ganze Team immer dieselbe aktuelle Liste sieht.

## Installation

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Funktionsweise

```
Du: "/milestone dashboard"
        |
        v
(Team-Modus) prüft zuerst, ob es ein neueres Milestone auf dem kanonischen Branch gibt
        |
        v
Liest den Memory-Snapshot (null Dateilesungen — bereits im Kontext)
        |
        v
Zeigt: Ziel, offene Teilaufgaben, Entscheidungen, letzter Kontexteintrag
        |
        v
Klassifiziert Teilaufgaben: [simple] -> ausführen | [complex] -> erst Plan
        |
        v
Nach der Arbeit: aktualisiert die Milestone-Datei + regeneriert den Snapshot
        |
        v
(Team-Modus) git-synchronisiert .milestones/ auf den kanonischen Branch
        |
        v
Nächste Konversation / nächster Kollege: sofortiger, aktueller Kontext
```

## Befehle

| Phase | Befehl | Beschreibung |
|-------|---------|-------------|
| Discovery | `/milestone` | Listet alle Milestones mit Status und Fortschritt |
| Discovery | `/milestone <name>` | Lädt Kontext (Fuzzy-Match — "dash" findet "dashboard-propietario") |
| Planning | `/milestone init <name>` | Erstellt neues Milestone mit Teilaufgaben-Vorschlägen |
| Execution | `/milestone start <name>` | Öffnet eine frische Terminal-Sitzung mit vorgeladenem Kompaktkontext |
| Execution | `/milestone done <name> <subtask>` | Markiert Teilaufgabe abgeschlossen mit minimalem Edit |
| Review | `/milestone update <name>` | Massen-Update nach einer Arbeitssitzung |

## Hauptfunktionen

- **Zweistufiger Cache** — Memory-Snapshot (~100 Tok) für Lesezugriffe, autoritative Datei für die volle Historie. 99 % günstiger als jedes Mal die ganze Datei zu lesen.
- **Komplexitäts-Klassifizierung** — `[simple]` (1 Datei, klare Änderung) vs. `[complex]` (mehrere Dateien, neue Logik). Komplexe Teilaufgaben sind **blockiert**, bis ein Plan existiert.
- **Token-Effizienz-Regeln** — 3+ Änderungen an derselben Datei → ein einziges Write (10x günstiger als iterative Edits). Keine erneuten Lesungen bereits im Kontext befindlicher Dateien.
- **Neuer-Sitzungs-Befehl** — `/milestone start` öffnet ein frisches `claude` in einem neuen Terminalfenster mit Kompaktkontext und eliminiert den 5-10x-Kostenmultiplikator durch angesammelte Konversationshistorie.
- **Team-Modus (R13, Opt-in)** — ein geteiltes Milestone, git-synchronisiert auf einen kanonischen Branch (Standard `develop`) über ein isoliertes Worktree, sodass das ganze Team dieselbe lebende Liste liest/schreibt. Standardmäßig deaktiviert.
- **Fuzzy-Matching** — Teilnamen eingeben, um Milestones zu laden
- **Append-only-Kontextprotokoll** — umgekehrt chronologische Aufzeichnung dessen, was passiert ist und warum
- **17 NEVER-Regeln** — decken Split-Brain-Prävention, veraltete Snapshots, Edit-Anti-Patterns und Team-Git-Sync-Risiken ab

## Team-Modus (R13 + R14) — Opt-in

Ohne dies ist das Milestone eine maschinenlokale Datei. In einem Team entartet das zu duplizierten Listen (jeder Feature-Branch editiert dieselbe Datei) und veralteten To-do-Listen. Der Team-Modus macht das Milestone zu einer **einzigen geteilten Quelle der Wahrheit auf einem kanonischen Branch**, die nur gegen diesen Branch über ein dediziertes Worktree editiert wird — niemals innerhalb der Code-Branches. Er **entdeckt Milestones, die andere Mitglieder erstellt haben**, bevor du eines auflistest oder erstellst (sodass du niemals `foo` duplizierst, wenn ein Kollege es vor einer Minute angelegt hat), und er **reserviert jede Teilaufgabe atomar** in dem Moment, in dem jemand anfängt daran zu arbeiten — sodass zwei Personen nie dasselbe machen, und das System sagt dir, *wer* zuerst da war.

Pro Projekt in `.milestones/config.yml` aktivieren:

```yaml
milestone_sync:
  enabled: true        # fehlt oder false -> der gesamte Team-Modus ist ein stiller No-op
  branch: develop      # kanonischer Branch (Standard: develop)
  path: .milestones     # synchronisiertes Unterverzeichnis (Standard: .milestones)
```

### R13 — geteilte Quelle der Wahrheit

- **Beim Lesen** (`/milestone <name>`, `/milestone sync`): holt den kanonischen Branch und warnt, falls ein Kollege das Milestone vorangebracht hat, mit dem Angebot, es zu übernehmen, bevor du arbeitest.
- **Beim Schreiben** (init / update / done / Sitzungsende): nach dem Aktualisieren des Snapshots committet es **nur** `<path>/<slug>.md` und pusht es auf den kanonischen Branch über ein isoliertes Worktree unter `.git/` — dein Code-Branch und dein Working Tree werden nie berührt.
- **PR-Stempel**: eine Teilaufgabe, deren Arbeit in einem offenen PR liegt, behält ihren Zustand `[~]` mit einer Inline-Annotation `` `⏳ PR #N` ``.

### R14 — atomarer Claim, bevor Code angefasst wird

Wenn du `/milestone start` ausführst, **reserviert das System die Teilaufgabe im kanonischen Branch, BEVOR du irgendeinen Code anfasst**. Die Zeile wird zu `[>]` mit einer Inline-Annotation:

```
- [>] 1.4 [complex] Stripe integration — `🔒 Jane Doe (jdoe) · 2026-05-26 15:01` [Backend]
```

- **Atomar via `git push --fast-forward`**: Wenn zwei Mitglieder gleichzeitig dieselbe Teilaufgabe beanspruchen wollen, gewinnt nur ein Fast-Forward-Push. Der Verlierer holt (fetch), revalidiert, sieht den Claim des Gewinners und bricht mit `race-lost:<winner>` ab — es sagt dir genau, wer sie genommen hat. Hatte das andere Mitglied den Claim bereits veröffentlicht, bekommst du direkt `already-claimed:<winner>`. Ein Doppel-Claim ist unmöglich.
- **Retry-Schleife, kein einzelner Versuch**: bei einem verlorenen Fast-Forward rebast der Claim und revalidiert bis zu 5 Mal, sodass bei 3+ gleichzeitigen Beanspruchern ein irreführendes `commit-pending-push` nie auftaucht — dieser Status bedeutet jetzt nur noch ein echtes Push-Problem (Auth / geschützter Branch / Netzwerk).
- **Live-Verifikation zwingend**: `claim` führt `git fetch` aus und bricht mit `noop:fetch-failed` ab, wenn die Netzwerkprüfung fehlschlägt. Kein Beanspruchen gegen veraltete lokale Daten.
- **`/milestone`-Auflistung im Team-Modus muss Claims konsultieren**: die Liste der Milestones zeigt, wer was reserviert hat. Eine von jemand anderem beanspruchte Teilaufgabe kann für dich nie als „frei“ erscheinen.
- **Audit-Trail**: jeder Claim/Release ist ein dedizierter Commit auf `<branch>` (`chore(milestone): claim <slug> <X.Y> by <Jane Doe (jdoe)>`). Die Branch-Historie *ist* das Koordinationsprotokoll des Teams.
- **Veraltete Claims werden beim Start angezeigt**: ist alles Freie vergeben, aber ein Claim älter als 24 Std., schlägt `/milestone start` das bewusste Override vor (`release --force` + erneut beanspruchen), statt es nur aufzulisten.
- **Übergabe via `/milestone release <slug> <X.Y> --force`** bei Bedarf (Urlaub, Maschine aus, Verweigerung). Füge eine Notiz in `## Contexto` hinzu, die den erzwungenen Release begründet; der ursprüngliche Beansprucher sieht beim nächsten Mal `not-claimed`.

### Index-Sync — nie ein Duplikat erstellen (H4)

R13/R14 synchronisieren jeweils eine `<slug>.md` auf einmal, aber das allein kann **neue Milestones, die ein Kollege erstellt hat und die du lokal nicht hast**, nicht aufdecken. Der Index-Sync schließt diese Lücke, indem er den gesamten Katalog der veröffentlichten Milestones liest, bevor du auflistest oder erstellst:

- **`milestone-sync.sh index <root>`** listet jedes Milestone auf dem kanonischen Branch als `<slug>` · `<created_by>` · `<created_at>` · `<updated_at>` auf (Autor/Datum aus dem Commit, der die Datei *hinzugefügt* hat).
- **Bei `/milestone init`**: der vorgeschlagene Name wird gegen den Index abgeglichen (exakt und „Near-Miss“ unter Ignorieren von `-`/`_`/Groß-Kleinschreibung). Bei einer Kollision → wird es **nicht** erstellt; es sagt dir, **wer es wann erstellt hat**, und bietet an, es zu laden, statt zu duplizieren.
- **Bei `/milestone` (Liste)**: Milestones, die auf dem Branch vorhanden, aber nicht lokal sind, werden als `🆕 remote · created by <handle>` angezeigt, sodass du auf einen Blick siehst, was andere begonnen haben, noch bevor du pullst.

### Helper-Auto-Update (H1)

Der Helper installiert sich unter `~/.claude/milestone-sync.sh`. Damit nicht zwei Maschinen unterschiedliche Claim-Logik ausführen, ist er **versioniert**: die Skill vergleicht die installierte `version` mit der Referenzkopie und kopiert erneut, wenn sie sich unterscheiden (oder wenn sie fehlt), beim ersten Sync jeder Sitzung.

### Zentraler Modus & Onboarding

Im zentralen Modus (v1.2.0) liegen die Konfiguration und die autoritativen Dateien im geteilten Memories-Repo, sodass das Client-Repo sauber bleibt. `references/team-bootstrap.sh` bindet ein neues Mitglied ein: klont/aktualisiert dieses Repo, installiert die Skill + den Helper und verifiziert die git-Identität, die Claims signiert.

### Grenze — ehrliche Abgrenzung

Git ist verteilt: der Index und die Claims sehen nur, was **auf dem kanonischen Branch** liegt. Ein Claim, den jemand hält, ohne zu pushen, ist unsichtbar — genau wie jeder lokale Commit. Genau deshalb erzwingt R14, dass der Claim **im Moment des Starts veröffentlicht wird** (vor der ersten Codezeile) — „eine Aufgabe starten“ und „alle sehen es“ werden zum selben atomaren Akt.

### Gemeinsames Verhalten

- **Anmutige Degradation**: kein git / kein Remote / kein kanonischer Branch / Block fehlt → stiller No-op. Das Zero-Dependency-Versprechen bleibt bestehen.
- **Umgeht nie die Guards**: wird ein Push von einem Sicherheits-Guard oder der Auth blockiert, bleibt der Commit im Worktree und du erhältst den exakten auszuführenden Befehl — der Fehler wird nie verschwiegen und deine Arbeit nie blockiert.

## Architektur

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-geladen, ~100 Tok)
<project-root>/.milestones/<slug>.md                      ← AUTORITATIV (volle Historie)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Pläne für [complex] Teilaufgaben
<project-root>/.git/milestone-sync-wt/                     ← Isoliertes R13-Worktree (nur Team-Modus)
```

## Was es von v1 unterscheidet

| Aspekt | v1 | v2 |
|--------|----|----|
| Ladekosten | ~8.300 Tok (Read volle Datei + Templates) | ~100 Tok (Memory-Snapshot) |
| Listenkosten | ~8.750 Tok (Read aller Dateien) | ~400 Tok (nur Frontmatter, limit:8) |
| Komplexe Teilaufgaben | Kein Gate — Trial-and-Error | Plan vor Ausführung erforderlich |
| Sitzungsverwaltung | Gleiche Konversation (Kontext akkumuliert) | `/milestone start` öffnet frische Sitzung |
| Referenz-Laden | Lädt immer templates.md | Nur bei `/milestone init` |
| Team-Kollaboration | Keine — nur lokale Datei | Opt-in git-synchronisiertes geteiltes Milestone (R13) |

## Bewertung

- **`/skill-judge`**: 120/120 (Note A+)
- **`/skill-guard`**: 92/100 (GREEN) — keine Skripte im Normalbetrieb ausgeführt, kein Netzwerk, kein MCP. R13 (Opt-in, standardmäßig aus) ist der einzige Pfad, der git-Operationen durchführt.

## Sicherheit

- Standardmäßig liest/schreibt nur lokale `.milestones/*.md`- und Memory-Snapshot-Dateien. Kein Netzwerk, keine Skripte im Normalbetrieb.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash wird für `/milestone start` genutzt (installiert das Skript bei Erstnutzung automatisch) und, **nur wenn der Team-Modus explizit aktiviert ist**, für `milestone-sync.sh` — das `git fetch`/`git push` begrenzt auf `<path>/` gegen den kanonischen Branch über ein isoliertes Worktree ausführt. Standardmäßig deaktiviert; pusht nie Code; umgeht nie Sicherheits-Guards (blockierter Push → gemeldet, nicht verschwiegen).
