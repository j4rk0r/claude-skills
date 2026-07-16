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
- **Modo central (v1.2.0, opt-in)** — config y ficheros autoritativos en el repo central de memorias (`~/.claude/projects/<clave>/milestones/`) en vez del repo del proyecto: **los repos de cliente quedan sin rastro de planificación interna**. Discovery automático; el modo clásico local siempre tiene precedencia. Alta de miembros del equipo con `references/team-bootstrap.sh`.

## Modo equipo (R13 + R14) — opt-in

Sin esto, el milestone es un fichero local por máquina. En equipo eso degenera en listas duplicadas (cada feature branch edita el mismo fichero) y listas de tareas obsoletas. El modo equipo convierte el milestone en una **única fuente de verdad compartida en una rama canónica**, editado solo contra esa rama vía un worktree dedicado — nunca dentro de las ramas de código. **Descubre los milestones que otros crearon** antes de que listes o crees uno (así no duplicas `foo` cuando un compañero lo creó hace un minuto), y **reserva atómicamente cada subtarea** en el momento en que alguien la arranca — así dos personas nunca acaban haciendo lo mismo, y el sistema te dice *quién* llegó antes.

Actívalo por proyecto en `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # ausente o false -> todo el modo equipo es no-op silencioso
  branch: develop      # rama canónica (default: develop)
  path: .milestones     # subdir sincronizado (default: .milestones)
```

### R13 — fuente de verdad compartida

- **En lectura** (`/milestone <name>`, `/milestone sync`): trae la rama canónica y, si un compañero avanzó el milestone, avisa y ofrece adoptarlo antes de que trabajes.
- **En escritura** (init / update / done / fin de sesión): tras refrescar el snapshot, commitea **solo** `<path>/<slug>.md` y lo pushea a la rama canónica vía un worktree aislado bajo `.git/` — tu rama de código y tu working tree nunca se tocan.
- **Sello de PR**: una subtarea cuyo trabajo está en un PR abierto mantiene su estado `[~]` con una anotación inline `` `⏳ PR #N` ``.

### R14 — claim atómico antes de tocar código

Cuando ejecutas `/milestone start`, el sistema **reserva la subtarea en la rama canónica ANTES de que toques código**. La línea pasa a `[>]` con una anotación inline:

```
- [>] 1.4 [complejo] Integración Stripe — `🔒 Jane Doe (jdoe) · 2026-05-26 15:01` [Backend]
```

- **Atómico vía `git push --fast-forward`**: si dos miembros intentan claimear la misma subtarea a la vez, solo un FF push gana. El perdedor hace fetch, re-valida, ve el claim del ganador y aborta con `race-lost:<ganador>` — te dice exactamente quién la cogió. Si el otro ya había publicado el claim, recibes `already-claimed:<ganador>` de entrada. Imposible doble claim.
- **Loop de reintentos, no un único intento**: al perder el FF, el claim rebasa y re-valida hasta 5 veces, así con 3+ claimers simultáneos no aparece un `commit-pending-push` engañoso — ese estado ya solo significa un problema real de push (auth / rama protegida / red).
- **Verificación en vivo obligatoria**: `claim` hace `git fetch` y aborta con `noop:fetch-failed` si el chequeo de red falla. Sin claim contra datos locales obsoletos.
- **`/milestone` listing en modo equipo consulta claims**: el listado muestra quién tiene qué reservado. Una subtarea claimeada por otro NUNCA aparece como "libre" para ti.
- **Trazabilidad**: cada claim/release deja un commit dedicado en `<branch>` (`chore(milestone): claim <slug> <X.Y> by <Jane Doe (jdoe)>`). El historial de la rama *es* el log de coordinación del equipo.
- **Claims caducados sugeridos al arrancar**: si todo lo libre está cogido pero un claim tiene más de 24h, `/milestone start` sugiere el override consciente (`release --force` + re-claim) en vez de solo listarlo.
- **Handover vía `/milestone release <slug> <X.Y> --force`** cuando hace falta (vacaciones, máquina caída, abandono). Dejar nota en `## Contexto` justificando; el claimer original verá `not-claimed` la próxima vez.

### Sync de índice — nunca crees un duplicado (H4)

R13/R14 sincronizan un `<slug>.md` cada vez, pero eso por sí solo no revela **milestones nuevos que un compañero creó y tú no tienes en local**. El sync de índice cierra ese hueco leyendo el catálogo completo de milestones publicados antes de que listes o crees:

- **`milestone-sync.sh index <root>`** lista cada milestone de la rama canónica como `<slug>` · `<creado_por>` · `<creado_el>` · `<actualizado_el>` (autor/fecha del commit que *añadió* el fichero).
- **En `/milestone init`**: el nombre propuesto se compara con el índice (exacto y "casi-igual" ignorando `-`/`_`/mayúsculas). Si colisiona → **no** lo crea; te dice **quién lo creó y cuándo**, y ofrece cargarlo en vez de duplicar.
- **En `/milestone` (list)**: los milestones presentes en la rama pero no en local se muestran como `🆕 remoto · creado por <handle>`, así ves de un vistazo lo que otros arrancaron incluso antes de hacer pull.

### Auto-update del helper (H1)

El helper se instala en `~/.claude/milestone-sync.sh`. Para que dos máquinas no corran lógicas de claim distintas, está **versionado**: la skill compara la `version` instalada con la copia de referencia y re-copia cuando difieren (o cuando falta), en el primer sync de cada sesión.

### Límite honesto

Git es distribuido: el índice y los claims solo ven lo que está **en la rama canónica**. Un claim que alguien tiene sin pushear es invisible, igual que cualquier commit local. Por eso R14 obliga a **publicar el claim en el instante de arrancar** (antes de la primera línea de código) — "empezar una tarea" y "que el resto lo vea" son el mismo acto atómico.

### Comportamiento común

- **Degradación con gracia**: sin git / sin remoto / sin rama canónica / bloque ausente → no-op silencioso. La promesa zero-dependency se mantiene.
- **Nunca salta los guards**: si un push lo bloquea un guard de seguridad o la auth, el commit se queda en el worktree y recibes el comando exacto a ejecutar — nunca silencia el fallo ni bloquea tu trabajo.

## Arquitectura

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-cargado, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTORITATIVO (histórico completo)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Planes para subtareas [complejo]
<project-root>/.git/milestone-sync-wt/                     ← Worktree aislado R13 (solo modo equipo)

# Modo central (v1.2.0 — el repo del cliente queda limpio):
~/.claude/projects/<clave>/milestones/config.yml          ← config (marcador de discovery)
~/.claude/projects/<clave>/milestones/<slug>.md           ← AUTORITATIVO (central)
```

## Qué lo diferencia de v1

| Aspecto | v1 | v2 |
|--------|----|----|
| Coste de carga | ~8.300 tok (Read fichero completo + templates) | ~100 tok (snapshot de memoria) |
| Coste de listado | ~8.750 tok (Read todos los ficheros) | ~400 tok (solo frontmatter, limit:8) |
| Subtareas complejas | Sin gate — prueba y error | Plan requerido antes de ejecutar |
| Gestión de sesión | Misma conversación (el contexto se acumula) | `/milestone start` abre sesión fresca |
| Carga de referencias | Siempre carga templates.md | Solo en `/milestone init` |
| Colaboración en equipo | Ninguna — solo fichero local | Milestone compartido git-sincronizado opt-in (R13) + claim atómico antes de tocar código (R14) |
| Protección de carrera | Ninguna | Git fast-forward push como lock de serialización — imposible doble claim de una subtarea (R14) |

## Evaluación

- **`/skill-judge`**: 120/120 (Grado A+)
- **`/skill-guard`**: 92/100 (GREEN) — sin scripts ejecutados en operación normal, sin red, sin MCP. R13 (opt-in, desactivado por defecto) es el único camino que realiza operaciones git.

## Seguridad

- Por defecto, solo lee/escribe ficheros locales `.milestones/*.md` y snapshots de memoria. Sin red, sin scripts en operación normal.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash se usa para `/milestone start` (auto-instala el script en el primer uso) y, **solo cuando el modo equipo está explícitamente activado**, para `milestone-sync.sh` — que realiza `git fetch`/`git push` limitados a `<path>/` contra la rama canónica vía un worktree aislado. Desactivado por defecto; nunca pushea código; nunca salta los guards de seguridad (push bloqueado → reportado, no silenciado).
