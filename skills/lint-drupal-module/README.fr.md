# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Ta revue de code manuelle trouve 29 problèmes. Tu lances PHPStan et PHPCS à la main. Tu demandes à un reviewer de regarder les standards et la sécurité. 45 minutes plus tard tu as enfin une vue consolidée — et tu as manqué 140 violations dans les fichiers JS du module parce que personne n'a lancé PHPCS sur le JavaScript.**

`lint-drupal-module` est une skill de lint review pour Drupal 11 qui exécute **quatre sources en parallèle** — PHPStan niveau 5 (avec `phpstan-drupal`), PHPCS (Drupal/DrupalPractice), un agent `drupal-qa` pour les standards, et un agent `drupal-security` pour les vecteurs OWASP — et consolide les résultats dans un rapport actionnable unique. Ce qui était 12 étapes manuelles et 30 minutes devient une seule invocation qui termine dans le temps pris par la source la plus lente (2-5 min en mode complet, 30s-1min en mode diff).

## Installation

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## Comment ça marche

```
Toi : "lint review du module chat_soporte_tecnico_ia"
        |
        v
Identifie le module (par nom, chemin, ou Glob)
        |
        v
Choisit le mode : complet (par défaut) | diff (vs develop)
        |
        v
Détecte l'environnement (DDEV avec ddev exec, ou composer local)
        |
        v
Installe PHPStan + phpstan-drupal s'ils manquent (en demandant d'abord)
        |
        v
Charge references/prompts-agentes.md (obligatoire avant d'invoquer les agents)
        |
        v
Lance 4 sources en parallèle, dans le même message :
  • Agent drupal-qa        (standards)
  • Agent drupal-security  (OWASP)
  • PHPStan niveau 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Charge references/plantilla-informe.md (obligatoire avant d'écrire)
        |
        v
Consolide les 4 sorties dans un rapport markdown
        |
        v
Auto-détecte l'IDE (Antigravity / Cursor / VS Code)
        |
        v
Écrit dans <ide>/Lint reviews/lint-review-<module>-<mode>-<branche>.md
        |
        v
Résume les top bloqueurs dans le chat et demande :
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## Deux modes

**Complet (par défaut)** — analyse chaque fichier du module. Plus exhaustif, plus lent (~2-5 min). À utiliser avant une release, sur des modules fraîchement créés, ou pour des audits périodiques.

**Diff** — analyse seulement les fichiers modifiés dans la branche courante par rapport à `origin/develop`. Plus rapide (~30s-1min). À utiliser pour des reviews intermédiaires pendant le développement, validation avant push, ou quand seul le nouveau te concerne.

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<nom>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## Ce qu'elle détecte qu'une review manuelle rate

La skill a été validée contre un module Drupal 11 réel (32 fichiers). Une review manuelle uniquement avec agents a signalé 29 problèmes. La skill lançant son pipeline parallélisé complet a fait émerger **65 problèmes** — incluant 166 violations PHPCS sur les JavaScript du module (la plupart auto-corrigibles avec `phpcbf`) que le reviewer manuel n'a jamais vérifiées parce que le JS était hors de son périmètre.

C'est le principe : une lint review ne vaut que ce que vaut sa couche la plus faible. Combiner analyse statique (PHPStan), application de style (PHPCS) et agents experts en parallèle capture des choses qu'aucune source seule ne voit.

## Structure du rapport

Chaque rapport suit le même template fixe (pour que l'équipe puisse lire les rapports de différents modules sans réapprendre) :

1. **Résumé exécutif** — tableau des résultats par source, top 5 bloqueurs, verdict catégorique (`APTE`, `APTE avec corrections mineures`, `APTE avec corrections critiques`, `PAS APTE`)
2. **PHPStan niveau 5** — erreurs groupées par fichier
3. **PHPCS Drupal/DrupalPractice** — violations groupées par fichier
4. **Standards (drupal-qa)** — résultats par sévérité avec suggestions de correction
5. **Sécurité (drupal-security)** — vulnérabilités classées 🔴 CRITIQUE / 🟠 ÉLEVÉ / 🟡 MOYEN / 🟢 BAS / ℹ️ INFO
6. **Actions priorisées** — P0 (bloqueurs), P1 (recommandés), P2 (améliorations)
7. **Couverture des bonnes pratiques** — checklist strict_types, hooks OOP, DI, CSRF dans routing, cache metadata, config schema, permissions, translation, behaviors, tests
8. **Commandes de vérification** — commandes exactes pour ré-exécuter en local

## NEVER (leçons apprises à la dure)

- **Ne modifie jamais les fichiers pendant la skill.** Rapports uniquement. Les corrections sont une phase séparée avec confirmation explicite de l'utilisateur.
- **N'exécute jamais les 4 sources dans des messages séparés.** La parallélisation est la valeur principale ; l'exécution séquentielle prend 4× plus de temps.
- **Ne marque jamais le verdict comme "APTE" avec des résultats ÉLEVÉ/CRITIQUE non résolus.**
- **Ne liste jamais `Unsafe usage of new static()` dans les Controllers comme bloqueur** — faux positif connu de phpstan-drupal avec le pattern standard de Drupal.
- **Ne supprime jamais les alias FQCN dans `services.yml` sans vérifier si Hook OOP les utilise via type-hint.** Manière connue de casser `drush cr`.
- **Ne suppose jamais que les tests fonctionnels passent juste parce que PHPUnit n'échoue pas.** Si PHPStan signale des méthodes inexistantes (`getClient()`, `post()`) dans le répertoire `tests/`, le test échoue probablement silencieusement en CI.
- **N'écrit jamais le rapport en anglais.** Code, commandes et noms de classe en anglais ; explications en espagnol.

## Relation avec les skills sœurs

- **`codex-diff-develop`** — review la logique métier sur le diff en utilisant la méthodologie Codex à 18 règles. Complète cette skill (qui fait de l'analyse statique et des standards) en détectant les bugs de logique.
- **`codex-pr-review`** — review architecturale d'une PR complète. Un niveau au-dessus de cette skill.
- **Workflow idéal pré-merge :**
  1. `lint-drupal-module` → corrections mécaniques (types, standards, vecteurs de sécurité)
  2. `codex-diff-develop` → corrections de logique métier
  3. `codex-pr-review` → review architecturale finale avant merge

## Prérequis

- Projet Drupal 11 (détecte le module via `Glob "**/web/modules/custom/*/*.info.yml"`)
- DDEV recommandé (la skill lance les outils dans le conteneur via `ddev exec`)
- Sous-agents `drupal-qa` et `drupal-security` disponibles (dégradation gracieuse vers PHPStan + PHPCS uniquement s'ils manquent)
- Claude d'Anthropic avec tool use parallèle (l'exécution séquentielle fonctionne mais est 4× plus lente)

## Licence

MIT. Voir le LICENSE du repo.
