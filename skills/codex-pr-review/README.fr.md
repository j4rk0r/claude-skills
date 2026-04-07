# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Ton reviewer dit "LGTM" — et trois semaines plus tard la prod casse a cause d'un hook qui ne tourne que sur update, pas sur insert.**

codex-pr-review est une skill de revue de pull requests Drupal 11 qui recupere le PR depuis GitHub et l'audite selon la **methodologie Codex** : 18 regles eprouvees en production avec le *pourquoi* derriere chacune. Trouve les bugs que ton linter rate — ceux qui n'apparaissent qu'a 3h du matin apres un deploy.

## Installer

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## Comment ca marche

```
Toi : "revision Codex PR #42 develop ← feature/alejandro"
        |
        v
Confirme le numero de PR et les branches (demande s'il manquent)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Charge MANDATORY les references (memes que codex-diff-develop)
        |
        v
Applique le framework Codex de 5 questions + decision tree
        |
        v
Revue UNIQUEMENT du diff du PR
        |
        v
Auto-detecte l'IDE → ecrit le rapport dans <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Auto-verification contre une checklist de 13 points avant livraison
```

## Les 18 regles Codex — chacune avec sa cicatrice

Chaque regle inclut le **pourquoi** :

1. **Completude `hook_entity_insert` vs `_update`** — la logique seulement dans `_update` rate les nouvelles entites
2. **Agregations (MAX/MIN/COUNT) sur tables vides retournent NULL, pas 0**
3. **Interpolation directe en SQL** — SQL injection plus apostrophes cassent les queries
4. **Recursion dans les hooks sans garde statique** — boucles infinies seulement detectees par cron
5. **Plusieurs ecritures sans transaction** — echecs partiels = etat incoherent
6. **APIs externes sans `connect_timeout`** — fournisseur lent bloque les workers de queue
7. **`accessCheck(FALSE)` injustifie** — bypass silencieux des permissions
8. **Invalidation de cache insuffisante** — classique "ca marche en local"
9. **Idempotence sur retry/double-clic** — commandes en double, emails en double
10. **Coherence des types** entre code, schema et BDD
11. **Pas de kill-switch** — incidents 3h du matin sans le temps de redeployer
12. **Form alters AJAX sans `#process`** — alter perdu au rebuild AJAX
13. **`\Drupal::service()` dans des classes neuves** — bloque unit et kernel tests
14. **Blocs/formatters custom sans `getCacheableMetadata()`** — casse BigPipe
15. **Schema de config obsolete** — `drush cim` echoue dans d'autres environnements
16. **Migrations sans `id_map` propre** — rollbacks corrompus
17. **Update hooks non idempotents** — re-execution apres echec partiel empire la BDD
18. **Overrides `settings.php` en collision avec config split** — perdus a chaque deploy

## NEVER list — 15 anti-patterns Drupal

Specifiques a la revue de PR :

- **NUNCA** marquer un point de style (typo, espace) comme "Alta" — dilue la severite
- **NUNCA** suggerer des refactos hors du PR sauf securite critique ou data loss
- **NUNCA** referencer ou nommer d'autres PRs dans le document — le reviewer perd le focus et melange les discussions (unique a la revue de PR, absent de diff-develop)
- **NUNCA** approuver `\Drupal::service()` dans des classes neuves
- **NUNCA** approuver `accessCheck(FALSE)` sans commentaire inline justificatif
- **NUNCA** approuver `|raw` dans Twig sans verifier que la source est controlee par le systeme
- **NUNCA** approuver `loadMultiple([])` sans garde de tableau vide
- **NUNCA** approuver Batch API sans callback `finished` gerant l'echec
- **NUNCA** marquer le rapport "OK" si un finding High n'est pas resolu

## Framework Codex de 5 questions

Avant de revoir n'importe quel bloc :

1. **Quel type de changement c'est ?** Hook, refacto, hotfix, migration, config
2. **Quel est le pire scenario en prod ?** Fixe le seuil de severite
3. **Que suppose le changement hors du diff ?** Schema, indexes, permissions
4. **Est-ce idempotent ?** Retry, double-clic, re-deploy
5. **Peut-on le desactiver ?** Kill-switch via config/setting/feature flag

Un exemple travaille guide pas a pas l'application a un mini-PR hypothetique.

## Structure du rapport

```markdown
Español confirmado.

# Revisión de código — PR #<N> (<base> ← <head>)

## Resumen ejecutivo
## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI
## Riesgos (tabla)
## Sugerencias accionables
## Checklist final
```

Chaque finding suit **Probleme (Severite)** → **Risque** → **Solution** avec du code adapte des 14 modeles dans `references/`.

## Auto-detection d'IDE

Lit `CLAUDE_CODE_ENTRYPOINT` d'abord. Fallback sur l'existence de dossiers seulement si l'env var n'est pas concluante.

| Detection | Dossier de sortie |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (aucun / CLI) | `docs/revisiones-prs/` |

## Checklist d'auto-verification

Avant livraison, parcourt 13 verifications : premiere ligne correcte, fichier dans le bon dossier, references chargees dans cette session, chaque finding avec Probleme/Risque/Solution, aucune Alta n'est juste un point de style, **aucun autre PR reference**, etc.

## Recovery — que faire en cas d'echec

| Symptome | Action |
|---|---|
| `references/*.md` manquant | Prevenir l'utilisateur, ne pas inventer de points Codex |
| `git fetch origin pull/<N>/head` echoue | Verifier le numero de PR, le repo, ou fallback GitLab `merge-requests/<N>/head` |
| Branche base manquante localement | `git fetch origin <base>:<base>` |
| `.cursor/` non creable | Demander a l'utilisateur de creer le dossier |
| PR > 200 fichiers | Demander confirmation avant de continuer |
| PR deja merge | Prevenir et confirmer la revue de l'historique |
| L'utilisateur ne donne pas le numero de PR | Demander, ne pas supposer |

## Evaluation

- **`/skill-judge`** : 120/120 (Grade A+)
- **`/skill-guard`** : 100/100 (VERT) — declare des `allowed-tools` minimaux, zero reseau, zero MCP

| Dimension | Score |
|-----------|-------|
| Knowledge Delta | 20/20 |
| Mindset + Procedures | 15/15 |
| Anti-Pattern Quality | 15/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 15/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## Skill jumelle

Si tu veux revoir le diff de ta *branche actuelle* contre `develop` (pas un PR distant), utilise [`codex-diff-develop`](../codex-diff-develop/) — meme methodologie Codex, memes references, source de diff differente.

## Licence

MIT
