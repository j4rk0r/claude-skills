# Project Audit — `/milestone sync`

Auditoría del estado real del proyecto vs lo que los milestones reflejan. Detecta trabajo no trackeado, milestones obsoletos y áreas sin cobertura.

## Paso 1 — Recopilar fuentes de verdad del proyecto

Buscar documentos técnicos y fuentes de requisitos en este orden:

| Fuente | Dónde buscar | Qué extraer |
|--------|-------------|-------------|
| Documento técnico / spec | `docs/`, `*.pdf`, `README.md`, `CLAUDE.md` | Funcionalidades previstas, módulos descritos, arquitectura |
| Tablero de gestión | Monday, Jira, GitHub Issues (si hay MCPs) | Tareas pendientes, prioridades, estados |
| Codebase actual | `git log --oneline -20`, estructura de directorios, módulos | Qué existe implementado vs qué falta |
| Milestones existentes | `.milestones/*.md` (leer todos con `limit:8` por frontmatter) | Progreso actual, subtareas pendientes, última actividad |
| Deuda técnica | `CLAUDE.md`, TODOs en código, warnings conocidos | Trabajo pendiente no trackeado en ningún milestone |

## Paso 2 — Construir mapa de cobertura

Cruzar las funcionalidades del documento técnico con el estado del código y los milestones:

```
Para cada funcionalidad/módulo descrito en el documento técnico:
  1. ¿Existe código implementado? → Verificar con Glob/Grep
  2. ¿Hay un milestone que lo cubra? → Buscar en .milestones/
  3. ¿El milestone está actualizado? → Comparar subtareas vs código real
  4. ¿Faltan subtareas en el milestone? → Código nuevo sin reflejar
  5. ¿Falta un milestone completo? → Funcionalidad sin tracking
```

Clasificar cada funcionalidad en:

| Estado | Significado |
|--------|-------------|
| ✅ Completa | Código existe + milestone marcado completed |
| 🟡 En progreso | Milestone existe, algunas subtareas pendientes |
| 🔴 Sin milestone | Funcionalidad descrita pero sin tracking — necesita `/milestone init` |
| ⚠️ Desactualizado | Milestone existe pero no refleja el estado real del código |
| 🆕 No prevista | Código existe pero no aparece en el documento técnico |

## Paso 3 — Actualizar milestones existentes desactualizados

Para cada milestone marcado como ⚠️ Desactualizado:

1. Leer el milestone completo (`.milestones/<slug>.md`)
2. Comparar subtareas `[ ]` con el código actual:
   - Si la subtarea ya está implementada → marcar `[x]` con QA (cargar `qa-validation.md`)
   - Si la subtarea es obsoleta (ya no aplica) → marcar `[-]` con nota
3. Comparar subtareas `[x]` con el código actual:
   - Si el código fue eliminado o revertido → advertir, no desmarcar sin confirmación
4. Añadir subtareas nuevas descubiertas (pedir confirmación)
5. Actualizar `## Referencias` con archivos actuales
6. Añadir entrada en `## Contexto`: "Sincronización con estado real del proyecto"
7. Sync memoria

## Paso 4 — Proponer milestones nuevos para funcionalidades sin cobertura

Para cada funcionalidad marcada como 🔴 Sin milestone:

1. Analizar el codebase para determinar estado actual (¿hay código parcial? ¿nada?)
2. Proponer un milestone con:
   - **Nombre** descriptivo
   - **Objetivo** en una frase
   - **Subtareas** con `[simple]`/`[complejo]` y definición de "done"
   - **Dependencias** con otros milestones si las hay
3. Agrupar funcionalidades relacionadas en un solo milestone cuando tenga sentido (evitar proliferación)

## Paso 5 — Presentar informe y esperar confirmación

Mostrar al usuario:

```
## Auditoría del proyecto — YYYY-MM-DD

### Estado actual
| Funcionalidad | Estado | Milestone | Progreso |
|--------------|--------|-----------|----------|
| Auth usuarios | ✅ | auth-system | 5/5 |
| Dashboard admin | 🟡 | dashboard-propietario | 12/14 |
| Importación CSV | 🔴 | — | sin tracking |
| API REST | ⚠️ | api-publica | 3/7 (desactualizado) |

### Milestones a actualizar
1. **api-publica** — 2 subtareas completadas sin marcar, 1 obsoleta

### Milestones nuevos propuestos
1. **importacion-csv** — Importación de productos y usuarios desde CSV (4 subtareas)
2. **optimizacion-rendimiento** — Deuda técnica: cacheo, queries N+1 (6 subtareas)

¿Confirmas las actualizaciones y los nuevos milestones?
```

**NUNCA** crear milestones ni actualizar subtareas sin confirmación explícita del usuario.

## Cuándo ejecutar esta auditoría

| Trigger | Acción |
|---------|--------|
| `/milestone sync` (explícito) | Auditoría completa |
| `/milestone` (listar) y hace >14 días de la última auditoría | Sugerir: "Hace X días que no se audita el proyecto. ¿Ejecutar `/milestone sync`?" |
| `/milestone init` en proyecto con documento técnico | Antes de crear, verificar si hay otras funcionalidades sin milestone y ofrecer crearlos todos |
