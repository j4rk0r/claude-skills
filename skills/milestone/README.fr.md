# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**
> ⚠️ **v1.1.0 — atomic claim (R14) added.** This translated page may not yet reflect the latest team-mode improvements. See the [English README](README.md), [CHANGELOG.md](CHANGELOG.md) and [SKILL.md](SKILL.md) for full details on the R14 atomic claim.

> **Vous avez terminé une fonctionnalité sur 3 conversations. La 4ᵉ repart de zéro car le contexte ne survit pas. Et votre collègue travaille sur une liste de tâches obsolète.**

milestone v2 est un traqueur de développement persistant avec un **cache à deux niveaux** : snapshots de mémoire compacts (~100 tokens, auto-chargés) pour un état instantané, et fichiers de référence complets pour l'historique profond. Il classe les sous-tâches en `[simple]` ou `[complex]`, exigeant un plan avant d'exécuter un travail complexe — évitant le coûteux cycle d'essais-erreurs de 6+ éditions itératives sur le même fichier. Le **mode équipe optionnel (R13)** fait du milestone une source de vérité unique partagée, git-synchronisée sur une branche canonique pour que toute l'équipe voie toujours la même liste à jour.

## Installation

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Fonctionnement

```
Vous : "/milestone dashboard"
        |
        v
(mode équipe) vérifie d'abord s'il y a un milestone plus récent sur la branche canonique
        |
        v
Lit le snapshot de mémoire (zéro lecture de fichier — déjà en contexte)
        |
        v
Affiche : objectif, sous-tâches en attente, décisions, dernière entrée de contexte
        |
        v
Classe les sous-tâches : [simple] -> exécuter | [complex] -> plan d'abord
        |
        v
Après le travail : met à jour le fichier milestone + régénère le snapshot
        |
        v
(mode équipe) git-synchronise .milestones/ sur la branche canonique
        |
        v
Conversation suivante / collègue suivant : contexte instantané et à jour
```

## Commandes

| Phase | Commande | Description |
|-------|---------|-------------|
| Discovery | `/milestone` | Liste tous les milestones avec état et progression |
| Discovery | `/milestone <name>` | Charge le contexte (fuzzy match — "dash" trouve "dashboard-propietario") |
| Planning | `/milestone init <name>` | Crée un nouveau milestone avec propositions de sous-tâches |
| Execution | `/milestone start <name>` | Ouvre une nouvelle session terminal avec contexte compact préchargé |
| Execution | `/milestone done <name> <subtask>` | Marque une sous-tâche terminée avec édition minimale |
| Review | `/milestone update <name>` | Mise à jour groupée après une session de travail |

## Fonctionnalités clés

- **Cache à deux niveaux** — snapshot de mémoire (~100 tok) pour les lectures, fichier de référence pour l'historique complet. 99 % moins cher que lire le fichier entier à chaque fois.
- **Classification par complexité** — `[simple]` (1 fichier, changement clair) vs `[complex]` (multi-fichiers, logique nouvelle). Les sous-tâches complexes sont **bloquées** jusqu'à ce qu'un plan existe.
- **Règles d'efficacité des tokens** — 3+ changements au même fichier → un seul Write (10x moins cher que des Edits itératifs). Pas de relecture des fichiers déjà en contexte.
- **Commande de nouvelle session** — `/milestone start` ouvre un `claude` frais dans une nouvelle fenêtre de terminal avec contexte compact, éliminant le multiplicateur de coût 5-10x de l'historique de conversation accumulé.
- **Mode équipe (R13, opt-in)** — un milestone partagé unique, git-synchronisé sur une branche canonique (défaut `develop`) via un worktree isolé, pour que toute l'équipe lise/écrive la même liste vivante. Désactivé par défaut.
- **Fuzzy matching** — tapez des noms partiels pour charger les milestones
- **Journal de contexte append-only** — enregistrement chronologique inverse de ce qui s'est passé et pourquoi
- **17 règles NEVER** — couvrant la prévention du split-brain, les snapshots obsolètes, les anti-patterns d'édition et les risques du git-sync en équipe

## Mode équipe (R13) — opt-in

Sans cela, le milestone est un fichier local par machine. En équipe cela dégénère en listes dupliquées (chaque feature branch édite le même fichier) et listes de tâches obsolètes. Le mode équipe fait du milestone une **source de vérité unique partagée sur une branche canonique**, éditée uniquement contre cette branche via un worktree dédié — jamais dans les branches de code.

Activez-le par projet dans `.milestones/config.yml` :

```yaml
milestone_sync:
  enabled: true        # absent ou false -> tout R13 est un no-op silencieux
  branch: develop      # branche canonique (défaut : develop)
  path: .milestones     # sous-dossier synchronisé (défaut : .milestones)
```

- **En lecture** (`/milestone <name>`, `/milestone sync`) : récupère la branche canonique et, si un collègue a fait avancer le milestone, avertit et propose de l'adopter avant que vous travailliez.
- **En écriture** (init / update / done / fin de session) : après avoir rafraîchi le snapshot, commit **uniquement** `<path>/<slug>.md` et le push sur la branche canonique via un worktree isolé sous `.git/` — votre branche de code et votre working tree ne sont jamais touchés.
- **Estampille de PR** : une sous-tâche dont le travail est dans une PR ouverte garde son état `[~]` avec une annotation inline `` `⏳ PR #N` `` (pas un nouvel état — `[~]` signifie déjà « code-complete, en attente d'approbation » ; la PR est le véhicule de cette approbation).
- **Dégradation gracieuse** : pas de git / pas de remote / pas de branche canonique / bloc absent → no-op silencieux. La promesse zéro-dépendance tient toujours.
- **Ne contourne jamais les guards** : si un push est bloqué par un guard de sécurité ou l'auth, le commit reste dans le worktree et vous recevez la commande exacte à exécuter — il ne masque jamais l'échec ni ne bloque votre travail.

## Architecture

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-chargé, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← RÉFÉRENCE (historique complet)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Plans pour sous-tâches [complex]
<project-root>/.git/milestone-sync-wt/                     ← Worktree isolé R13 (mode équipe uniquement)
```

## Ce qui le distingue de la v1

| Aspect | v1 | v2 |
|--------|----|----|
| Coût de chargement | ~8 300 tok (Read fichier complet + templates) | ~100 tok (snapshot mémoire) |
| Coût de listage | ~8 750 tok (Read tous les fichiers) | ~400 tok (frontmatter seul, limit:8) |
| Sous-tâches complexes | Pas de gate — essais-erreurs | Plan requis avant exécution |
| Gestion de session | Même conversation (le contexte s'accumule) | `/milestone start` ouvre une session fraîche |
| Chargement des références | Charge toujours templates.md | Seulement sur `/milestone init` |
| Collaboration en équipe | Aucune — fichier local seulement | Milestone partagé git-synchronisé opt-in (R13) |

## Évaluation

- **`/skill-judge`** : 120/120 (Grade A+)
- **`/skill-guard`** : 92/100 (GREEN) — aucun script exécuté en fonctionnement normal, pas de réseau, pas de MCP. R13 (opt-in, désactivé par défaut) est le seul chemin qui effectue des opérations git.

## Sécurité

- Par défaut, lit/écrit uniquement les fichiers locaux `.milestones/*.md` et les snapshots mémoire. Pas de réseau, pas de scripts en fonctionnement normal.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash est utilisé pour `/milestone start` (auto-installe le script à la première utilisation) et, **uniquement quand le mode équipe est explicitement activé**, pour `milestone-sync.sh` — qui effectue des `git fetch`/`git push` limités à `<path>/` contre la branche canonique via un worktree isolé. Désactivé par défaut ; ne push jamais de code ; ne contourne jamais les guards de sécurité (push bloqué → signalé, pas masqué).
