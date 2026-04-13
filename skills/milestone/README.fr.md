# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Vous avez termine une feature en 3 conversations. La 4e repart de zero car le contexte ne survit pas.**

milestone v2 est un tracker de developpement persistant avec **cache a deux niveaux** : snapshots compacts en memoire (~100 tokens, charges automatiquement) pour un etat instantane, et fichiers autoritatifs pour l'historique complet. Il classifie les sous-taches en `[simple]` ou `[complexe]`, exigeant un plan avant d'executer les taches complexes — evitant le cycle couteux de 6+ modifications iteratives sur le meme fichier.

## Installer

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Commandes

| Phase | Commande | Description |
|-------|----------|-------------|
| Decouverte | `/milestone` | Lister tous les milestones avec statut et progression |
| Decouverte | `/milestone <nom>` | Charger le contexte (correspondance floue) |
| Planification | `/milestone init <nom>` | Creer un nouveau avec propositions de sous-taches |
| Execution | `/milestone start <nom>` | Ouvrir un terminal neuf avec contexte compact |
| Execution | `/milestone done <nom> <tache>` | Marquer une sous-tache comme terminee |
| Revision | `/milestone update <nom>` | Mise a jour globale apres session de travail |

## Caracteristiques cles

- **Cache deux niveaux** — snapshot memoire (~100 tok) pour les lectures, fichier autoritatif pour l'historique. 99% moins cher.
- **Classification de complexite** — `[simple]` vs `[complexe]`. Les complexes sont **bloquees** jusqu'a l'existence d'un plan.
- **Regles d'efficacite tokens** — 3+ modifications meme fichier → un seul Write (10x moins cher).
- **Nouvelle session** — `/milestone start` ouvre `claude` dans un nouveau terminal avec contexte compact.
- **12 regles NEVER** — prevention du split-brain, snapshots obsoletes, anti-patterns d'edition.

## Evaluation

- **`/skill-judge`** : 120/120 (Grade A+)
- **`/skill-guard`** : 92/100 (GREEN)
