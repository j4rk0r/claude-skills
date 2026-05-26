# States — 5-state subtask model (full reference)

**Load when**: vas a modificar checkboxes de subtareas (init, sync, update, done, session-end), o cuando detectas una transición ambigua. **Do NOT load** para `/milestone` list u operaciones que solo renderizan.

## Tabla completa

| Estado | Significado | Condición para entrar | Quién marca |
|--------|-------------|------------------------|-------------|
| `[ ]` | No iniciada — sin evidencia de código | Default al crear subtarea | init / sync |
| `[>]` | **En curso** — trabajo arrancado, subtarea NO code-complete (≥1 wave/archivo verificado, faltan otras) | Grep/git status confirma ≥1 archivo tocado Y faltan waves/archivos planeados | update / sync / session-end |
| `[~]` | Code-complete, **pendiente aprobación** — todo el alcance implementado y verificado | Todas las waves/archivos del plan existen Y phpcs/test pass según `project_type` | update / sync / session-end |
| `[x]` | Completada + **explicitly approved** post-QA | `/milestone done` con aprobación explícita | done only |
| `[-]` | Cancelada | User decision | user only |

## Transiciones legales

Estado sigue a la evidencia, nunca a la intención:

```
[ ] ─(1ª evidencia verificada)─▶ [>] ─(todas las waves done)─▶ [~] ─(aprobación explícita)─▶ [x]
                                  │                             │
                                  └──(cancelación)──▶ [-]       └──(cancelación)──▶ [-]
```

- Claude promotes `[ ]` → `[>]` → `[~]` solo tras verificar evidencia en disco (grep, git status, phpcs/tests).
- Solo usuario promueve `[~]` → `[x]` con aprobación explícita ("apruebo X.Y" / "marca como terminada" / "confirmed").
- Cualquier `[>]` o `[~]` → status global del milestone `in-progress`.
- **Downgrade permitido** en recovery (R12): `[>]` → `[ ]` o `[~]` → `[>]` si la evidencia no coincide con el checkbox.

## Edge cases

- **Dependencia en cadena**: si `Y.B` depende de `Y.A` que está `[~]` (no aprobada), NO arrancar `Y.B` sin aprobar `Y.A` primero. Riesgo: el rework de `Y.A` invalida `Y.B`. Excepción: el usuario autoriza explícitamente arrancar en paralelo asumiendo el riesgo.
- **Cancelación con trabajo parcial**: marcar `[-]` cuando ya hay código merged — documentar en `## Contexto` qué archivos quedaron modificados y si son reversibles, reusables en otra subtarea, o deuda técnica. NUNCA borrar código silenciosamente al cancelar.
- **Regresión detectada en `[x]` aprobada**: no revertir a `[~]` ni a `[ ]` — crear subtarea nueva (fix/rework) con referencia a la `X.Y` original. La subtarea `[x]` es histórica; el fix es trabajo nuevo.
- **Wave parcial en subtarea multi-wave**: la subtarea queda `[>]` con nota explícita `— W<k>/<N> code-complete` en la línea. Promover a `[~]` SOLO cuando `k == N`. NUNCA `[ ]` con trabajo parcial merged.
- **Session crash mid-wave**: si se interrumpe la sesión mientras implementas W3 (con W1+W2 hechas), el estado correcto al reanudar es `[>]` con nota `— W2/<N> code-complete` (no W3 porque W3 no terminó). Recovery (R12) detecta esto.
- **`[>]` sin evidencia detectado** (abandoned start): `[>]` marcado pero grep no encuentra los símbolos/archivos esperados → downgrade a `[ ]` con aviso "abandoned session detected, estado restaurado".

## Reglas de oro

1. Estado nunca antes que la evidencia.
2. Downgrade explícito > checkbox incorrecto silencioso.
3. Multi-wave → siempre nota `— W<k>/<N>` visible en la línea.
4. Aprobación ≠ "ok / sigamos / listo" — solo frases explícitas mueven a `[x]`.

## PR en vuelo (R13 — team mode)

Una subtarea `[~]` cuyo trabajo está en un PR abierto lleva la anotación inline
`` `⏳ PR #<n>` `` al final de la línea (mismo estilo backticks que la nota de
pendiente-aprobación; ver anti-pattern #8). **No es un estado nuevo**: `[~]` ya
es "code-complete, pendiente de aprobación" y el PR es el vehículo de esa
aprobación. Parser-safe: no cambia el checkbox ni los marcadores de sección
(anti-pattern #13). Al mergear + aprobación humana explícita → `/milestone done`
→ `[x]` (la anotación se retira en ese Edit). Lo estampa
`milestone-sync.sh stamp` — ver [`git-sync.md`](git-sync.md) §7.

## Claim atómico (R14 — team mode)

Cuando team mode (R13) está activo, **arrancar una subtarea genera un claim
atómico en la rama canónica antes de tocar nada de código**. Una subtarea no se
pone `[>]` sólo porque haya evidencia de archivos tocados — primero se *reserva*
con un commit dedicado en `<branch>` que pone `[ ]`→`[>]` y añade la anotación
inline `` `🔒 <handle> · YYYY-MM-DD HH:MM` `` en la línea. Mismo estilo
backticks que `` `⏳ PR #<n>` ``, parser-safe.

```
- [>] 1.1 [simple] Canal smee.io ... — `🔒 j4rk0r · 2026-05-26 14:45` [DevOps]
```

**Metadatos extraíbles de la anotación**: `claimer` (handle antes de `·`) y
`claimed_at` (timestamp). No vive en el frontmatter — vive en la propia línea
para que el render no necesite leer otra fuente.

**Estado vs claim**:

- `[>]` SIN anotación `🔒` → en curso por trabajo verificado (modelo clásico,
  válido en R13 sin team mode o en repos sin git).
- `[>]` CON anotación `🔒` → en curso y *reservado* explícitamente. Cualquier
  otro miembro que ejecute `/milestone start` ve la anotación y NO puede
  claimear la misma subtarea (el helper devuelve `already-claimed:<handle>`).
- `[>]` con waves (`⚙️ W<k>/<N>`) + `🔒` → coexisten. La anotación va siempre la
  última, antes de `[Dept]`.

**Quién marca**:

- Claude promueve `[ ]` → `[>]` con anotación `🔒` SOLO vía
  `milestone-sync.sh claim` (no editando el archivo a mano). El helper
  garantiza atomicidad: un solo `git push --ff` gana la carrera, el segundo
  recibe `race-lost:<handle>` y debe elegir otra subtarea.
- `[>]` (con 🔒) → `[ ]` vía `milestone-sync.sh release` (mismo claimer, o
  `--force`). Promueve a `[~]` cuando el trabajo está code-complete (la
  anotación 🔒 se retira en ese Edit).

**Reglas duras**:

1. En team mode (R13), **prohibido tocar código de una subtarea sin claim
   previo**. El `claim` es el primer paso del trabajo, antes de la primera línea
   de código.
2. El claim NO requiere confirmación del usuario (sólo toca `.milestones/` en
   la rama canónica vía worktree). El commit del **código** sigue requiriendo
   confirmación (regla global "PR — confirmación explícita").
3. Si `milestone_sync.enabled` es false o no hay remoto, el claim degrada a
   no-op silencioso: el modelo clásico `[ ]` → `[>]` (sin 🔒) sigue siendo
   válido, basado en evidencia. R14 no rompe nada.

Detalle del flujo, carrera y degradación → [`git-sync.md`](git-sync.md) §11.
