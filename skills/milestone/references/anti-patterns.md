# Anti-patterns — NEVER list (full reference)

**Load when**: duda sobre si una acción concreta es aceptable, revisión de cambios antes de commit, o cuando `/milestone sync` detecta posibles violaciones. **Do NOT load** en list / load / update operaciones rutinarias.

Los 3 más críticos están repetidos en SKILL.md. Este archivo contiene los 17 completos con contexto ampliado.

## Estado y evidencia

1. **NEVER mark `[x]` without explicit human approval post-QA.**
   "pasa a la siguiente" / "hemos terminado" / "ok" / "listo" son **NO** aprobación. Solo "apruebo X.Y" / "marca como terminada" / "confirmed" cuentan. QA fallida → se queda en `[~]`, nunca revierte a `[ ]`.

2. **NEVER leave `[ ]` if code already fulfills "done".**
   Oculta trabajo, provoca reimplementación, confunde a la siguiente sesión. Promover a `[>]` (evidencia parcial) o `[~]` (code-complete) sobre evidencia; el usuario aprueba a `[x]`.

3. **NEVER flip checkbox state based on intent.**
   Solo avanzar estado TRAS verificar evidencia en disco (grep confirma símbolo nuevo/ruta/método, git status lista el archivo, phpcs/test pasa). "Voy a empezar 5.2 W2" NO es evidencia para `[>]`. "Creé el template y pasó phpcs" SÍ. Previene progreso fantasma cuando se corta la sesión mid-work.

4. **NEVER close a session with code changes without executing the session-end protocol (R11).**
   Sin cerrar estado, el próximo start hereda drift. Protocolo: verificar evidencia → Edit milestone → entrada `## Contexto` → refresh snapshot.

5. **NEVER trust checkbox state without evidence cross-check when snapshot antigüedad > 2h** o cuando el último `## Contexto` carece de cierre limpio.
   Ejecutar mini-sync de recovery (R12) antes de usar el estado.

## Lectura y tokens

6. **NEVER read both memory snapshot AND `.milestones/<slug>.md`** si el snapshot suffices.
   Archivo completo = ~1.500 tok; snapshot = ~100 tok. En una conversación de 40 mensajes, desperdicio 5-10x (el contexto crece cuadráticamente por tool call).

7. **NEVER invent data absent from snapshot.**
   Si falta info de subtarea → regenerar snapshot o leer `.milestones/`, no fabricar.

## Rendering

8. **NEVER use `<sub>…</sub>` for pending-approval notes.**
   Renderiza idéntico a texto plano — sin distinción visual. Usar backticks inline `` `⏳ pendiente aprobación (QA)` `` (fondo monospace).

## Ejecución y sesiones

9. **NEVER skip pre-start sync before `/milestone start`.**
   Ventana nueva solo ve el snapshot; snapshot obsoleto = contexto incorrecto = sesión desperdiciada. Pre-start sin excepciones.

10. **NEVER run `bash ~/.claude/milestone-new-session.sh` inside an IDE** (VS Code, Cursor).
    Crea sesión terminal huérfana fuera del contexto del IDE. Mostrar solo el texto `/milestone start <slug>` para pegar en ventana nueva del plugin.

## Estructura y numeración

11. **NEVER put hours on subtask lines.**
    Las estimaciones decaen en cuanto arranca el trabajo; pertenecen a los planes (`.milestones/plans/`) o a `## Contexto`.

12. **NEVER renumber subtasks when plans reference old numbers.**
    `.milestones/plans/<slug>-1.3.md` se rompe si `1.3` pasa a ser `1.2`. Comprobar grep de `<slug>-<old>.md` antes de renumerar; si hay planes afectados, renombrar plan + actualizar referencias en `## Contexto` en el mismo Edit.

13. **NEVER mix languages within a single milestone.**
    El parser de snapshot busca marcadores en un idioma (`En curso`, `Pendiente aprobación`, `No iniciadas`); mezclar ES/EN rompe detección y muestra "(ninguna)" cuando hay subtareas reales. Elegir idioma al `init` y mantenerlo.

## Archivos y ciclo de vida

14. **NEVER delete `.milestones/<slug>.md` to "reset" a milestone.**
    Borra contexto histórico irrecuperable (`## Contexto`, decisiones). Si hay corrupción → cargar `errors.md` y reparar frontmatter/sección dañada. Cancelar milestone → marcar todas las subtareas `[-]` + archivar moviendo a `.milestones/archive/` preservando el archivo.

## Git-sync (R13 — team mode)

15. **NEVER commit `.milestones/<slug>.md` en una rama de código/feature.**
    Causa el caos duplicado: conflictos de merge en ese archivo y listas de tareas divergentes por rama. El milestone se sincroniza SOLO contra la rama canónica vía worktree aislado (`milestone-sync.sh`, R13 → [`git-sync.md`](git-sync.md)). En el repo del proyecto, `.milestones/` no debe entrar en PRs de código.

16. **NEVER auto-pushear el milestone saltándose el guard de seguridad o las reglas de confirmación outward.**
    Si el push se bloquea o falla → dejar el commit en el worktree y avisar con el comando exacto a ejecutar; nunca silenciar el fallo, nunca reintentar en bucle.

17. **NEVER bloquear ni abortar la operación de milestone si el git-sync no está disponible** (sin git/remoto/rama canónica, o `milestone_sync` ausente en config).
    Degrada a no-op silencioso — la skill sigue siendo portable y zero-dependency. R13 es estrictamente aditivo.

## Claim atómico (R14 — team mode)

18. **NEVER editar la anotación `🔒 <handle> · ts` a mano en el archivo del milestone.**
    El claim es atómico en `<branch>` y se construye / valida exclusivamente vía `milestone-sync.sh claim` / `release`. Editarla a mano:
    - rompe la comparación de claimer (`extract_claim_handle`) si cambias el formato;
    - puede dejar `[>]` sin anotación `🔒` o anotación `🔒` con `[~]`/`[x]` (estado inconsistente);
    - NO genera commit auditable en `develop` (la trazabilidad se pierde).
    Para liberar/cambiar un claim → `release [--force]`. Para reasignar handover → `release --force` (notificando al claimer original).

19. **NEVER tocar código de una subtarea sin claim previo cuando team mode está activo.**
    R14 obliga a que el primer paso del trabajo sea `milestone-sync.sh claim`. Tocar código antes deja el milestone mintiendo (otros la ven libre y pueden duplicar trabajo). Si descubres a mitad de sesión que olvidaste claimear y la subtarea sigue `[ ]` en `develop` → `claim` ahora y deja constancia en `## Contexto` ("claim retroactivo tras X archivos ya tocados").

20. **NEVER ejecutar `release --force` sin avisar al claimer original.**
    `--force` está pensado para handover legítimo (abandono, vacaciones, máquina caída). Forzar release sin avisar al claimer convierte un sistema de coordinación en una guerra silenciosa. Si necesitas forzar:
    - Avisa antes por el canal habitual del equipo (Slack, email, chat).
    - Deja entrada en `## Contexto`: "release forzado de X.Y a <claimer> por <razón>".
    - El claimer original recibirá `not-claimed` la próxima vez que intente operar y verá el `## Contexto`.

## Por qué importa esta lista

Estos 17 NEVER resumen los fallos observados en más de 1.400 sesiones: drift entre checkbox e implementación, contexto perdido al cerrar sesión, tokens desperdiciados por doble lectura, aprobaciones ambiguas que marcan `[x]` cuando solo era "continúa", y —en equipo— milestones duplicados por rama o pushes silenciados. La lista no es opinión — es cicatriz.
