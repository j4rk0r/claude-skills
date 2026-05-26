# Error Handling and Edge Cases

## Table of Contents
1. [File issues](#file-issues)
2. [Fuzzy match failures](#fuzzy-match-failures)
3. [State conflicts](#state-conflicts)
4. [Scale issues](#scale-issues)

---

## File issues

| Problem | Detection | Action |
|---------|-----------|--------|
| Corrupted frontmatter (missing `---`, invalid YAML) | Read fails to parse | Warn user, show raw content, offer to rebuild frontmatter from content |
| Non-milestone `.md` in `.milestones/` | No frontmatter with `name`/`status` | Skip silently in listings, never modify |
| Empty milestone file | File exists but no content | Warn user, offer to delete or reinitialize |
| Missing sections (no `## Subtareas`) | Section header not found | Add the missing section with placeholder, warn user |
| Subtask checkbox malformed (`-[] ` instead of `- [ ]`) | Regex doesn't match | Auto-fix to `- [ ]` format on read, save corrected version |

## Fuzzy match failures

| Scenario | Action |
|----------|--------|
| No match at all | List available milestones, ask user to pick |
| Multiple matches (e.g., "dash" matches "dashboard" and "dash-admin") | Show all matches with numbers, let user pick |
| Exact filename match + fuzzy name match = different files | Prefer exact filename match |

**Fuzzy match algorithm** (in priority order):
1. Exact filename match (without `.md`): `dashboard-propietario`
2. Exact `name` field match (case-insensitive): `Dashboard Propietario`
3. Starts-with on filename: `dash` → `dashboard-propietario`
4. Starts-with on `name` field: `Dash` → `Dashboard Propietario`
5. Contains on filename: `propie` → `dashboard-propietario`
6. Contains on `name` field: `Propie` → `Dashboard Propietario`

## State conflicts

| Problem | Detection | Action |
|---------|-----------|--------|
| Frontmatter status doesn't match subtask state | Count `[x]` vs `[ ]`, compare with `status` | Auto-fix frontmatter status, warn user |
| Subtask marked done but context has no entry for it | `[x]` exists but no matching context entry | Add context entry: "Marcada como completada (sin contexto registrado)" |
| Duplicate subtask text | Two `- [ ]` with identical text | Warn user, ask which to keep |
| `updated` date is in the future | Date > today | Fix to today's date |

## Scale issues

| Problem | Threshold | Action |
|---------|-----------|--------|
| Too many milestones | >10 active (non-completed) | Warn: "Tienes X hitos activos. Considera cerrar o fusionar algunos." |
| Too many subtasks in one milestone | >20 subtasks | Suggest splitting into sub-milestones |
| Context section very long | >50 entries | Suggest archiving old entries to a `## Contexto archivado` section |
| Milestone stale | `updated` >30 days ago, not completed | Flag in listing: "⚠️ sin actividad 30+ dias" |

## R13 / R14 — Git-sync and claim outputs

Estados que devuelve `milestone-sync.sh` y cómo manejarlos.

### check / pull / push (R13)

| Output | Significado | Acción |
|--------|-------------|--------|
| `up-to-date` | Local == canónica | Continuar |
| `local-only` | Local existe, canónica no (milestone nuevo aún sin pushear) | `push` para publicar |
| `remote-newer` | Canónica avanzó por otro miembro | `pull` antes de operar; NO pisar canónica |
| `diverged` | Local y canónica cambiaron en paralelo | Reconciliar manualmente `## Contexto` (append-only por fecha, intercalar nunca borrar); ver git-sync.md §9 |
| `pulled` | Canónica adoptada local | Continuar trabajo sobre versión fresca |
| `pushed` | Sincronizado a canónica | Confirmar al usuario en una línea |
| `commit-pending-push:<cmd>` | Commit hecho en worktree pero push bloqueado (auth, protección, red) | Mostrar `<cmd>` al usuario; **NO reintentar en bucle**; NO bloquear la operación de milestone |
| `noop:disabled` | Team mode off | Silencioso (degradación) |
| `noop:not-git` / `no-remote` / `no-branch` | Falta prerequisito git | Silencioso (degradación) |
| `noop:no-change` | El archivo no cambió | Silencioso |

### claim / release / claims / stale (R14)

| Output | Significado | Acción |
|--------|-------------|--------|
| `claimed` | Tu claim ganó el push fast-forward | Mostrar al usuario nombre + ts y arrancar trabajo |
| `already-claimed:<handle>` | La subtarea ya estaba `[>]` antes de tu fetch — otro la tiene | Mostrar quién la tiene; ofrecer elegir otra o `release --force` con aviso |
| `race-lost:<handle>` | Empezaste a la vez que otro, perdiste el FF tras rebase | Igual que `already-claimed`: el ganador queda visible |
| `not-claimable:[~]` / `[x]` / `[-]` | Estado avanzado, no es `[ ]` | La subtarea no es claimable; revisar el listing — probablemente está pendiente de aprobación o ya cerrada |
| `not-claimable:not-found` | X.Y no existe en el milestone | Typo del usuario; mostrar lista de subtareas reales |
| `not-claimer:<handle>` | Intentas release sin ser el claimer y sin `--force` | Pedir confirmación de handover + ejecutar con `--force` si procede |
| `not-claimed` | Intentas release sobre subtarea que no está `[>]` | Ya estaba libre o avanzada |
| `released` | Release exitoso | Confirmar; la subtarea vuelve a `[ ]` |
| `noop:fetch-failed` | `claim` no pudo verificar live (sin red) | Esperar conexión; NO claimear contra stale |
| `noop:no-remote-file` | El milestone aún no está publicado en `<branch>` | `push` primero |
| `noop:bad-args` | Falta argumento (ej. `claim` sin `<X.Y>`) | Corregir invocación |

### Reglas de oro para los outputs

1. **Solo `claimed` autoriza a tocar código.** Cualquier otro output → parar.
2. **`commit-pending-push` no bloquea el milestone.** El commit en worktree existe; sólo falta el push. Mostrar el comando al usuario y seguir adelante con lo demás.
3. **`race-lost` no es un fallo, es coordinación.** Es la prueba de que el sistema funciona: otro miembro ganó la carrera, no duplicas trabajo.
4. **`noop:*` siempre es no-fatal.** La skill nunca aborta una operación de milestone por un fallo de sync. Es estrictamente aditivo.
