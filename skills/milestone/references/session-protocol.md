# Session Protocol — R11 (session-end) + R12 (recovery)

**Load when**: vas a cerrar una sesión que produjo código (R11), o al iniciar sesión sobre un milestone y detectas señales de "sesión cortada" (R12). **Do NOT load** en list / update routine operations.

## R11 — Session-end protocol (OBLIGATORIO si hubo código)

Antes de cerrar una sesión que produjo cambios en el módulo/feature de un milestone activo, ejecutar en este orden:

### 1. Detectar evidencia real (no intenciones)

- `git status` → lista de archivos modificados/nuevos
- `grep` de símbolos clave del plan (rutas, métodos, clases, componentes) → confirma qué quedó materializado
- Si `project_type` lo soporta: `phpcs` / `phpstan` / `eslint` / `pytest` — marca archivos "broken" si fallan

### 2. Ajustar checkbox según evidencia

| Transición | Condición |
|------------|-----------|
| `[ ]` → `[>]` | ≥1 archivo/wave del plan existe Y phpcs pass (pero alcance total NO cubierto) |
| `[>]` → `[>]` (update nota) | Completaste una wave adicional; actualizar `— W<k>/<N>` |
| `[>]` → `[~]` | TODAS las waves/archivos del plan existen Y verificaciones pasan |
| Wave rota | Permanece `[>]` con nota `— W<k>/<N> code-complete, W<k+1> en progreso (broken: <archivo>)` |

### 3. Añadir entrada en `## Contexto`

Formato obligatorio:

```
### YYYY-MM-DD HH:MM — <subtarea X.Y> <wave o descripción>
- Archivos tocados: <lista de paths relativos>
- Waves completadas: W<a>, W<b>
- Waves pendientes: W<c>, W<d>
- Verificación: <phpcs/tests/drush cr status>
- Próximo paso: <siguiente wave o bloqueador>
- Estado: [>] (parcial) / [~] (completa)
```

### 4. Refrescar snapshot

En `~/.claude/projects/<project>/memory/milestone_<slug>.md` con contadores actualizados (`<active>▶` y `<pending>⏳`).

### 5. Commit opcional

Si el usuario trabaja con commits por wave, sugerir:
```
git commit -m "feat(<slug>): W<k>/<N> <descripción>"
```
Nunca ejecutar sin confirmación.

### 6. Git-sync del milestone (R13 — opt-in team mode)

Si `.milestones/config.yml` trae `milestone_sync.enabled: true`: tras el Edit
del milestone y el refresh del snapshot, ejecutar
`milestone-sync.sh push <root> <slug>` (sin confirmación: solo toca
`.milestones/`, rama canónica, vía worktree aislado). Si devuelve
`commit-pending-push:<cmd>` → avisar con el comando exacto; nunca bloquear ni
revertir la operación. El commit del **código** sigue siendo aparte y SÍ
requiere confirmación. Detalle → [`git-sync.md`](git-sync.md) §5.

### 7. Manejo del claim al cerrar (R14 — opt-in team mode)

Si la subtarea tenía claim propio `🔒 <tu_handle>`:

| Resultado del trabajo | Acción sobre el claim |
|-----------------------|------------------------|
| Promoviste `[>]` → `[~]` (code-complete) | El Edit del checkbox **retira la anotación 🔒 en el mismo Edit**. El claim ya cumplió su función. |
| Sigues en `[>]` con waves parciales | Mantén el claim — vas a continuar en próxima sesión. Otros siguen viendo `🔒 <tu_handle>`. |
| Decides no continuar (cancelación / handoff) | `milestone-sync.sh release <root> <slug> <X.Y>` libera explícitamente. La subtarea vuelve a `[ ]` para que otro la coja. |

NUNCA dejar `[~]` o `[x]` con `🔒` residual. Si pasa, R12 lo limpia.

### Sesión sin cambios de código

→ No mover checkbox, pero SÍ añadir entrada `## Contexto` minimal si hubo decisiones o bloqueos documentados.

---

## R12 — Session-start / recovery protocol

Al iniciar sesión sobre un milestone (vía `/milestone start`, `/milestone <name>`, o primer mensaje que referencia el milestone):

### 1. Leer snapshot de memoria

No leer `.milestones/` todavía.

**R13 team mode**: si `.milestones/config.yml` trae `milestone_sync.enabled:
true`, ejecutar `milestone-sync.sh check <root> <slug>` antes de comparar
checkbox vs evidencia. Si `remote-newer`/`diverged` → otro miembro avanzó el
milestone; adoptar primero la versión canónica (con aviso) y hacer la recovery
sobre esa base, no sobre la copia local obsoleta. Ver
[`git-sync.md`](git-sync.md) §4.

### 2. Detectar señales de "sesión cortada"

- Snapshot `> 2h` desde `updated`
- Último `## Contexto` del milestone sin campo "Estado" explícito
- Subtarea con `[>]` pero snapshot `archivos clave` vacío
- Subtarea con `[~]` pero sin entrada `## Contexto` de finalización

### 3. Si detectas señal → ejecutar mini-sync de recovery

- `git log --since='<timestamp-snapshot>' --name-only` → archivos tocados desde último sync
- `git status` → trabajo no-commiteado que podría ser de esta subtarea
- `grep` de símbolos/archivos del plan contra el codebase actual
- Comparar evidencia con checkbox actual:

| Checkbox | Evidencia | Acción |
|----------|-----------|--------|
| `[>]` | Archivos del plan presentes, phpcs OK, ≥1 wave pero no todas | Mantener `[>]`, actualizar nota wave counter si procede |
| `[>]` | Sin archivos/símbolos del plan | **Downgrade a `[ ]`** + aviso "abandoned session detected" |
| `[>]` | TODAS las waves/archivos presentes | **Upgrade a `[~]`** — session-end anterior se saltó el protocolo |
| `[~]` | Archivos del plan presentes y completos | Mantener `[~]` |
| `[~]` | Archivos del plan incompletos | **Downgrade a `[>]`** — marcado prematuro |
| `[x]` | Evidencia ausente | **NO downgrade automático** — alertar al usuario, sospechar merge revertido o archivo movido |

### 4. Confirmar con usuario ANTES de downgrade si hay duda

Ejemplo:
> "Detecté que 5.2 está marcada `[~]` pero faltan W3-W5 (Chart.js vendor y tests). ¿Downgrade a `[>]` o tienes las waves en otra rama/stash?"

### 5. Actualizar milestone file + snapshot

Con los resultados del recovery.

### Casos frecuentes de corte

- IDE cerrado mid-write (archivos parcialmente guardados)
- Claude interrumpido por Ctrl+C antes de refrescar snapshot
- MCP tool crash en mitad de un Edit
- Usuario cambia de tema y no vuelve a la subtarea
- Pérdida de contexto (auto-compaction truncó el `## Contexto` no persistido)

### 6. Stale claim detection (R14 — opt-in team mode)

Tras los pasos 1-5 anteriores, si team mode está activo:

1. `milestone-sync.sh claims <root> <slug>` → lista TSV `X.Y\thandle\tts` de claims activos.
2. Para cada claim CUYO `handle` coincide con tu `user_handle()`:
   - Si la edad del claim es **>2h** Y la subtarea sigue `[>]` sin evidencia en `git status` / `git log` reciente → preguntar al usuario:
     > "Tienes `X.Y` claimeada desde `<ts>` (`<Nh>` horas) sin commits recientes. ¿Sigues trabajando en ella o la libero?"
   - Si confirma "libero" → `milestone-sync.sh release <root> <slug> <X.Y>`.
   - Si confirma "sigo" → mantener; refresca `updated` para evitar el aviso en próxima sesión.
3. Para claims de OTROS miembros con edad > umbral configurado (default 24h):
   - Solo informar, NO liberar automáticamente. La decisión "liberar el claim de alguien que se olvidó" debe ser humana y explícita (`release --force`).
   - `milestone-sync.sh stale <root> <slug>` lista claims viejos.

El stale check evita el problema "máquina se cuelga con claim activo, nadie puede continuar". El claim no es prisión permanente.

### Qué evita la recovery

Dos fallos críticos:
- (a) Pensar que una subtarea está hecha cuando no lo está.
- (b) Empezar de cero trabajo que ya existe.

---

## Regla de oro combinada

R11 y R12 son el mismo contrato desde ambos lados: **toda sesión cierra con evidencia verificada y abre con evidencia verificada**. Si una sesión se corta sin R11, R12 lo detecta y repara. Si R11 se ejecuta correctamente, R12 confirma `✓` y no toca nada.
