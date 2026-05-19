# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Terminaste una feature a lo largo de 3 conversaciones. La 4ª empieza de cero porque el contexto no sobrevive. Y tu compañero trabaja con una lista de tareas obsoleta.**

milestone v2 es un tracker de desarrollo persistente con **caché de dos niveles**: snapshots de memoria compactos (~100 tokens, auto-cargados) para estado instantáneo, y ficheros autoritativos completos para el histórico profundo. Clasifica las subtareas como `[simple]` o `[complejo]`, exigiendo un plan antes de ejecutar trabajo complejo — evitando el costoso ciclo de prueba y error de 6+ ediciones iterativas sobre el mismo fichero. El **modo equipo opcional (R13)** convierte el milestone en una única fuente de verdad compartida, git-sincronizada a una rama canónica para que todo el equipo vea siempre la misma lista actualizada.

## Instalación

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Cómo funciona

```
Tú: "/milestone dashboard"
        |
        v
(modo equipo) comprueba primero si hay un milestone más nuevo en la rama canónica
        |
        v
Lee el snapshot de memoria (cero lecturas de fichero — ya en contexto)
        |
        v
Muestra: objetivo, subtareas pendientes, decisiones, última entrada de contexto
        |
        v
Clasifica subtareas: [simple] -> ejecutar | [complejo] -> plan primero
        |
        v
Tras el trabajo: actualiza el fichero milestone + regenera el snapshot
        |
        v
(modo equipo) git-sincroniza .milestones/ a la rama canónica
        |
        v
Siguiente conversación / siguiente compañero: contexto instantáneo y al día
```

## Comandos

| Fase | Comando | Descripción |
|-------|---------|-------------|
| Discovery | `/milestone` | Lista todos los milestones con estado y progreso |
| Discovery | `/milestone <name>` | Carga contexto (fuzzy match — "dash" encuentra "dashboard-propietario") |
| Planning | `/milestone init <name>` | Crea un milestone nuevo con propuestas de subtareas |
| Execution | `/milestone start <name>` | Abre una sesión de terminal nueva con contexto compacto precargado |
| Execution | `/milestone done <name> <subtask>` | Marca subtarea completada con edición mínima |
| Review | `/milestone update <name>` | Actualización en bloque tras una sesión de trabajo |

## Funciones clave

- **Caché de dos niveles** — snapshot de memoria (~100 tok) para lecturas, fichero autoritativo para el histórico completo. 99% más barato que leer el fichero entero cada vez.
- **Clasificación por complejidad** — `[simple]` (1 fichero, cambio claro) vs `[complejo]` (multi-fichero, lógica nueva). Las subtareas complejas quedan **bloqueadas** hasta que exista un plan.
- **Reglas de eficiencia de tokens** — 3+ cambios al mismo fichero → un único Write (10x más barato que Edits iterativos). No releer ficheros ya en contexto.
- **Comando de sesión nueva** — `/milestone start` abre un `claude` fresco en una ventana de terminal nueva con contexto compacto, eliminando el multiplicador de coste 5-10x del historial de conversación acumulado.
- **Modo equipo (R13, opt-in)** — un único milestone compartido, git-sincronizado a una rama canónica (default `develop`) vía un worktree aislado, para que todo el equipo lea/escriba la misma lista viva. Desactivado por defecto.
- **Fuzzy matching** — escribe nombres parciales para cargar milestones
- **Log de contexto append-only** — registro en orden cronológico inverso de qué pasó y por qué
- **17 reglas NEVER** — cubren prevención de split-brain, snapshots obsoletos, anti-patrones de edición y riesgos del git-sync en equipo

## Modo equipo (R13) — opt-in

Sin esto, el milestone es un fichero local por máquina. En equipo eso degenera en listas duplicadas (cada feature branch edita el mismo fichero) y listas de tareas obsoletas. El modo equipo convierte el milestone en una **única fuente de verdad compartida en una rama canónica**, editado solo contra esa rama vía un worktree dedicado — nunca dentro de las ramas de código.

Actívalo por proyecto en `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # ausente o false -> todo R13 es un no-op silencioso
  branch: develop      # rama canónica (default: develop)
  path: .milestones     # subdir sincronizado (default: .milestones)
```

- **En lectura** (`/milestone <name>`, `/milestone sync`): trae la rama canónica y, si un compañero avanzó el milestone, avisa y ofrece adoptarlo antes de que trabajes.
- **En escritura** (init / update / done / fin de sesión): tras refrescar el snapshot, commitea **solo** `<path>/<slug>.md` y lo pushea a la rama canónica vía un worktree aislado bajo `.git/` — tu rama de código y tu working tree nunca se tocan.
- **Sello de PR**: una subtarea cuyo trabajo está en un PR abierto mantiene su estado `[~]` con una anotación inline `` `⏳ PR #N` `` (no es un estado nuevo — `[~]` ya significa "code-complete, pendiente de aprobación"; el PR es el vehículo de esa aprobación).
- **Degradación con gracia**: sin git / sin remoto / sin rama canónica / bloque ausente → no-op silencioso. La promesa zero-dependency se mantiene.
- **Nunca salta los guards**: si un push lo bloquea un guard de seguridad o la auth, el commit se queda en el worktree y recibes el comando exacto a ejecutar — nunca silencia el fallo ni bloquea tu trabajo.

## Arquitectura

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-cargado, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTORITATIVO (histórico completo)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Planes para subtareas [complejo]
<project-root>/.git/milestone-sync-wt/                     ← Worktree aislado R13 (solo modo equipo)
```

## Qué lo diferencia de v1

| Aspecto | v1 | v2 |
|--------|----|----|
| Coste de carga | ~8.300 tok (Read fichero completo + templates) | ~100 tok (snapshot de memoria) |
| Coste de listado | ~8.750 tok (Read todos los ficheros) | ~400 tok (solo frontmatter, limit:8) |
| Subtareas complejas | Sin gate — prueba y error | Plan requerido antes de ejecutar |
| Gestión de sesión | Misma conversación (el contexto se acumula) | `/milestone start` abre sesión fresca |
| Carga de referencias | Siempre carga templates.md | Solo en `/milestone init` |
| Colaboración en equipo | Ninguna — solo fichero local | Milestone compartido git-sincronizado opt-in (R13) |

## Evaluación

- **`/skill-judge`**: 120/120 (Grado A+)
- **`/skill-guard`**: 92/100 (GREEN) — sin scripts ejecutados en operación normal, sin red, sin MCP. R13 (opt-in, desactivado por defecto) es el único camino que realiza operaciones git.

## Seguridad

- Por defecto, solo lee/escribe ficheros locales `.milestones/*.md` y snapshots de memoria. Sin red, sin scripts en operación normal.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash se usa para `/milestone start` (auto-instala el script en el primer uso) y, **solo cuando el modo equipo está explícitamente activado**, para `milestone-sync.sh` — que realiza `git fetch`/`git push` limitados a `<path>/` contra la rama canónica vía un worktree aislado. Desactivado por defecto; nunca pushea código; nunca salta los guards de seguridad (push bloqueado → reportado, no silenciado).
