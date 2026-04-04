# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de niveau expert pour Claude Code. Chaque skill notee **A+ (120/120)** avant publication.

## Installer

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | Description | Score |
|-------|------------|-------|
| **[skill-advisor](../skills/skill-advisor/)** | Analyse chaque instruction et recommande la bonne skill avant execution. Ne ratez plus jamais une skill installee. | 120/120 |

## skill-advisor

> **Vous installez 50 skills. Vous en utilisez 5. Les 45 autres prennent la poussiere.**

skill-advisor resout ce probleme. Il se place entre vous et Claude, analysant chaque instruction pour trouver la meilleure skill dans VOTRE collection — avant tout travail.

### Comment ca marche

```
Vous tapez une instruction
        |
        v
skill-advisor scanne vos skills installees
        |
        v
Correspondance? --> Recommande 1-5, classees par impact
Aucune?         --> Continue en silence (ou suggere une a installer)
```

### Deux modes

**Pre-action** — Avant que Claude commence, recommande les skills qui amelioreraient le resultat :

```
> "corrige ce bug de login"

Evaluation des skills:
1. /systematic-debugging — correspond a "bug, test failure"
2. /webapp-testing — verifier le fix apres

Je procede avec celles-ci ? Ou directement sans skill ?
```

**Post-action** — Apres le travail, suggere la prochaine etape logique :

```
> [code modifie]

Skills recommandees:
1. /webapp-testing — code modifie, tests necessaires
2. /verification-before-completion — avant de declarer termine
```

### Ce qui le rend different

- **Lit VOS skills** — Pas de liste codee en dur. Scanne le system-reminder dynamiquement.
- **Pense lateralement** — "rends-le plus beau" trouve des skills de design, animation ET audit d'accessibilite.
- **Sait quand se taire** — Taches simples ? Pas de recommandation. Se demande : "l'utilisateur me remercierait ou serait agace ?"
- **Recommande des pipelines** — Detecte les scenarios multi-etapes et suggere le combo complet.
- **Fallback communautaire** — Si rien ne correspond localement, suggere des skills installables.

### Premier lancement

A la premiere invocation (`/skill-advisor`), scanne votre ecosysteme et rapporte :

```
Ecosysteme detecte:
- 47 skills installees (global + projet)
- Categories: debugging, testing, frontend, docs, planning, ...
- Pret a recommander a chaque instruction.
```

## Standards de Qualite

Chaque skill est evaluee avec [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensions, 120 points max. **Minimum pour inclusion : B (96/120).**

## Contribuer

1. Fork ce repo
2. Ajoutez votre skill dans `skills/<nom>/SKILL.md`
3. Executez `/skill-judge` — doit obtenir B ou plus
4. Ouvrez une PR avec votre score

## Licence

[MIT](../LICENSE)
