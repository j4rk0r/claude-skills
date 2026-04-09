# Milestone File Templates

## Table of Contents
1. [New milestone template](#new-milestone-template)
2. [Context entry format](#context-entry-format)
3. [Mature milestone example](#mature-milestone-example)

---

## New milestone template

Use this exact structure when creating a milestone with `/milestone init`:

```markdown
---
name: "<Nombre del Hito>"
status: not-started
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## Objetivo
<One paragraph: what this achieves and why it matters to the project>

## Subtareas
- [ ] Subtask 1 — brief description of what "done" looks like
- [ ] Subtask 2
- [ ] Subtask 3

## Decisiones
(ninguna todavia)

## Contexto

### YYYY-MM-DD — Estado inicial
- <Current state of codebase relevant to this milestone>
- <What exists, what's missing>
- <Key constraints or dependencies>

## Referencias
- `path/to/file` — what it does and why it matters here
```

### Slug rules
- Lowercase, hyphens for spaces, no special chars
- "Dashboard Propietario" → `dashboard-propietario.md`
- "Auth & Permisos v2" → `auth-permisos-v2.md`

---

## Context entry format

Each entry in `## Contexto` follows this structure (reverse chronological — newest first):

```markdown
### YYYY-MM-DD — <Short summary of what was done>
- What was implemented/changed and why
- Key files touched: `path/to/file.php`, `path/to/other.yml`
- Decisions made (brief — detail goes in ## Decisiones)
- Blockers or pending items discovered
- Outcome of QA/review if applicable
```

### Good context entry:
```markdown
### 2026-04-09 — Implementado routing dinamico del dashboard
- Se creo `oltex_dashboard.routing.yml` con rutas derivadas del MenuTree
- Controller `DashboardController::buildPage()` renderiza links por seccion
- Se decidio no hardcodear links (ver Decisiones)
- Pendiente: permisos por rol aun no implementados
- Archivos: `oltex_dashboard.module`, `src/Controller/DashboardController.php`
```

### Bad context entry (too vague):
```markdown
### 2026-04-09 — Avances
- Se trabajo en el dashboard
- Se hicieron cambios
```

---

## Mature milestone example

This is what a milestone looks like after several work sessions:

```markdown
---
name: "Dashboard Propietario"
status: in-progress
created: 2026-04-01
updated: 2026-04-09
---

## Objetivo
Panel principal para propietarios de Oltex que muestra links de gestion
descubiertos dinamicamente desde el MenuTree de Drupal. Debe ser reusable
para otros clientes (no hardcodear links especificos de Oltex).

## Subtareas
- [x] Estructura base del modulo oltex_dashboard
- [x] Routing dinamico desde MenuTree
- [x] Controller con render por secciones
- [ ] Permisos por rol (propietario vs admin)
- [ ] Skeleton loader mientras carga
- [ ] Tests funcionales del controller
- [ ] Integracion con tema Bootstrap 5

## Decisiones
- **2026-04-07 — Links dinamicos vs hardcoded**: Se opto por descubrir links
  del MenuTree en lugar de hardcodearlos. Razon: reutilizable para otros
  clientes sin modificar codigo. Trade-off: mas complejidad en el controller.
- **2026-04-09 — Sin cache por ahora**: El MenuTree ya cachea internamente.
  No anadir cache adicional hasta que haya evidencia de que es necesario.

## Contexto

### 2026-04-09 — Implementado routing y controller
- Se creo `oltex_dashboard.routing.yml` con rutas derivadas del MenuTree
- Controller renderiza links agrupados por seccion del menu
- QA paso: las rutas responden 200 y muestran links correctos
- Pendiente: no hay control de permisos, cualquier usuario autenticado ve todo
- Archivos: `oltex_dashboard.routing.yml`, `src/Controller/DashboardController.php`

### 2026-04-07 — Analisis y estructura base
- Se analizo el admin menu de Drupal para entender que links exponer
- Se creo la estructura del modulo: .info.yml, .module, src/
- El MenuTree del admin tiene 3 niveles con 12 links relevantes
- Archivos: `oltex_dashboard.info.yml`, `oltex_dashboard.module`

### 2026-04-01 — Estado inicial
- No existia modulo de dashboard
- Propietarios accedian directamente al admin de Drupal (UX deficiente)
- Requisito del cliente: panel simplificado sin acceso al admin completo

## Referencias
- `web/modules/custom/oltex_dashboard/oltex_dashboard.info.yml` — definicion del modulo
- `web/modules/custom/oltex_dashboard/oltex_dashboard.routing.yml` — rutas dinamicas
- `web/modules/custom/oltex_dashboard/src/Controller/DashboardController.php` — controller principal
- `web/modules/custom/oltex_dashboard/oltex_dashboard.module` — hooks del modulo
```
