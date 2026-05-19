# Examples — flujos end-to-end

**Load when**: dudas sobre cómo encajan los comandos en un flujo real, o primer uso de R11+R12 en un milestone activo. **Do NOT load** en operaciones rutinarias donde el flujo es obvio.

## Ejemplo 1 — Sesión end-to-end con R11+R12

Demuestra: discovery → recovery (R12) → update → start modo A + B → implementación → session-end (R11) → aprobación → done.

```
User: "qué falta en dashboard propietario"

Claude: [reads snapshot — zero reads; detecta snapshot 3h antiguo → R12]
        [ejecuta mini-sync: git log, grep de símbolos del plan]
        ⚠️ Recovery: 1.4 marcada [>] con W1+W2 según snapshot, pero grep encuentra
           W3 ya implementada en StripeSyncService.php (línea 87). Actualizo [>] W3/4.
        Dashboard Propietario — in-progress 3/7 (1 en curso, 2 pendientes aprobación)
        Siguiente: 1.4 [complejo] [>] W3/4 done, falta W4 (webhook handler) [Backend, QA]

User: "sigue con W4"

Claude: [detects IDE env → Modo A: sesión origen]
        [runs /milestone update dashboard → refreshes snapshot]
        ✓ Milestone actualizado.
        /milestone start dashboard

[user opens new IDE window, pastes]

User (new window): "/milestone start dashboard"

Claude: [detects fresh session, updated <10min → Modo B: arrancar trabajo]
        📍 Dashboard Propietario — in-progress 3/7 (1 en curso)
        Siguiente: 1.4 [>] W3/4 done → W4 webhook handler
        ¿Empezamos?

User: "sí"

Claude: [loads plan W4, implements StripeWebhookController.php, tests]
        [verifica: phpcs OK, drush cr OK, grep confirma clase+ruta]
        ✓ W4 implementada, todas las waves done.
        Estado actualizado: [>] W3/4 → [~] (pendiente tu aprobación post-QA).
        [R11 session-end: Edit milestone → [~], Contexto entry, snapshot refresh]

User: "apruebo la 1.4"

Claude: [MANDATORY loads qa-validation.md]
        [runs QA checklist backend + frontend]
        ✓ QA backend OK. ✓ QA frontend OK.
        /milestone done dashboard 1.4 → [x] marcado.
        [refreshes snapshot]
```

## Ejemplo 2 — Recovery detecta sesión abandonada

Demuestra: `[>]` sin evidencia real → downgrade a `[ ]`.

```
User: "seguimos con informes"

Claude: [lee snapshot — subtarea 5.2 marcada [>] W0/3, updated hace 18h]
        [R12 triggered por antigüedad >2h]
        [git log --since=<18h> → no hay commits relevantes]
        [grep SupportReportsProvider → no existe en el codebase]
        [git status → sin cambios locales]

        ⚠️ Recovery: 5.2 marcada [>] pero no encuentro archivos del plan.
        - Plan esperaba: SupportReportsProvider, ruta /support/reports, método reports()
        - Evidencia real: ninguno presente, sin commits, sin stash
        - Diagnóstico: sesión anterior abortada sin escribir código

        Propongo downgrade: [>] → [ ] y arrancamos limpio con el plan existente.
        ¿Confirmas?

User: "sí"

Claude: [Edit milestone: 5.2 [ ]]
        [## Contexto entry: "Recovery 2026-04-18 — downgrade 5.2 [>]→[ ] por abandoned start"]
        [refresh snapshot]
        ✓ Estado restaurado. Siguiente paso: arrancar W1 según plan.
```

## Ejemplo 3 — Recovery detecta upgrade necesario

Demuestra: `[>]` con TODAS las waves presentes → upgrade a `[~]`.

```
User: "qué queda en log errores"

Claude: [snapshot: 2.3 marcada [>] W1/2, updated hace 4h]
        [R12 triggered]
        [grep de símbolos: ErrorLogController, ruta /admin/errors, método exportCsv]
        [TODOS presentes, phpcs pass]

        ⚠️ Recovery: 2.3 marcada [>] W1/2 pero encuentro W2 completa:
        - ErrorLogController::exportCsv() (línea 142, implementada)
        - Botón export en admin/errors.twig (línea 38)
        - phpcs OK, drush cr OK

        Diagnóstico: R11 se saltó en la sesión anterior, quedó subgraduado.
        Propongo upgrade: [>] W1/2 → [~] (pendiente tu aprobación post-QA).
        ¿Confirmas?

User: "sí, apruébala ya"

Claude: [primero Edit: [>]→[~] + Contexto entry]
        [NO marcar [x] — "apruébala ya" es aprobación pero requiere QA]
        [MANDATORY loads qa-validation.md]
        [runs QA]
        ✓ QA OK.
        /milestone done log-errores 2.3 → [x]
```

## Ejemplo 4 — Wave parcial multi-wave

Demuestra: cierre de sesión tras completar 2 de 4 waves.

```
User: "implementa W1 y W2 de 1.4"

Claude: [plan: 1.4 tiene 4 waves. W1 = schema, W2 = sync service]
        [implementa W1: migration + entity fields]
        [verifica: drush updb OK, schema correcto]
        [implementa W2: StripeSyncService::syncSubscriptions()]
        [verifica: phpcs OK, unit test pasa]
        [R11 session-end]
        ✓ W1+W2 implementadas. W3+W4 pendientes.
        Estado: [ ] → [>] — W2/4 code-complete
        [Edit milestone: "- [>] **1.4** [complejo] Integración Stripe — W2/4 code-complete [Backend, QA]"]
        [Contexto entry: archivos tocados, próximo paso = W3 webhook handler]
        [refresh snapshot con "En curso [>]: 1.4 (W2/4)"]

User: "cerramos por hoy"

Claude: ✓ R11 ya ejecutado. Milestone queda [>] W2/4.
        Próxima sesión: /milestone start dashboard → W3 webhook handler.
```

## Lecciones condensadas

- **R12 siempre primero** al tocar un milestone con snapshot >2h.
- **R11 siempre último** al cerrar sesión con código.
- **Aprobación ≠ QA**: "apruebo" significa "procede con el cierre", pero QA aún es obligatorio antes de `[x]`.
- **Wave counter en la línea** (`— W<k>/<N>`) es OBLIGATORIO en estado `[>]` multi-wave.
- **Modo A vs B** solo se distingue por antigüedad del snapshot y historial de la sesión actual.
