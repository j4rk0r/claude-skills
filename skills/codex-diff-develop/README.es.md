# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Tu linter dice "todo bien" — y tres semanas despues produccion peta por un hook que solo se ejecuta en update, no en insert.**

codex-diff-develop es una skill de revision de codigo Drupal 11 que audita el diff de tu rama actual contra `develop` usando la **metodologia Codex**: 18 reglas probadas en produccion con el *por que* detras de cada una. Encuentra los bugs que tu linter no ve — los que solo aparecen a las 3am despues de un deploy.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## Como funciona

```
Tu: "revision diff develop"
        |
        v
Detecta contexto: rama, subdir drupal/, tipos de archivo en el diff
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
Revisa SOLO el diff, sin sugerencias fuera de alcance
        |
        v
Auto-detecta IDE → escribe informe en .vscode/.cursor/.antigravity
        |
        v
Auto-verificacion contra checklist de 12 items antes de entregar
```

## La metodologia Codex — 18 reglas con cicatrices

Cada regla incluye el **por que** (el incidente de produccion que la enseno):

1. **Completitud `hook_entity_insert` vs `_update`** — logica solo en `_update` se salta entidades nuevas hasta que alguien las edita
2. **Agregadas (MAX/MIN/COUNT) en tablas vacias devuelven NULL, no 0** — `$max + 1` se vuelve incoherente en el primer registro
3. **Interpolacion directa en SQL** — SQL injection mas apostrofos en nombres reales rompen la query antes de produccion
4. **Recursion en hooks sin guarda estatica** — loops infinitos solo detectados por cron, nunca en pruebas manuales
5. **Multiples escrituras sin transaccion** — fallos parciales = estado inconsistente, pesadilla de soporte
6. **APIs externas sin `connect_timeout`** — proveedor lento bloquea workers de cola y agota PHP-FPM
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permisos que nadie revisa en PRs futuros
8. **Invalidacion de cache insuficiente** — clasico "en local funciona" tras deploy multi-instance
9. **Idempotencia en operaciones retry/doble-click** — pedidos duplicados, emails duplicados, cobros duplicados
10. **Coherencia de tipos** entre codigo, schema y BD — `===` falla silencioso en MySQL strict
11. **Sin kill-switch** — incidentes a las 3am sin tiempo de hacer rollback
12. **Form alters AJAX sin `#process`** — el alter se pierde en AJAX rebuild
13. **`\Drupal::service()` en clases nuevas** — bloquea unit tests y kernel tests
14. **Bloques/formatters custom sin `getCacheableMetadata()`** — rompe BigPipe y Dynamic Page Cache silenciosamente
15. **Schema de config desactualizado** — `drush cim` falla en otros entornos
16. **Migraciones sin `id_map` limpio** — rollbacks corruptos detectados meses despues
17. **Update hooks no idempotentes** — re-ejecucion manual tras fallo parcial empeora la BD
18. **Overrides de `settings.php` colisionando con config split** — silenciosamente perdidos en cada deploy

## NEVER list — 15 anti-patrones especificos de Drupal

Cosas que solo aprendes de incidentes reales:

- **NUNCA** marcar un hallazgo de estilo (typo, espacio, comentario) como "Alta" — diluye la severidad, el equipo deja de leer las Altas reales
- **NUNCA** sugerir refactors fuera del diff salvo seguridad critica o data loss — rompe el alcance del PR
- **NUNCA** aprobar `\Drupal::service()` en clases nuevas con el argumento "ya habia antes" — perpetua deuda
- **NUNCA** dar por bueno `accessCheck(FALSE)` sin comentario `// accessCheck OK porque...` en la linea siguiente
- **NUNCA** aprobar `|raw` en Twig sin verificar que el origen es 100% controlado por el sistema
- **NUNCA** aprobar `entityTypeManager->getStorage()->loadMultiple()` sin guarda de array vacio — `loadMultiple([])` devuelve TODAS las entidades (clasico de fuga de memoria)
- **NUNCA** aprobar Batch API sin `finished` callback que maneje `$success === FALSE`
- **NUNCA** aprobar `EntityFieldManagerInterface::getFieldStorageDefinitions()` sin verificar que el field existe primero — zombie field storage tras delete + antes de `field_purge_batch`
- **NUNCA** marcar el informe como "OK" si hay cualquier hallazgo de severidad Alta sin resolver

## Framework Codex de 5 preguntas

Antes de revisar cualquier bloque, pregunta:

1. **Que tipo de cambio es?** Hook, refactor, hotfix, migracion, config — determina las reglas Codex aplicables
2. **Cual es el peor caso en produccion?** Fija el suelo de severidad
3. **Que asume el cambio fuera del diff?** Schema, indices, permisos — los olvidos viven en lo que no se ve
4. **Es idempotente?** Retry, doble-click, re-deploy, re-import config
5. **Se puede desactivar?** Kill-switch via config/setting/feature flag para incidentes a las 3am

Un ejemplo trabajado guia paso a paso la aplicacion a un mini-diff hipotetico.

## Estructura del informe

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branch>)

## Resumen ejecutivo
<2-4 frases: alcance, conteo de severidades, veredicto>

## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI

## Riesgos (tabla)
| Área | Riesgo | Severidad | Mitigación |

## Sugerencias accionables (priorizado)
## Lo positivo (porque tambien va en el PR)
## Checklist final
```

Cada hallazgo sigue **Problema (Severidad)** → **Riesgo** → **Solucion** con codigo adaptado de las 14 plantillas en `references/`.

## Auto-deteccion de IDE

Lee `CLAUDE_CODE_ENTRYPOINT` primero (`claude-vscode`, `claude-cursor`, `claude-antigravity`). Solo cae a deteccion por carpeta si el env var no es concluyente. Esto evita el bug de escribir informes en una carpeta `.cursor/` legacy cuando estas en VS Code.

| Deteccion | Carpeta de salida |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (ninguno / CLI) | `docs/revisiones-diff/` |

## Checklist de auto-verificacion

Antes de entregar, la skill recorre 12 checks: primera linea correcta, archivo en la carpeta correcta, references cargadas en esta sesion, cada hallazgo con Problema/Riesgo/Solucion, ninguna Alta es solo de estilo, sin sugerencias fuera de alcance, todas las explicaciones en espanol + codigo en ingles, etc. Si alguna casilla queda sin marcar, vuelve atras y arregla.

## Recovery — que hacer cuando algo falla

| Sintoma | Accion |
|---|---|
| `references/*.md` no existe | Avisar al usuario, no inventar puntos Codex |
| `git fetch` falla por red | Continuar con `develop` local + nota en informe |
| `.cursor/` no se puede crear | Pedir al usuario que cree la carpeta |
| Diff > 200 archivos | Pedir confirmacion antes de continuar |
| El usuario esta en `develop` | Abortar con mensaje claro |

## Evaluacion

- **`/skill-judge`**: 120/120 (Grado A+) — puntuacion perfecta en las 8 dimensiones
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, cero red, cero MCP, cero env vars sensibles

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

Si quieres revisar un PR remoto en lugar de tu rama actual, usa [`codex-pr-review`](../codex-pr-review/) — misma metodologia Codex, mismas references, descarga el PR via `git fetch origin pull/<N>/head`.

## Licencia

MIT
