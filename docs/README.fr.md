# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de niveau expert pour Claude Code. Chaque skill notee **A+ (120/120)** avant publication.

## Installer tout

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

Ou installer individuellement :

```bash
npx skills add j4rk0r/claude-skills@skill-guard -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-advisor -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-learner -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review -y -g
```

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module -y -g
```

```bash
npx skills add j4rk0r/claude-skills@milestone -y -g
```

```bash
npx skills add j4rk0r/claude-skills@usage-tracker -y -g
```

## Skills

| Skill | Description |
|-------|------------|
| **[skill-guard](../skills/skill-guard/)** | Detecte les skills malveillantes avant qu'elles ne touchent vos fichiers, tokens ou cles. Analyse en 9 couches + registre d'audits verifie. |
| **[skill-advisor](../skills/skill-advisor/)** | Construit des plans d'execution combinant vos skills installees et les gaps manquants — puis propose de les installer. Ne commencez jamais sous-equipe. |
| **[skill-learner](../skills/skill-learner/)** | Capture les erreurs et persiste les corrections pour que la meme faute ne se reproduise plus. Fonctionne pour les skills ET le comportement general de Claude. Genere optionnellement des propositions d'amelioration pour les auteurs. |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Revue de code Drupal 11 de la branche actuelle contre `develop` selon la methodologie Codex — 18 regles eprouvees en production avec le *pourquoi* derriere chacune. Genere un rapport `.md` structure. |
| **[codex-pr-review](../skills/codex-pr-review/)** | Revue de pull requests Drupal 11 avec la methodologie Codex — memes 18 regles que `codex-diff-develop` mais recupere le PR via `git fetch origin pull/<N>/head` pour auditer n'importe quel PR GitHub. |
| **[lint-drupal-module](../skills/lint-drupal-module/)** | Lint review parallelisee de modules Drupal 11 combinant 4 sources — PHPStan level 5, PHPCS Drupal/DrupalPractice, agent `drupal-qa` (standards) et agent `drupal-security` (OWASP). Modes complet ou diff. Consolide tout dans un seul rapport actionnable avec actions P0/P1/P2. |
| **[milestone](skills/milestone/)** | Tracker de developpement persistant v2 avec cache a deux niveaux (snapshots memoire + fichiers autoritatifs). Classe les sous-taches en `[simple]`/`[complex]`, exige un plan avant le travail complexe. Efficace en tokens : charges 99% moins couteuses, regle 3-Edit→Write. |
| **[usage-tracker](../skills/usage-tracker/)** | Hook PostToolUse qui enregistre chaque appel d'outil dans `~/.claude/usage.jsonl`. Voyez exactement combien coûte chaque requête utilisateur — par projet, session, jour et outil. |

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

### Registre communautaire d'audits

Chaque audit est sauvegarde dans [`skills/skill-guard/audits/`](../skills/skill-guard/audits/), organise par auteur verifie (anthropic, obra, softaworks, etc.). Avant d'analyser, skill-guard verifie si quelqu'un a deja audite cette version. Resultats instantanes si le SHA correspond.

**Modele de confiance :** Seul le systeme genere et publie les resultats d'audit. Les membres de la communaute demandent des audits via PR dans `audits/requests/` — le mainteneur execute skill-guard et publie le resultat. Cela empeche les audits falsifies d'entrer dans le registre.

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

## skill-learner

> **Claude s'excuse, promet de faire mieux — puis refait exactement la meme erreur a la session suivante.**

skill-learner brise ce cycle. Quand une skill ou Claude se trompe, il capture ce qui s'est mal passe, pourquoi, et quoi faire a la place — sous forme de fichier de correction persistant qui survit entre les sessions.

### Comment ca marche

```
Quelque chose s'est mal passe
        |
        v
skill-learner detecte quel skill (ou comportement general) a echoue
        |
        v
Pose des questions ciblees jusqu'a comprendre l'erreur
        |
        v
Sauvegarde une correction structuree dans ~/.claude/skill-corrections/
        |
        v
Prochaine execution de ce skill → la correction est disponible
        |
        v
Optionnellement: genere une proposition d'amelioration pour l'auteur
```

### Caracteristiques cles

- **Auto-detecte le skill defaillant** a partir du contexte de conversation
- **Deduplique** — verifie INDEX.md avant de creer, fusionne si le meme probleme existe deja
- **9 regles NEVER** — empeche les corrections vagues, doublons et bypass de securite
- **Test de lecture a froid** — verifie que chaque correction est claire pour un agent different
- **Propositions d'amelioration** — genere des propositions avec diffs pour l'auteur de la skill
- **Bilingue** — ecrit les corrections dans la langue de l'utilisateur

### Installer

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **Ton linter dit "ca a l'air bon" — et trois semaines plus tard la prod casse a cause d'un hook qui ne tourne que sur update, pas sur insert.**

codex-diff-develop est une skill de revue de code Drupal 11 qui audite le diff de ta branche actuelle contre `develop` selon la **methodologie Codex** : 18 regles eprouvees en production avec le *pourquoi* derriere chacune. Trouve les bugs que ton linter rate — ceux qui n'apparaissent qu'a 3h du matin apres un deploy.

### Comment ca marche

```
Toi : "revision diff develop"
        |
        v
Detecte le contexte : branche, sous-dossier drupal/, types de fichiers
        |
        v
Charge MANDATORY les references (18 regles Codex + 14 modeles)
        |
        v
Applique le framework Codex de 5 questions
        |
        v
Decision tree choisit les regles Codex selon le type de fichier
        |
        v
Revue UNIQUEMENT du diff, pas de suggestions hors perimetre
        |
        v
Auto-detecte l'IDE → ecrit le rapport dans .vscode/.cursor/.antigravity
        |
        v
Auto-verification contre une checklist de 12 points avant livraison
```

### Les 18 regles Codex — chacune avec sa cicatrice

Chaque regle inclut le **pourquoi** (l'incident de production qui l'a enseignee) :

1. **Completude `hook_entity_insert` vs `_update`** — la logique seulement dans `_update` rate les entites toutes neuves
2. **Agregations (MAX/MIN/COUNT) sur tables vides retournent NULL, pas 0**
6. **APIs externes sans `connect_timeout`** — un fournisseur lent bloque les workers de queue et epuise PHP-FPM
7. **`accessCheck(FALSE)` injustifie** — bypass silencieux des permissions
9. **Idempotence sur retry/double-clic** — commandes en double, emails en double
11. **Pas de kill-switch** — incidents 3h du matin sans le temps de redeployer
14. **Blocs/formatters custom sans `getCacheableMetadata()`** — casse BigPipe silencieusement

Liste complete avec le *pourquoi* dans [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md).

### NEVER list — 15 anti-patterns Drupal

- **NUNCA** marquer un point de style comme "Alta" — dilue la severite
- **NUNCA** suggerer des refactos hors du diff sauf securite critique
- **NUNCA** approuver `loadMultiple([])` — retourne TOUTES les entites (fuite memoire classique)
- **NUNCA** approuver Batch API sans callback `finished` gerant l'echec

### Framework Codex de 5 questions

1. **Quel type de changement c'est ?**
2. **Quel est le pire scenario en prod ?**
3. **Que suppose le changement hors du diff ?**
4. **Est-ce idempotent ?**
5. **Peut-on le desactiver ?**

### Output

Rapport `.md` structure : resume executif, hallazgos par categorie (Securite, Codex, Standards/DI, Performance, A11y/i18n, Tests/CI), tableau de risques, liste accionnable, section "Le positif", checklist final. Chaque hallazgo suit **Probleme (Severite)** → **Risque** → **Solution**.

### Auto-detection IDE

Lit `CLAUDE_CODE_ENTRYPOINT` d'abord. Fallback sur l'existence de dossiers seulement si l'env var n'est pas concluante.

### Evaluation

- **`/skill-judge`** : 120/120 (Grade A+)
- **`/skill-guard`** : 100/100 (VERT) — declare des `allowed-tools` minimaux, zero reseau, zero MCP

### Installer

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **Ton reviewer dit "LGTM" — et trois semaines plus tard la prod casse a cause d'un hook qui ne tourne que sur update.**

codex-pr-review est la skill jumelle de `codex-diff-develop` pour les **pull requests distantes**. Meme methodologie Codex, memes 18 regles, memes modeles — mais recupere le PR via `git fetch origin pull/<N>/head` pour auditer n'importe quel PR GitHub par numero.

### Differences avec codex-diff-develop

| Aspect | codex-diff-develop | codex-pr-review |
|---|---|---|
| Source du diff | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| Dossier de sortie | `Revisiones diff/` | `Revisiones PRs/` |
| Nom de fichier | `lint-review-diff-develop-<branche>.md` | `lint-review-pr<N>.md` |
| Triggers | "diff develop", "codex diff" | "revision PR", "revisar PR #N", "codex PR" |
| NEVER extra | — | "**NUNCA** referencer d'autres PRs dans le document" |
| Edge cases extra | — | Fallback GitLab, PR deja merge, numero de PR manquant |

### Quand utiliser laquelle

- **`codex-diff-develop`** : tu travailles localement sur une branche et tu veux revoir tes propres changements avant de pousser
- **`codex-pr-review`** : tu veux revoir le PR de quelqu'un d'autre (ou le tien apres l'avoir pousse) sans checkout local

### Evaluation

- **`/skill-judge`** : 120/120 (Grade A+)
- **`/skill-guard`** : 100/100 (VERT)

### Installer

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## lint-drupal-module

> **Ta revue de code manuelle trouve 29 problemes. Tu lances PHPStan et PHPCS a la main. Tu demandes a un reviewer de regarder les standards et la securite. 45 minutes plus tard tu as enfin une vue consolidee — et tu as manque 140 violations dans les fichiers JS du module parce que personne n'a lance PHPCS sur le JavaScript.**

lint-drupal-module execute **quatre sources en parallele** — PHPStan level 5 (avec `phpstan-drupal`), PHPCS Drupal/DrupalPractice, un agent `drupal-qa` pour les standards et un agent `drupal-security` pour les vecteurs OWASP — et consolide les resultats dans un seul rapport actionnable. Ce qui etait 12 etapes manuelles et 30 minutes devient une seule invocation qui termine dans le temps pris par la source la plus lente (2-5 min complet, 30s-1min diff).

### Comment ca marche

```
Toi : "lint review du module chat_soporte_tecnico_ia"
        |
        v
Identifie le module (par nom, chemin ou Glob)
        |
        v
Choisit le mode : complet (par defaut) | diff (vs develop)
        |
        v
Detecte DDEV / composer local, installe PHPStan si manquant (en demandant)
        |
        v
Charge references/prompts-agentes.md (obligatoire avant d'invoquer les agents)
        |
        v
Lance les 4 sources en parallele, dans le meme message :
  • Agent drupal-qa        (standards)
  • Agent drupal-security  (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Consolide les 4 sorties dans un rapport markdown
        |
        v
Auto-detecte l'IDE → <ide>/Lint reviews/lint-review-<module>-<mode>-<branche>.md
        |
        v
Resume les top bloqueurs et demande :
  "arregla todo" / "solo critico" / "auto-fix PHPCS" / "dejalo asi"
```

### Deux modes

| Mode | Quand l'utiliser | Vitesse |
|---|---|---|
| **Complet** (par defaut) | Avant une release, modules nouveaux, audits periodiques | ~2-5 min |
| **Diff** | Reviews intermediaires, validation pre-push, seulement les changements vs `develop` | ~30s-1min |

### Ce qu'elle detecte qu'une review manuelle rate

Validee contre un module Drupal 11 reel (32 fichiers). Une review manuelle uniquement avec agents a signale 29 problemes. Lancer le pipeline parallelise complet a fait emerger **65 problemes** — incluant 166 violations PHPCS sur les JavaScript du module (la plupart auto-corrigibles avec `phpcbf`) que le reviewer manuel n'a jamais verifiees parce que le JS etait hors de son perimetre.

C'est le principe : une lint review ne vaut que ce que vaut sa couche la plus faible. Combiner analyse statique, application de style et agents experts en parallele capture des choses qu'aucune source seule ne voit.

### Structure du rapport (fixe)

1. **Resume executif** — resultats par source, top 5 bloqueurs, verdict categorique
2. **PHPStan level 5** — erreurs groupees par fichier
3. **PHPCS Drupal/DrupalPractice** — violations groupees par fichier
4. **Standards (drupal-qa)** — resultats par severite avec suggestions de correction
5. **Securite (drupal-security)** — vulnerabilites classees 🔴 CRITIQUE / 🟠 ELEVE / 🟡 MOYEN / 🟢 BAS / ℹ️ INFO
6. **Actions priorisees** — P0 bloqueurs, P1 recommandes, P2 ameliorations
7. **Couverture des bonnes pratiques** — checklist strict_types, hooks OOP, DI, CSRF, cache metadata, etc.
8. **Commandes de verification** — commandes exactes pour relancer en local

### Regles NEVER principales

1. **NE modifie JAMAIS les fichiers pendant la skill.** Rapports uniquement. Les corrections sont une phase separee avec confirmation explicite.
2. **N'execute JAMAIS les 4 sources dans des messages separes.** La parallelisation est la valeur principale ; en serie c'est 4× plus lent.
3. **Ne liste JAMAIS `Unsafe usage of new static()` dans les Controllers comme bloqueur** — faux positif connu de phpstan-drupal.
4. **Ne supprime JAMAIS les alias FQCN dans `services.yml` sans verifier l'utilisation par type-hint du Hook OOP** — facon connue de casser `drush cr`.
5. **N'execute JAMAIS `phpcbf` sur des fichiers JavaScript** — le standard Drupal convertit `null`/`true`/`false` en `NULL`/`TRUE`/`FALSE` en JS, cassant le code en runtime. Utilise toujours `--extensions=php,module,inc,install,profile,theme` et `--ignore='*/js/*'`.

### Relation avec les skills soeurs

- **`codex-diff-develop`** → revue la logique metier sur le diff (complete cette skill)
- **`codex-pr-review`** → revue architecturale d'un PR complet (un niveau au-dessus)
- **Workflow ideal pre-merge :** `lint-drupal-module` → corrections mecaniques → `codex-diff-develop` → corrections de logique → `codex-pr-review` → merge

### Installer

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

---

## milestone

> **Vous avez termine une feature en 3 conversations. La 4e repart de zero parce que le contexte ne survit pas.**

milestone stocke tout le necessaire pour reprendre le travail de developpement dans n'importe quelle conversation future — objectif, sous-taches avec statut, decisions architecturales, references de code et un journal chronologique inverse de ce qui a ete fait et pourquoi. Chargez un jalon par nom et commencez a travailler immediatement.

### Comment ca marche

- `/milestone` — liste tous les jalons avec statut et progres
- `/milestone <nom>` — charge le contexte complet (fuzzy match)
- `/milestone init <nom>` — cree un nouveau jalon avec sous-taches basees sur le codebase
- `/milestone add/done/update` — gere les sous-taches, decisions et contexte

### Decisions de conception cles

- **Journal de contexte append-only** — ne jamais effacer l'historique, seulement ajouter des corrections
- **Decouverte des planificateurs** — detecte automatiquement les skills de planification installees
- **Skill global, donnees locales** — cree `.milestones/` par projet
- **8 regles NEVER** — pas de milestones triviaux, pas de doublons, max 10 actifs

### Evaluation

- **`/skill-guard`**: 92/100 (GREEN)

### Installer

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

---

## usage-tracker

> **Vous utilisez Claude Max. Pas de facturation par token. Mais vous n'avez aucune idée quel projet, conversation ou requête brûle vos limites de contexte.**

usage-tracker corrige cela. Un hook PostToolUse capture chaque appel d'outil avec ses tokens, son projet et la requête utilisateur qui l'a déclenchée — transformant un historique d'utilisation opaque en un bilan actionnable par requête, projet, session, outil et jour.

### Comment ca marche

```
Utilisateur : "revue du module auth"
  └─ Read auth.module           → 1 200 tok   ┐
  └─ Grep hook                  →    80 tok   │ même "requête"
  └─ Read AuthService.php       → 2 400 tok   │ → total : 4 980 tok
  └─ Bash lint auth/            → 1 300 tok   ┘
```

Chaque entrée stocke : timestamp, session, projet, outil, modèle, étiquette, texte de la requête, tokens. Le script de rapport agrège en ventilations sur lesquelles vous pouvez agir.

### La partie non evidente

Le hook capture les appels d'outils isolément — mais Claude envoie l'intégralité de l'historique de conversation à chaque requête. Cela crée une **sous-estimation non linéaire** :

| Message | Sous-estimation réelle |
|---------|----------------------|
| 5       | ~20%                 |
| 20      | ~60%                 |
| 40+     | ~80–90%              |

Utilisez-le comme **indice relatif** pour comparer projets, sessions et types de requêtes — pas comme coût absolu.

Angles morts principaux :
- **Appels d'agents** — les conversations de sous-agents sont complètement invisibles (500 tokens dans le log = potentiellement 20 000+ réels)
- **Longues conversations** — le contexte s'accumule quadratiquement ; démarrez de nouvelles conversations pour les tâches indépendantes
- **Skills actives** — chaque SKILL.md chargée ajoute un overhead fixe par requête

### Commandes

```bash
/usage-tracker install        # Configurer le hook + scripts
/usage-tracker report hoy     # Rapport d'aujourd'hui
/usage-tracker report semana  # Les 7 derniers jours
/usage-tracker top-requests   # Les 15 requêtes les plus coûteuses
/usage-tracker status         # Vérifier que le hook est actif
```

### Installer

```bash
npx skills add j4rk0r/claude-skills@usage-tracker --yes --global
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
