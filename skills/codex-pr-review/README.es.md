# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Tu reviewer dice "LGTM" — y tres semanas despues produccion peta por un hook que solo se ejecuta en update, no en insert.**

codex-pr-review es una skill de revision de pull requests Drupal 11 que descarga el PR desde GitHub y lo audita usando la **metodologia Codex**: 18 reglas probadas en produccion con el *por que* detras de cada una. Encuentra los bugs que tu linter no ve — los que solo aparecen a las 3am despues de un deploy.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## Como funciona

```
Tu: "revision Codex PR #42 develop ← feature/alejandro"
        |
        v
Confirma numero de PR y ramas (pregunta si faltan)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Carga MANDATORY las references (18 reglas Codex + 14 plantillas)
        |
        v
Aplica el framework Codex de 5 preguntas
        |
        v
Decision tree elige reglas Codex segun tipo de archivo
        |
        v
Revisa SOLO el diff del PR, sin sugerencias fuera de alcance
        |
        v
Auto-detecta IDE → escribe informe en <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Auto-verificacion contra checklist de 13 items antes de entregar
```

## La metodologia Codex — 18 reglas con cicatrices

Cada regla incluye el **por que** (el incidente de produccion que la enseno):

1. **Completitud `hook_entity_insert` vs `_update`** — logica solo en `_update` se salta entidades nuevas
2. **Agregadas (MAX/MIN/COUNT) en tablas vacias devuelven NULL, no 0**
3. **Interpolacion directa en SQL** — SQL injection mas apostrofos rompen queries
4. **Recursion en hooks sin guarda estatica** — loops infinitos solo detectados por cron
5. **Multiples escrituras sin transaccion** — fallos parciales = estado inconsistente
6. **APIs externas sin `connect_timeout`** — proveedor lento bloquea workers de cola
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permisos
8. **Invalidacion de cache insuficiente** — clasico "en local funciona" tras deploy
9. **Idempotencia en operaciones retry/doble-click** — pedidos duplicados, emails duplicados
10. **Coherencia de tipos** entre codigo, schema y BD
11. **Sin kill-switch** — incidentes a las 3am sin tiempo de hacer rollback
12. **Form alters AJAX sin `#process`** — alter perdido en AJAX rebuild
13. **`\Drupal::service()` en clases nuevas** — bloquea unit y kernel tests
14. **Bloques/formatters custom sin `getCacheableMetadata()`** — rompe BigPipe
15. **Schema de config desactualizado** — `drush cim` falla en otros entornos
16. **Migraciones sin `id_map` limpio** — rollbacks corruptos
17. **Update hooks no idempotentes** — re-ejecucion tras fallo parcial empeora la BD
18. **Overrides de `settings.php` colisionando con config split** — perdidos en cada deploy

## NEVER list — 15 anti-patrones especificos de Drupal

Especificos de PR review:

- **NUNCA** marcar un hallazgo de estilo (typo, espacio) como "Alta" — diluye la severidad
- **NUNCA** sugerir refactors fuera del PR salvo seguridad critica o data loss
- **NUNCA** referenciar ni nombrar otros PRs en el documento — el revisor pierde foco y mezcla discusiones (unico de PR review, no presente en diff-develop)
- **NUNCA** aprobar `\Drupal::service()` en clases nuevas
- **NUNCA** dar por bueno `accessCheck(FALSE)` sin comentario inline justificativo
- **NUNCA** aprobar `|raw` en Twig sin verificar que el origen es controlado por el sistema
- **NUNCA** aprobar `loadMultiple([])` sin guarda de array vacio
- **NUNCA** aprobar Batch API sin `finished` callback que maneje fallo
- **NUNCA** marcar el informe como "OK" si hay cualquier hallazgo Alta sin resolver

## Framework Codex de 5 preguntas

Antes de revisar cualquier bloque:

1. **Que tipo de cambio es?** Hook, refactor, hotfix, migracion, config
2. **Cual es el peor caso en produccion?** Fija el suelo de severidad
3. **Que asume el cambio fuera del diff?** Schema, indices, permisos
4. **Es idempotente?** Retry, doble-click, re-deploy
5. **Se puede desactivar?** Kill-switch via config/setting/feature flag

Un ejemplo trabajado guia paso a paso la aplicacion a un mini-PR hipotetico.

## Estructura del informe

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

Cada hallazgo sigue **Problema (Severidad)** → **Riesgo** → **Solucion** con codigo adaptado de las 14 plantillas en `references/`.

## Auto-deteccion de IDE

Lee `CLAUDE_CODE_ENTRYPOINT` primero (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Solo cae a deteccion por carpeta si el env var no es concluyente.

| Deteccion | Carpeta de salida |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (ninguno / CLI) | `docs/revisiones-prs/` |

## Checklist de auto-verificacion

Antes de entregar, recorre 13 checks: primera linea correcta, archivo en la carpeta correcta, references cargadas en esta sesion, cada hallazgo con Problema/Riesgo/Solucion, ninguna Alta es solo de estilo, **sin referencias a otros PRs**, sin sugerencias fuera de alcance, etc.

## Recovery — que hacer cuando algo falla

| Sintoma | Accion |
|---|---|
| `references/*.md` no existe | Avisar al usuario, no inventar puntos Codex |
| `git fetch origin pull/<N>/head` falla | Verificar numero de PR, repo, o fallback GitLab `merge-requests/<N>/head` |
| Rama base no existe localmente | `git fetch origin <base>:<base>` |
| `.cursor/` no se puede crear | Pedir al usuario que cree la carpeta |
| PR > 200 archivos | Pedir confirmacion antes de continuar |
| PR ya mergeado | Avisar y confirmar revision del historico |
| El usuario no proporciona numero de PR | Preguntar, no asumir |

## Evaluacion

- **`/skill-judge`**: 120/120 (Grado A+) — puntuacion perfecta en las 8 dimensiones
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, cero red, cero MCP

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

## Skill hermana

Si quieres revisar el diff de tu *rama actual* contra `develop` (no un PR remoto), usa [`codex-diff-develop`](../codex-diff-develop/) — misma metodologia Codex, mismas references, distinto origen del diff.

## Licencia

MIT
