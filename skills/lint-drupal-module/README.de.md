# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Dein manueller Code-Review findet 29 Issues. Du führst PHPStan und PHPCS manuell aus. Du fragst einen Reviewer nach Standards und Sicherheit. 45 Minuten später hast du endlich eine konsolidierte Sicht — und du hast 140 JS-Verstöße übersehen, weil niemand PHPCS gegen das JavaScript des Moduls ausgeführt hat.**

`lint-drupal-module` ist eine Drupal-11-Lint-Review-Skill, die **vier Quellen parallel** ausführt — PHPStan Level 5 (mit `phpstan-drupal`), PHPCS (Drupal/DrupalPractice), einen `drupal-qa`-Agenten für Standards und einen `drupal-security`-Agenten für OWASP-Vektoren — und die Befunde in einem einzigen umsetzbaren Bericht konsolidiert. Was vorher 12 manuelle Schritte und 30 Minuten waren, ist jetzt ein einziger Aufruf, der in der Zeit der langsamsten Quelle fertig wird (2-5 Min im vollständigen Modus, 30s-1min im Diff-Modus).

## Installation

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## Wie es funktioniert

```
Du: "lint review des Moduls chat_soporte_tecnico_ia"
        |
        v
Identifiziert das Modul (per Name, Pfad oder Glob)
        |
        v
Wählt den Modus: vollständig (Standard) | diff (vs develop)
        |
        v
Erkennt die Umgebung (DDEV mit ddev exec, oder lokaler composer)
        |
        v
Installiert PHPStan + phpstan-drupal falls fehlend (fragt zuerst)
        |
        v
Lädt references/prompts-agentes.md (Pflicht vor Agent-Aufruf)
        |
        v
Startet 4 Quellen parallel in derselben Nachricht:
  • Agent drupal-qa         (Standards)
  • Agent drupal-security   (OWASP)
  • PHPStan Level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Lädt references/plantilla-informe.md (Pflicht vor dem Schreiben)
        |
        v
Konsolidiert alle 4 Ausgaben in einem Markdown-Bericht
        |
        v
Erkennt die IDE automatisch (Antigravity / Cursor / VS Code)
        |
        v
Schreibt nach <ide>/Lint reviews/lint-review-<modul>-<modus>-<branch>.md
        |
        v
Fasst die Top-Blocker im Chat zusammen und fragt:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## Zwei Modi

**Vollständig (Standard)** — analysiert jede Datei im Modul. Gründlicher, langsamer (~2-5 Min). Verwende es vor einem Release, bei neu erstellten Modulen oder für regelmäßige Audits.

**Diff** — analysiert nur die Dateien, die im aktuellen Branch gegenüber `origin/develop` geändert wurden. Schneller (~30s-1min). Verwende es für Reviews während der Entwicklung, Validierung vor Push, oder wenn dich nur das Neue interessiert.

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<name>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## Was es erkennt, das manuelle Reviews verpassen

Die Skill wurde gegen ein echtes Drupal-11-Modul (32 Dateien) validiert. Ein manuelles Review nur mit Agenten markierte 29 Issues. Das Ausführen der vollständigen parallelisierten Pipeline der Skill brachte **65 Issues** ans Licht — darunter 166 PHPCS-Verstöße im JavaScript des Moduls (die meisten auto-korrigierbar mit `phpcbf`), die der manuelle Reviewer nie überprüft hatte, weil JS außerhalb seines Scopes war.

Darum geht es: Ein Lint-Review ist nur so gut wie seine schwächste Schicht. Die Kombination aus statischer Analyse (PHPStan), Stil-Durchsetzung (PHPCS) und Experten-Agenten parallel erfasst Dinge, die keine einzelne Quelle sieht.

## Berichtsstruktur

Jeder Bericht folgt derselben festen Vorlage (damit das Team Berichte verschiedener Module ohne Umlernen lesen kann):

1. **Executive Summary** — Tabelle der Befunde pro Quelle, Top 5 Blocker, kategorisches Urteil (`GEEIGNET`, `GEEIGNET mit kleinen Korrekturen`, `GEEIGNET mit kritischen Korrekturen`, `NICHT GEEIGNET`)
2. **PHPStan Level 5** — Fehler gruppiert nach Datei
3. **PHPCS Drupal/DrupalPractice** — Verstöße gruppiert nach Datei
4. **Standards (drupal-qa)** — Befunde nach Schweregrad mit Lösungsvorschlägen
5. **Sicherheit (drupal-security)** — Verwundbarkeiten klassifiziert 🔴 KRITISCH / 🟠 HOCH / 🟡 MITTEL / 🟢 NIEDRIG / ℹ️ INFO
6. **Priorisierte Aktionen** — P0 (Blocker), P1 (empfohlen), P2 (Verbesserungen)
7. **Best-Practices-Abdeckung** — Checkliste von strict_types, OOP-Hooks, DI, CSRF in Routing, Cache-Metadaten, Config-Schema, Permissions, Translation, Behaviors, Tests
8. **Verifikationsbefehle** — exakte Befehle zur lokalen erneuten Ausführung

## NEVER (auf die harte Tour gelernte Lektionen)

- **Ändert niemals Dateien während der Skill.** Nur Berichte. Fixes sind eine separate Phase mit expliziter Benutzerbestätigung.
- **Führt die 4 Quellen niemals in getrennten Nachrichten aus.** Parallelisierung ist der Kernwert; serielle Ausführung dauert 4× länger.
- **Markiert das Urteil niemals als "GEEIGNET", wenn ungelöste HOCH/KRITISCH-Befunde existieren.**
- **Listet `Unsafe usage of new static()` in Controllern niemals als Blocker** — bekanntes False Positive von phpstan-drupal mit Drupals Standard-Pattern.
- **Entfernt FQCN-Aliase in `services.yml` niemals, ohne zu prüfen, ob Hook OOP sie per Type-Hint verwendet.** Bekannter Weg, `drush cr` zu brechen.
- **Nimmt niemals an, dass Functional Tests bestehen, nur weil PHPUnit nicht fehlschlägt.** Wenn PHPStan nicht-existente Methoden (`getClient()`, `post()`) im `tests/`-Verzeichnis meldet, schlägt der Test wahrscheinlich stillschweigend im CI fehl.
- **Schreibt den Bericht niemals auf Englisch.** Code, Befehle und Klassennamen auf Englisch; Erklärungen auf Spanisch.

## Beziehung zu Geschwister-Skills

- **`codex-diff-develop`** — reviewt Business-Logik im Diff mit der Codex-18-Regeln-Methodik. Ergänzt diese Skill (die statische Analyse und Standards macht) durch das Erkennen von Logik-Bugs.
- **`codex-pr-review`** — architektonisches Review eines kompletten PRs. Eine Ebene über dieser Skill.
- **Idealer Pre-Merge-Workflow:**
  1. `lint-drupal-module` → mechanische Fixes (Typen, Standards, Sicherheitsvektoren)
  2. `codex-diff-develop` → Business-Logik-Fixes
  3. `codex-pr-review` → finales architektonisches Review vor dem Mergen

## Anforderungen

- Drupal-11-Projekt (erkennt das Modul via `Glob "**/web/modules/custom/*/*.info.yml"`)
- DDEV empfohlen (die Skill führt Tools im Container via `ddev exec` aus)
- Subagenten `drupal-qa` und `drupal-security` verfügbar (degradiert elegant zu nur PHPStan + PHPCS falls fehlend)
- Anthropic Claude mit parallelem Tool Use (sequenzielle Ausführung funktioniert, ist aber 4× langsamer)

## Lizenz

MIT. Siehe LICENSE im Repo.
