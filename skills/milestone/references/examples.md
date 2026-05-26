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

## Ejemplo 5 — Claim atómico R14 (team mode, dos miembros)

Demuestra: claim en sesión origen → otra persona intenta la misma subtarea → already-claimed → handover vía release --force.

```
[15:01 — Pedro]
User: "vamos con 1.4 de dashboard"

Claude (sesión origen Modo A, team mode detectado):
  [/milestone update dashboard → snapshot refresh + push a develop]
  [milestone-sync.sh check → up-to-date]
  [milestone-sync.sh claims → lista vacía]
  [proponer claim de 1.4 a Pedro]
  [milestone-sync.sh claim ./ dashboard 1.4]
  ✓ Subtarea 1.4 claimeada en `develop` por Pedro Luis Roman de la Calle (j4rk0r) · 2026-05-26 15:01
    → otros miembros la verán como bloqueada hasta que termines.

  Pega en nueva ventana del plugin:
  /milestone start dashboard

[15:02 — Ana, en otra máquina, otro Claude]
User: "voy con 1.4 de dashboard"

Claude (sesión origen Modo A):
  [/milestone update dashboard]
  [milestone-sync.sh check → remote-newer → pull adoptado]
  [milestone-sync.sh claims → 1.4 claimeada por Pedro Luis Roman de la Calle (j4rk0r) desde 15:01]
  ⚠️ 1.4 ya está en curso por Pedro Luis Roman de la Calle (j4rk0r) desde hace 1 minuto.
     Otra subtarea libre que puedo proponer: 1.5, 2.1, 2.3.
     Si necesitas que Ana coja 1.4 en su lugar → /milestone release dashboard 1.4 --force
     (recomendado: avisarle a Pedro antes).

User: "voy con 1.5 entonces"

Claude:
  [milestone-sync.sh claim ./ dashboard 1.5]
  ✓ Subtarea 1.5 claimeada por Ana Pérez (ana). Trabajo en paralelo sin colisión.

[16:30 — Pedro cierra sesión sin terminar 1.4]
Claude (R11 session-end):
  [git status → archivos parciales: StripeSyncService.php, sin tests]
  [phpcs ok pero scope incompleto — quedó W2/4]
  [Edit milestone: 1.4 sigue [>] (claim 🔒 se mantiene) con nota W2/4 code-complete]
  [Edit `## Contexto`: progreso, próximo paso W3]
  [refresh snapshot]
  [milestone-sync.sh push → pushed a develop]
  ✓ Cierre limpio. 1.4 sigue claimeada por ti para mañana.

[Día siguiente 10:00 — Pedro vuelve]
User: "/milestone start dashboard"

Claude (Modo B, snapshot >2h → R12 + R14 stale check):
  [milestone-sync.sh check → up-to-date]
  [milestone-sync.sh claims → 1.4 claimeada por Pedro Luis Roman de la Calle (j4rk0r) desde ayer 15:01]
  [edad del claim: ~19h — bajo umbral 24h, no es stale crítico]
  📍 Tienes 1.4 reservada desde ayer 15:01 (W2/4). ¿Continuamos?
```

## Ejemplo 6 — Handover legítimo con release --force

Demuestra: Pedro se va de vacaciones con un claim activo; Ana lo asume con la conversación adecuada.

```
[Slack interno]
Pedro: "Me voy 2 semanas, dejo 1.4 a medias. Ana, ¿la coges? Está en W2/4."
Ana: "Sí, la sigo. Lo libero y la claimeo a mí ahora."

[Ana en su máquina]
User: "voy a coger 1.4 que dejó Pedro"

Claude:
  [milestone-sync.sh check]
  [milestone-sync.sh claims → 1.4 claimeada por Pedro Luis Roman de la Calle (j4rk0r)]
  ⚠️ 1.4 la tiene Pedro. Confirmas handover legítimo (avisado por Slack)?

User: "sí, releásala y claimea a mi nombre"

Claude:
  [milestone-sync.sh release ./ dashboard 1.4 --force]
  ✓ 1.4 liberada (release forzado por handover).
  [milestone-sync.sh claim ./ dashboard 1.4]
  ✓ 1.4 ahora claimeada por Ana Pérez (ana) · 2026-06-09 10:15
  [Edit `## Contexto` con justificación del --force]
  [milestone-sync.sh push]

  En develop quedan los commits:
  - chore(milestone): release dashboard 1.4 by Ana Pérez (ana)
  - chore(milestone): claim dashboard 1.4 by Ana Pérez (ana)

  Trazabilidad permanente del handover.
```

## Lecciones condensadas

- **R12 siempre primero** al tocar un milestone con snapshot >2h.
- **R11 siempre último** al cerrar sesión con código.
- **Aprobación ≠ QA**: "apruebo" significa "procede con el cierre", pero QA aún es obligatorio antes de `[x]`.
- **Wave counter en la línea** (`— W<k>/<N>`) es OBLIGATORIO en estado `[>]` multi-wave.
- **Modo A vs B** solo se distingue por antigüedad del snapshot y historial de la sesión actual.
- **R14 claim en sesión origen** (no en ventana nueva) — cierra la ventana de carrera entre ver el comando y abrir la nueva ventana.
- **release --force = avisar primero** — el sistema técnico no sustituye la comunicación humana en handovers.
