# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Ton linter dit "ca a l'air bon" — et trois semaines plus tard la prod casse a cause d'un hook qui ne tourne que sur update, pas sur insert.**

codex-diff-develop est une skill de revue de code Drupal 11 qui audite le diff de ta branche actuelle contre `develop` selon la **methodologie Codex** : 18 regles eprouvees en production avec le *pourquoi* derriere chacune. Trouve les bugs que ton linter rate — ceux qui n'apparaissent qu'a 3h du matin apres un deploy.

## Installer

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## Comment ca marche

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

## Les 18 regles Codex — chacune avec sa cicatrice

Chaque regle inclut le **pourquoi** (l'incident de production qui l'a enseignee) :

1. **Completude `hook_entity_insert` vs `_update`** — la logique seulement dans `_update` rate les entites toutes neuves
2. **Agregations (MAX/MIN/COUNT) sur tables vides retournent NULL, pas 0**
3. **Interpolation directe en SQL** — SQL injection plus apostrophes dans les vrais noms cassent la query
4. **Recursion dans les hooks sans garde statique** — boucles infinies seulement detectees par cron
5. **Plusieurs ecritures sans transaction** — echecs partiels = etat incoherent
6. **APIs externes sans `connect_timeout`** — un fournisseur lent bloque les workers de queue et epuise PHP-FPM
7. **`accessCheck(FALSE)` injustifie** — bypass silencieux des permissions
8. **Invalidation de cache insuffisante** — classique "ca marche en local" apres deploy
9. **Idempotence sur retry/double-clic** — commandes en double, emails en double
10. **Coherence des types** entre code, schema et BDD
11. **Pas de kill-switch** — incidents 3h du matin sans le temps de redeployer
12. **Form alters AJAX sans `#process`** — l'alter est perdu au rebuild AJAX
13. **`\Drupal::service()` dans des classes neuves** — bloque unit tests et kernel tests
14. **Blocs/formatters custom sans `getCacheableMetadata()`** — casse BigPipe silencieusement
15. **Schema de config obsolete** — `drush cim` echoue dans d'autres environnements
16. **Migrations sans `id_map` propre** — rollbacks corrompus detectes des mois plus tard
17. **Update hooks non idempotents** — re-execution apres echec partiel empire la BDD
18. **Overrides `settings.php` en collision avec config split** — silencieusement perdus a chaque deploy

## NEVER list — 15 anti-patterns Drupal

- **NUNCA** marquer un point de style comme "Alta" — dilue la severite
- **NUNCA** suggerer des refactos hors du diff sauf securite critique ou data loss
- **NUNCA** approuver `\Drupal::service()` dans des classes neuves avec l'argument "c'etait deja la"
- **NUNCA** approuver `accessCheck(FALSE)` sans commentaire inline justificatif
- **NUNCA** approuver `|raw` dans Twig sans verifier que la source est 100% controlee par le systeme
- **NUNCA** approuver `loadMultiple([])` — retourne TOUTES les entites (fuite memoire classique)
- **NUNCA** approuver Batch API sans callback `finished` gerant l'echec
- **NUNCA** approuver `EntityFieldManagerInterface::getFieldStorageDefinitions()` sans verifier que le field existe
- **NUNCA** marquer le rapport "OK" si un finding High n'est pas resolu

## Framework Codex de 5 questions

Avant de revoir n'importe quel bloc :

1. **Quel type de changement c'est ?** Hook, refacto, hotfix, migration, config
2. **Quel est le pire scenario en prod ?** Fixe le seuil de severite
3. **Que suppose le changement hors du diff ?** Schema, indexes, permissions
4. **Est-ce idempotent ?** Retry, double-clic, re-deploy
5. **Peut-on le desactiver ?** Kill-switch via config/setting/feature flag

Un exemple travaille guide pas a pas l'application a un mini-diff hypothetique.

## Structure du rapport

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branche>)

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
## Lo positivo
## Checklist final
```

Chaque finding suit **Probleme (Severite)** → **Risque** → **Solution** avec du code adapte des 14 modeles dans `references/`.

## Auto-detection d'IDE

Lit `CLAUDE_CODE_ENTRYPOINT` d'abord (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Fallback sur l'existence de dossiers seulement si l'env var n'est pas concluante.

| Detection | Dossier de sortie |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (aucun / CLI) | `docs/revisiones-diff/` |

## Checklist d'auto-verification

Avant livraison, la skill parcourt 12 verifications : premiere ligne correcte, fichier dans le bon dossier, references chargees dans cette session, chaque finding avec Probleme/Risque/Solution, aucune Alta n'est juste un point de style, pas de suggestions hors perimetre, etc.

## Recovery — que faire en cas d'echec

| Symptome | Action |
|---|---|
| `references/*.md` manquant | Prevenir l'utilisateur, ne pas inventer de points Codex |
| `git fetch` echoue (reseau) | Continuer avec `develop` local + note dans le rapport |
| `.cursor/` non creable | Demander a l'utilisateur de creer le dossier |
| Diff > 200 fichiers | Demander confirmation avant de continuer |
| L'utilisateur est sur `develop` | Avorter avec message clair |

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

Si tu veux revoir un PR distant au lieu de ta branche actuelle, utilise [`codex-pr-review`](../codex-pr-review/) — meme methodologie Codex, memes references, recupere le PR via `git fetch origin pull/<N>/head`.

## Licence

MIT
