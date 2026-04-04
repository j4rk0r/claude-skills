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
| **[skill-guard](../skills/skill-guard/)** | Auditeur de securite — detection de menaces en 9 couches pour les skills avant installation. Registre communautaire d'audits. | 120/120 |

## skill-guard

> **Vous installez une skill. Elle lit votre `~/.ssh`, prend votre `$GITHUB_TOKEN` et l'envoie a un serveur distant. Vous ne remarquez rien.**

skill-guard empeche cela. Il audite les skills avant installation en utilisant 9 couches d'analyse — des patterns statiques a l'analyse semantique LLM qui detecte l'injection de prompts deguisee en instructions normales.

### Comment ca marche

```
Vous voulez installer une skill
        |
        v
skill-guard consulte le registre communautaire d'audits
        |
        v
Deja auditee (meme SHA) ?  --> Affiche le rapport precedent
Non auditee ?               --> "Analyse de securite avant installation ?"
        |
        v
Analyse 9 couches: permissions, patterns, scripts,
flux de donnees, abus MCP, supply chain, reputation...
        |
        v
Score 0-100 → VERT / JAUNE / ROUGE
        |
        v
VERT: auto-installe | JAUNE: vous decidez | ROUGE: avertissement fort
```

### Les 9 couches

1. **Frontmatter et permissions** (20%) — `allowed-tools` manquant ? Bash sans restrictions ?
2. **Patterns statiques** (15%) — URLs, IPs, chemins sensibles, commandes dangereuses
3. **Analyse semantique LLM** (30%) — Injection de prompts, trojans, ingenierie sociale
4. **Scripts bundles** (15%) — Lit CHAQUE script. Imports dangereux, obfuscation
5. **Flux de donnees** (10%) — Mappe source → destination. Donnees sensibles vers URLs externes = menace
6. **MCP et outils** — Usage MCP non declare, exfiltration via Slack/GitHub/Monday
7. **Supply chain** (2%) — Typosquatting, versions non fixees, faux repos
8. **Reputation** (3%) — Profil de l'auteur, age du repo, forks trojans
9. **Anti-evasion** (5%) — Astuces unicode, homoglyphes, auto-modification

### Deux modes d'analyse

- **Audit complet** — 9 couches, rapport complet, persistance dans le registre
- **Scan rapide** — Couches 1+2+3 uniquement. Auto-escalade si trouvaille HIGH/CRITICAL

### Installer

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

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
Correspondance ? --> Recommande 1-5, classees par impact
Aucune ?         --> Continue en silence (ou suggere une a installer)
```

### Deux modes

**Pre-action** — Avant que Claude commence, recommande les skills qui amelioreraient le resultat.

**Post-action** — Apres le travail, suggere la prochaine etape logique.

### Ce qui le rend different

- **Lit VOS skills** — Pas de liste codee en dur. Scanne le system-reminder dynamiquement.
- **Pense lateralement** — "rends-le plus beau" trouve design, animation ET audit d'accessibilite.
- **Sait quand se taire** — Taches simples ? Pas de recommandation.
- **Recommande des pipelines** — Detecte les scenarios multi-etapes et suggere le combo complet.
- **Fallback communautaire** — Si rien ne correspond, suggere des skills installables.

### Installer

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## Standards de Qualite

Chaque skill est evaluee avec [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensions, 120 points max. **Minimum pour inclusion : B (96/120).**

## Contribuer

1. Fork ce repo
2. Ajoutez votre skill dans `skills/<nom>/SKILL.md`
3. Executez `/skill-judge` — doit obtenir B ou plus
4. Ouvrez une PR avec votre score

## Licence

[MIT](../LICENSE)
