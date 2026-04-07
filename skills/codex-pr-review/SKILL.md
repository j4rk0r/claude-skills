---
name: codex-pr-review
description: Revisa pull requests en proyectos Drupal 11 (u otro) siguiendo la metodología Codex (lógica de negocio, edge cases de hooks/queries, seguridad, performance, completitud). Genera un informe .md en la carpeta del IDE detectado (.antigravity/, .cursor/, .vscode/ o docs/) con hallazgos por severidad y soluciones accionables. Usar cuando el usuario pida "revisión Codex", "revisión de PR", "revisar PR", "revisar PR #N", "revisión tipo Codex" o indique un número de PR con ramas (ej. develop ← feature/alejandro). Triggers: revisión PR, revisar PR, codex PR, revisión Codex, lint PR.
allowed-tools: Bash(git:*) Bash(printenv CLAUDE_CODE_ENTRYPOINT) Bash(printenv __CFBundleIdentifier) Bash(printenv VSCODE_PID) Bash(mkdir:*) Bash(ls:*) Bash(wc:*) Bash(cd:*) Read Write Edit Grep Glob
---

# Revisión Codex — Pull Request

Primera línea del informe generado: **"Español confirmado."**

## Antes de revisar — pregúntate (framework Codex)

1. **¿Qué tipo de cambio es?** Hook nuevo, refactor, hotfix, migración, config — el tipo determina qué puntos Codex aplican.
2. **¿Cuál es el peor escenario en producción?** Si este código falla, ¿qué se rompe? Eso fija la severidad de los hallazgos.
3. **¿Hay algo fuera del diff que el cambio asume?** Schema, config, dependencias, índices BD, permisos — los olvidos viven en lo que no se ve.
4. **¿Es idempotente?** Si se ejecuta dos veces (retry, doble clic, re-deploy, re-import config), ¿pasa algo malo?
5. **¿Se puede desactivar?** ¿Hay kill-switch (config/setting/feature flag) si la feature explota a las 3am sin tiempo de redeploy?

Si no puedes responder a las cinco con confianza, lee el código circundante antes de emitir el informe.

### Ejemplo de aplicación (mini-PR)

PR: añade `mymodule_node_update()` que calcula un score y lo guarda en una tabla custom vía `db_query("INSERT ... VALUES ('" . $title . "')")`.

- **(1) Tipo:** hook de entidad + escritura SQL → aplican Codex 1, 3, 4, 9.
- **(2) Peor escenario:** SQL injection si `$title` viene de input + nodos nuevos sin score (falta `_insert`).
- **(3) Asume:** que la tabla custom existe (¿hay update hook? ¿schema?).
- **(4) Idempotente:** ¿qué pasa al re-guardar el nodo? ¿duplica filas o hace UPDATE? Verificar.
- **(5) Kill-switch:** no hay → hallazgo Media (Codex 11).

Resultado: 4 hallazgos (3 Alta + 1 Media), ninguno fuera del alcance del PR.

## Fast path (resumen ejecutable)

```
1. Leer references/metodologia-codex-completa.md   (~70 líneas, completo)
2. Leer references/plantillas-hallazgos.md          (~230 líneas, completo)
3. cd a drupal/ si existe, si no raíz del workspace
4. Pedir/confirmar número de PR y ramas (base ← head). Si no se sabe, preguntar.
5. git fetch origin pull/<N>/head:pr-<N>            (descarga rama del PR)
6. git diff --name-only origin/<base>...pr-<N>      → lista de archivos
7. Aplicar Decision tree para elegir puntos Codex prioritarios
8. Aplicar las 5 preguntas del framework Codex (sección anterior)
9. Revisar archivo por archivo, anotando hallazgos con Severidad
10. Detectar IDE: leer CLAUDE_CODE_ENTRYPOINT (claude-vscode/claude-cursor/claude-antigravity).
    Solo si no es concluyente, caer a detección por carpeta existente.
11. Escribir informe en <carpeta-IDE>/Revisiones PRs/lint-review-pr<N>.md
12. Auto-verificar contra el Checklist de auto-verificación (final del documento)
```

Si cualquier paso falla, detente y consulta la sección "Edge cases del propio flujo".

## Ubicación fija (no preguntar)

- **Repo git:** si existe carpeta `drupal/` en el workspace, los `git` se ejecutan **dentro de `drupal/`**. Si no, raíz del workspace.
- **Carpeta de salida (auto-detectada por IDE):**

  **Paso 1 — detectar el IDE por variable de entorno (PRIORITARIO).** Ejecuta `printenv CLAUDE_CODE_ENTRYPOINT` (o equivalente) y aplica:
  | `CLAUDE_CODE_ENTRYPOINT` | Carpeta a usar |
  |---|---|
  | `claude-antigravity` | `.antigravity/Revisiones PRs/` |
  | `claude-cursor` | `.cursor/Revisiones PRs/` |
  | `claude-vscode` | `.vscode/Revisiones PRs/` |
  | otros (`cli`, vacío, etc.) | continuar al Paso 2 |

  Señales secundarias si `CLAUDE_CODE_ENTRYPOINT` no es concluyente: `__CFBundleIdentifier` (`com.microsoft.VSCode` → VS Code, `com.todesktop.*` → Cursor, `com.google.Antigravity` → Antigravity), o `VSCODE_PID`/`CURSOR_*`/`ANTIGRAVITY_*` cuando existan.

  **Si el IDE se identificó por env**, crea la carpeta correspondiente aunque no exista todavía. **NUNCA caigas a detección por carpeta cuando el env var es claro** — eso causa el bug de elegir `.cursor/` solo porque sobrevive de un uso anterior del IDE.

  **Paso 2 — fallback por existencia de carpeta** (solo si no hay señal de env):
  1. Si existe `.antigravity/` en la raíz del workspace → `.antigravity/Revisiones PRs/`
  2. Si existe `.cursor/` (y no `.antigravity/`) → `.cursor/Revisiones PRs/`
  3. Si existe `.vscode/` (y no las anteriores) → `.vscode/Revisiones PRs/`
  4. Si no existe ninguna → `docs/revisiones-prs/`

- **Nombre del archivo:** `lint-review-pr<N>.md` (N = número de PR, sin ceros a la izquierda). Crear la carpeta si no existe. Un archivo por PR (no sobrescribir entre PRs).

## Flujo

1. **Detectar contexto del PR**:
   - Pedir/confirmar al usuario el **número de PR** y las **ramas exactas** (base ← head). Si no se proporcionan, preguntar antes de continuar.
   - `git fetch origin pull/<N>/head:pr-<N>` (descarga la rama del PR como `pr-<N>` local).
   - `git fetch origin <base>` (asegura que la rama base esté actualizada).
   - `git diff --name-only origin/<base>...pr-<N>` → lista de archivos.
   - Aplicar el **Decision tree** (siguiente sección).
2. **Cargar referencias necesarias** (ver sección "Carga de referencias").
3. **Revisar solo los archivos del PR** + dependencias mínimas.
4. **Emitir el informe** con la estructura obligatoria.

## Decision tree según contenido del PR

| Contenido del PR | Puntos Codex prioritarios | Foco extra |
|---|---|---|
| `.module` / `.php` (hooks, services, controllers) | 1, 2, 3, 4, 5, 6, 7, 9, 11, 13 | DI, access, transactions |
| `.twig` solo | 8, 14 | XSS, cache metadata, i18n |
| `.yml` config (`*.schema.yml`, `*.routing.yml`, `*.services.yml`) | 11, 15, 18 | Schema completo, overrides |
| `*.install` / update hooks | 1, 5, 9, 17 | Idempotencia, rollback |
| Migrations (`migrate_plus.migration.*`) | 16 | id_map, file usage |
| `.scss` / `.js` solo | — | Linters, A11y, BigPipe |
| **Diff vacío** | Reportar "PR sin cambios respecto a la base" y salir |
| **PR ya mergeado** | Avisar al usuario; confirmar si se quiere revisar histórico |
| **Sin acceso a `pull/<N>/head`** | Pedir confirmación de número de PR / repo correcto |
| **>200 archivos cambiados** | Avisar al usuario y pedir confirmación |
| **Solo `composer.lock`** | Revisar deps añadidas/eliminadas, no líneas |

## Edge cases del propio flujo

- Si `git fetch origin pull/<N>/head:pr-<N>` falla → verificar acceso al repo, número de PR, o si el repo no es GitHub (GitLab usa `merge-requests/<N>/head`).
- Si la rama base no existe localmente → `git fetch origin <base>:<base>`.
- Si el PR tiene >200 archivos cambiados → avisar al usuario y pedir confirmación antes de revisar (puede ser merge ruidoso).
- Si solo hay cambios en `composer.lock` → revisar deps añadidas/eliminadas, no líneas individuales.
- Si el PR ya fue mergeado → avisar al usuario y confirmar si se quiere revisar histórico igualmente.

## Carga de referencias

Esta skill tiene dos archivos en `references/`. Reglas de carga:

- **MANDATORY — leer ANTES de citar puntos Codex:** lee **completo** [`references/metodologia-codex-completa.md`](references/metodologia-codex-completa.md) (~70 líneas, 18 puntos con el PORQUÉ). **NUNCA** parafrasees los puntos sin haberlo leído. **NUNCA** uses range limits al leerlo.
- **MANDATORY — leer ANTES de redactar hallazgos:** lee **completo** [`references/plantillas-hallazgos.md`](references/plantillas-hallazgos.md) (~230 líneas, 14 plantillas con código real). Adapta los snippets al PR real, no inventes código.
- **Si ya las has leído en esta sesión**, no recargar — el contexto las conserva.
- **Do NOT load** ninguna otra documentación externa, README, ni archivos del propio módulo más allá del diff y dependencias mínimas.

## NEVER (lecciones aprendidas a las malas)

- **NUNCA** marcar "Alta" un hallazgo de estilo (typo, espacio, comentario). *Por qué:* diluye severidad, el equipo deja de leer las Altas reales.
- **NUNCA** sugerir refactors fuera del diff salvo seguridad crítica o data loss. *Por qué:* rompe el alcance del PR y genera fricción con el autor.
- **NUNCA** referenciar ni nombrar otros PRs en el documento. *Por qué:* el revisor del PR pierde foco y mezcla discusiones.
- **NUNCA** aprobar `\Drupal::service()` en clases nuevas con el argumento "ya había antes". *Por qué:* perpetúa deuda y bloquea testing.
- **NUNCA** dar por bueno `accessCheck(FALSE)` sin comentario `// accessCheck OK porque...` en la línea siguiente. *Por qué:* bypass silencioso de permisos.
- **NUNCA** aprobar migración sin verificar `id_map` y `file_usage` (si maneja media). *Por qué:* rollbacks rotos.
- **NUNCA** aprobar `|raw` en Twig sin verificar que el origen es 100% controlado por el sistema. *Por qué:* XSS persistente.
- **NUNCA** aprobar `$query->execute()` dentro de `hook_*_alter` sin cache. *Por qué:* N+1 en cada render.
- **NUNCA** aprobar nuevo `dependencies:` en `*.info.yml` sin verificar que el módulo está en `composer.json`. *Por qué:* deploy roto en CI.
- **NUNCA** escribir el informe en inglés. Código y comandos en inglés; explicaciones en español.
- **NUNCA** marcar el informe como "OK" si hay cualquier hallazgo de severidad Alta sin resolver.
- **NUNCA** citar un punto Codex sin haber leído `references/metodologia-codex-completa.md` en esta sesión.
- **NUNCA** aprobar `EntityFieldManagerInterface::getFieldStorageDefinitions()` sin verificar que el field exists primero. *Por qué:* tras eliminar un field y antes de `cron`/`field_purge_batch`, el storage queda zombi y revienta queries.
- **NUNCA** aprobar Batch API nueva sin `finished` callback que maneje `$success === FALSE`. *Por qué:* batches que fallan en mitad dejan datos a medias y nadie se entera.
- **NUNCA** aprobar `entityTypeManager->getStorage()->loadMultiple()` sin `array` vacío como guarda. *Por qué:* `loadMultiple([])` devuelve TODAS las entidades — bug clásico de fuga de memoria.

## Severidades (criterio fijo)

| Severidad | Criterio |
|---|---|
| **Alta** | Seguridad explotable, data loss, rompe producción, bloquea deploy |
| **Media** | Bug funcional, incumple estándar del proyecto, deuda inmediata |
| **Baja** | Estilo, micro-optimización, mejora opcional |

Si dudas entre dos niveles, **baja uno**. Las Altas deben ser **realmente** Altas.

## Estructura obligatoria del informe

```markdown
Español confirmado.

# Revisión de código — PR #<N> (<base> ← <head>)

## Resumen ejecutivo
<2-4 frases: alcance del PR, conteo por severidad, veredicto>

## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI

## Riesgos (tabla)
| Área | Riesgo | Severidad | Mitigación |

## Sugerencias accionables
1. ...

## Checklist final
- [ ] Hallazgos Alta resueltos
- [ ] Tests pasan
- [ ] Schema config actualizado
- [ ] Update hooks idempotentes
```

Cada hallazgo va con **Problema (Severidad)**, **Riesgo** y **Solución** (con código). Adapta las plantillas de [`references/plantillas-hallazgos.md`](references/plantillas-hallazgos.md).

## Idioma y tono

- **Español** en todo el texto. Inglés en código, nombres de clase, comandos y rutas.
- Tono profesional, directo, simpático con el equipo que aplicará las correcciones.
- Detalle proporcional a la complejidad del hallazgo.

## Checklist de auto-verificación (antes de entregar)

Antes de dar por cerrado el informe, comprueba uno por uno:

- [ ] Primera línea del informe es exactamente `Español confirmado.`
- [ ] El archivo está en `<carpeta-IDE>/Revisiones PRs/lint-review-pr<N>.md`
- [ ] El título incluye número de PR exacto y las ramas (base ← head)
- [ ] He leído `references/metodologia-codex-completa.md` en esta sesión
- [ ] He leído `references/plantillas-hallazgos.md` en esta sesión
- [ ] Cada hallazgo tiene **Problema (Severidad)**, **Riesgo** y **Solución**
- [ ] Ninguna severidad "Alta" es solo de estilo (typo, espacio, comentario)
- [ ] Todas las soluciones de código compilan mentalmente y siguen DI/PSR-12
- [ ] No he propuesto cambios fuera del alcance del PR (salvo seguridad crítica)
- [ ] No he referenciado ni nombrado otros PRs en el documento
- [ ] Todas las explicaciones en español, todo el código en inglés
- [ ] He aplicado las 5 preguntas Codex a cada bloque significativo
- [ ] El informe incluye Resumen ejecutivo, Hallazgos, Riesgos, Sugerencias y Checklist final
- [ ] Si hay hallazgos Alta sin resolver, el veredicto NO es "OK"

Si alguna casilla queda sin marcar, vuelve atrás y arregla antes de entregar.

## Recovery — qué hacer si algo falla

| Síntoma | Acción |
|---|---|
| `references/metodologia-codex-completa.md` no existe | Avisar al usuario, no inventar puntos Codex |
| `references/plantillas-hallazgos.md` no existe | Generar hallazgos sin plantilla pero con misma estructura |
| `git fetch origin pull/<N>/head` falla | Verificar número de PR, repo correcto, o si es GitLab (`merge-requests/<N>/head`) |
| Rama base no existe localmente | `git fetch origin <base>:<base>` y reintentar |
| `.cursor/` o `.vscode/` no se puede crear | Pedir al usuario que cree la carpeta y reintentar |
| PR demasiado grande (>200 archivos) | Pedir confirmación antes de continuar |
| PR ya mergeado | Avisar y confirmar si se revisa histórico igualmente |
| El usuario no proporciona número de PR | Preguntar antes de continuar, no asumir |
