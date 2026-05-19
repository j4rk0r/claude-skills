# Git Sync — R13: milestone como propiedad compartida del equipo (opt-in)

**Load when**: el proyecto define `milestone_sync.enabled: true` en
`.milestones/config.yml` Y vas a (a) cargar/auditar un milestone
(`/milestone <name>`, `/milestone sync`), (b) escribir en `.milestones/`
(init/update/done/start/R11), o (c) sellar una subtarea con su PR.
**Do NOT load** si el bloque `milestone_sync` no existe (comportamiento
clásico, este archivo es irrelevante) ni en `/milestone` list.

---

## 1. Qué resuelve

Sin esto, el milestone es un archivo local por máquina. En equipo eso degenera
en dos fallos:

- **Caos duplicado**: si cada feature branch edita `.milestones/<slug>.md`, los
  PRs chocan en ese archivo y cada miembro ve una lista de tareas distinta.
- **Listas obsoletas**: un miembro avanza subtareas y el resto sigue con una
  copia vieja.

R13 hace del milestone una **propiedad compartida única en una rama canónica**
(normalmente `develop`), editada SIEMPRE contra esa rama vía un worktree
dedicado — nunca dentro de las ramas de código. Es **opt-in** y **degrada a
no-op** sin romper nada: sin el bloque de config, la skill se comporta
exactamente como antes (portable, zero-dep).

## 2. Config (`.milestones/config.yml`)

```yaml
milestone_sync:
  enabled: true        # ausente o false → R13 entero es no-op
  branch: develop      # rama canónica (default: develop si enabled y no se indica)
  path: .milestones    # subdir a sincronizar (default: .milestones)
```

Resolución de la rama canónica:
1. `milestone_sync.branch` si está.
2. Si no: `develop` si existe en `origin`; si no, la rama por defecto del remoto.
3. Si no hay remoto → no-op (degradación, ver §6).

## 3. Helper

Todo el git lo encapsula `references/milestone-sync.sh`. Auto-install igual que
los otros helpers de la skill: si `~/.claude/milestone-sync.sh` no existe →
copiar desde `references/milestone-sync.sh` + `chmod +x`.

Subcomandos (todos idempotentes, todos no-op-safe):

| Comando | Uso |
|---|---|
| `milestone-sync.sh check <repo_root> <slug>` | Estado vs rama canónica: `up-to-date` / `remote-newer` / `diverged` / `local-only` / `noop:<razón>` |
| `milestone-sync.sh pull <repo_root> <slug>` | Trae la versión canónica al working copy local (tras confirmación del usuario) |
| `milestone-sync.sh push <repo_root> <slug>` | Commit+push de `<path>/<slug>.md` a la rama canónica vía worktree. Salida: `pushed` / `commit-pending-push:<cmd>` / `noop:<razón>` |
| `milestone-sync.sh stamp <repo_root> <slug> <X.Y> <pr_number>` | Anota `` `⏳ PR #<n>` `` en la línea de la subtarea `[~]` y hace push |

## 4. Comportamiento en LECTURA

En `/milestone <name>` (load) y `/milestone sync`, ANTES de mostrar contexto o
auditar:

1. `milestone-sync.sh check <root> <slug>`.
2. Según resultado:
   - `up-to-date` / `local-only` → continuar normal.
   - `remote-newer` → **avisar** ("otro miembro avanzó el milestone; hay versión
     más nueva en `<branch>`") y ofrecer `pull` antes de trabajar. No pisar la
     remota sin que el usuario lo decida.
   - `diverged` → avisar de divergencia (local y remoto cambiaron). Mostrar
     ambas cabeceras de `## Contexto` y pedir al usuario cómo reconciliar
     (adoptar remoto / conservar local / fusionar manual). NUNCA auto-merge.
   - `noop:<razón>` → silencioso, continuar (degradación).
3. NO se hace `check` en `/milestone` (list): añade latencia de red en cada
   listado para nulo valor.

## 5. Comportamiento en ESCRITURA

Tras CUALQUIER Edit/Write a `.milestones/<slug>.md` (init Step 7, update, done,
R11 paso 5), inmediatamente después de regenerar el snapshot de memoria:

1. `milestone-sync.sh push <root> <slug>`.
2. Resultado:
   - `pushed` → confirmar en una línea ("milestone sincronizado a `<branch>`").
   - `commit-pending-push:<cmd>` → el commit en el worktree está hecho; el push
     lo bloqueó el guard de seguridad / auth / protección. **Avisar** con el
     comando exacto a ejecutar; **no** reintentar en bucle; **no** bloquear ni
     revertir la operación de milestone.
   - `noop:<razón>` → silencioso.
3. El push del milestone NO requiere confirmación del usuario (solo toca
   `<path>/`, rama canónica, vía worktree aislado). El commit del **código**
   sigue siendo aparte y SÍ requiere confirmación (no se mezcla aquí).

## 6. Mecanismo git (worktree aislado)

`milestone-sync.sh` nunca cambia tu rama ni toca tu working tree:

- Si la rama actual del working tree principal **es** la canónica → opera ahí
  añadiendo y commiteando SOLO `<path>/` (no arrastra código).
- Si es otra rama (caso normal: estás en `feature/*`) → usa un **worktree
  dedicado** en `<root>/.git/milestone-sync-wt` fijado a la rama canónica con
  sparse-checkout limitado a `<path>/`. Se resetea a `origin/<branch>` antes de
  aplicar, copia el `<slug>.md` actual, commitea solo `<path>/`, pushea.
- El worktree vive bajo `.git/` → invisible a `git status`, nunca se commitea,
  no contamina el repo del proyecto.

Esto materializa la regla dura: **`.milestones/<slug>.md` jamás entra en una
feature branch ni en un PR de código** (anti-pattern #15). El milestone viaja
solo por la rama canónica.

## 7. Sello de PR (`[~]` + `⏳ PR #N`)

No es un estado nuevo. `[~]` ya es "code-complete, pendiente de aprobación"; un
PR abierto es precisamente el vehículo de esa aprobación. Cuando se abre un PR
que implementa una subtarea:

1. La subtarea debe estar `[~]` (si está `[>]`/`[ ]`, primero promover con
   evidencia — no saltar el modelo de estados).
2. `milestone-sync.sh stamp <root> <slug> <X.Y> <N>` añade la anotación inline
   `` `⏳ PR #<N>` `` al final de la línea (estilo backticks, anti-pattern #8;
   parser-safe: no cambia el checkbox ni los marcadores de sección — ver
   anti-pattern #13) y sincroniza.
3. Al mergear el PR + aprobación humana explícita → `/milestone done` → `[x]`
   (la anotación de PR se retira en ese Edit).

Ejemplo de línea:

```
- [~] 3.1 Servidor MCP (`review_branch`) [MCP/Integraciones] `⏳ PR #42`
```

## 8. Matriz de degradación (no-op silencioso)

`milestone-sync.sh` devuelve `noop:<razón>` y la skill continúa sin avisar
(salvo log de una línea en modo verbose) cuando:

| Razón | Situación |
|---|---|
| `noop:disabled` | `milestone_sync.enabled` ausente o `false` |
| `noop:not-git` | `<root>` no es repo git |
| `noop:no-remote` | sin remoto `origin` |
| `noop:no-branch` | la rama canónica no existe en `origin` |
| `noop:no-change` | el `<slug>.md` no cambió respecto a la rama canónica |

La skill **nunca** aborta una operación de milestone por un fallo de sync. R13
es aditivo: si algo del git no está, el milestone sigue funcionando local como
siempre.

## 9. Edge cases

- **Dos miembros editan a la vez**: el segundo `push` ve `diverged`; el helper
  NO fuerza. Avisa y deja `commit-pending-push`; el usuario hace `pull`,
  reconcilia el `## Contexto` (ambas entradas se conservan, son append-only por
  fecha) y reintenta. `## Contexto` es cronológico inverso → fusionar = intercalar
  entradas por fecha, nunca borrar.
- **Estás en la rama canónica en el working tree principal**: no se crea
  worktree; se commitea `<path>/` ahí. Si hay también código sin commitear en
  esa rama, el helper hace `git add` SOLO de `<path>/` (pathspec explícito),
  nunca `git add -A`.
- **Rama canónica protegida** (p.ej. si alguien apunta `branch` a `main`
  protegida): el push fallará → `commit-pending-push`. Es señal de mala config:
  la rama canónica debe ser una rama de integración NO protegida (`develop`).
- **`/milestone start` (ventana nueva)**: el pre-start `update` ya dispara el
  `push`; la ventana nueva, al cargar, hace `check` y arranca sobre la versión
  canónica fresca. Cierra el ciclo equipo.

## 10. Por qué importa

El milestone es el contrato de "qué falta y quién lo tiene". En solo es un
fichero; en equipo, sin una única copia canónica viva, se convierte en N
ficheros mintiéndose entre sí. R13 garantiza una sola verdad, fuera de las
ramas de código, sin romper los proyectos que no la usan.
