# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Vous avez termine une feature en 3 conversations. La 4e repart de zero car le contexte ne survit pas.**

milestone est un tracker de developpement persistant qui stocke le contexte complet sous forme de fichiers markdown dans votre projet. Chaque jalon est une capsule autonome : objectif, sous-taches avec statut, decisions architecturales, references de code et un journal de ce qui a ete fait et pourquoi. Chargez-le dans n'importe quelle conversation et reprenez exactement la ou vous en etiez.

## Installer

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Commandes

| Commande | Description |
|----------|-------------|
| `/milestone` | Liste tous les jalons avec statut, progression et liens de chargement rapide |
| `/milestone <nom>` | Charge le contexte complet d'un jalon (correspondance floue) |
| `/milestone init <nom>` | Cree un nouveau jalon avec objectif et sous-taches |
| `/milestone add <nom> <contenu>` | Ajoute sous-tache, decision, note ou reference |
| `/milestone done <nom> <sous-tache>` | Marque une sous-tache comme terminee |
| `/milestone update <nom>` | Mise a jour groupee du contexte apres une session de travail |

## Caracteristiques cles

- **Persistant entre conversations** — les fichiers vivent dans `.milestones/` et survivent a toute session
- **Contexte autonome** — chaque fichier contient tout le necessaire pour reprendre le travail
- **Decouverte des planificateurs** — detecte automatiquement les skills de planification et propose d'unifier leurs resultats
- **Auto-statut** — le statut se recalcule depuis les cases a cocher
- **Correspondance floue** — tapez "dash" pour charger "dashboard-propietario"
- **Journal append-only** — historique chronologique inverse de ce qui s'est passe et pourquoi
- **Skill globale, donnees locales** — installee une fois, cree des donnees specifiques par projet

## Securite

- Audite avec Skill-Guard : **92/100 GREEN**
- Sans scripts, sans appels reseau, sans acces MCP
- `allowed-tools: Read Write Edit Glob Grep`
