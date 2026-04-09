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
