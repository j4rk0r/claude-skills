# Milestone Rendering Rules — `/milestone` listing

Reglas OBLIGATORIAS para renderizar el listing de `/milestone` (bloques A y B).

## (A) Tabla resumen

```
| Estado | Hito | Progreso | Actualizado | Retomar |
|--------|------|----------|-------------|---------|
| 🟡 | Dashboard Propietario | 3/7 | 2026-04-09 16:17 | `/milestone start dashboard-propietario` |
```

🟢 completado · 🟡 en progreso · 🔴 no iniciado · ⚠️ sin actividad >30 días.

Reglas:
- Nombre del hito como **texto plano**. NUNCA enlaces markdown.
- Columna "Retomar": slash command literal `/milestone start <slug>` entre backticks. NUNCA `bash ~/.claude/milestone-new-session.sh ...`.
- Columna "Progreso": `[x]`+`[~]` / total. Si hay `[~]`, indicar `N/T (M pending)`.
- Columna "Actualizado": SIEMPRE fecha + hora `YYYY-MM-DD HH:MM` (local, 24h). Viene del frontmatter `updated`. Snapshots legacy sin hora → regenerar al siguiente `/milestone update`.
- Emoji de estado en texto plano, sin enlaces.

## (B) Desglose por milestone

Debajo de (A), por cada milestone:

```
### <Nombre>
**Objetivo**: <primera línea ## Objetivo>
**Siguiente acción**: <qué toca y por qué>
**Avisos**: <bloqueos/dependencias, si aplica>

**Subtareas**:

- Fase 1 — <nombre>
  *Qué se construye en esta fase, lenguaje llano.*

  - [x] *1.1 [simple] ~~Subtarea hecha~~* [Backend]
  - [~] *1.2 [complejo] Subtarea* `⏳ pendiente aprobación (QA)` [Backend, QA]
    - Plan: `fase1-bundle.md`
    - Sub-pasos: a) ..., b) ..., c) ...
  - 👉 **[ ] 1.3 [complejo] Subtarea — siguiente** [Backend]
    - Plan: `fase1-detalle.md` (por crear)

- Fase 2 — <nombre>
  *Descripción llana de la fase 2.*

  - [ ] *2.1 [simple] Subtarea* [Backend]
```

**Comando siguiente** (pegar en nueva tab del IDE):
```
/milestone start <slug>
```

## Reglas OBLIGATORIAS del desglose

### 1. Cobertura completa
TODOS los milestones del listing llevan desglose. Si falta en el snapshot, leer `.milestones/<slug>.md` y reconstruirlo. No aceptable mostrar unos con lista y otros sin.

### 2. Énfasis visual invertido (apagar todo salvo "siguiente")
- `[x]` completada: *cursiva* + `~~tachado~~`.
- `[ ]` no iniciada: *cursiva*.
- `[>]` en curso (NUEVO): texto regular (ni cursiva ni negrita) + nota en backticks inline → `` `⚙️ W<k>/<N> code-complete` `` o `` `⚙️ en curso` ``. Pesa visual neutro, para que `👉 siguiente` siga destacando. Si una wave quedó rota, añadir `` `⚙️ W<k>/<N> · W<k+1> broken: <archivo>` ``. Etiqueta `[Dept]` fuera de los backticks.
- `[~]` pendiente de aprobación: título en *cursiva* + nota en **backticks inline** → `` `⏳ pendiente aprobación (QA)` ``. Renderiza con fondo monospace, color distinto al título. NUNCA `<sub>…</sub>` (idéntico a texto plano). Etiqueta `[Dept]` va fuera de los backticks.
- `[-]` cancelada: *cursiva* + `~~tachado~~`.
- `👉 siguiente`: TODA la línea en **negrita**, sin cursiva, sin tachado. Única que destaca. Si la "siguiente" es `[>]` (típico: subtarea en curso), combina: `👉 **[>] X.Y [complejo] <título> — W<k>/<N> code-complete — siguiente** [Dept]`. La nota backticks se omite (queda redundante con el wave counter inline en bold).
- Aviso de recovery (R12): si una subtarea aparece por downgrade automático (`[>]` → `[ ]` abandoned, o `[~]` → `[>]` marcado prematuro), añadir al final de su línea `` `⚠️ restaurado por recovery` `` en texto regular. Señala al usuario que el estado se corrigió respecto a la sesión anterior.
- Checkbox siempre fuera de cursiva/negrita.

### 3. Marca "siguiente acción" (OBLIGATORIA)
Una única subtarea lleva prefijo `👉 ` antes del checkbox y palabra `siguiente` al final. Por regla 2, única en **negrita**. Elección:
- Si hay `[~]` no bloqueadas → primera en orden `X.Y`.
- Si todas `[~]` bloqueadas → primera accionable o primera `[ ]`.
- Si no hay `[~]` pero sí `[ ]` → primera `[ ]`.
- Si todas `[x]` → "milestone completo".

### 4. Bloque `/milestone start` debajo
Tras subtareas, bloque de código una línea para copiar-pegar en **nueva tab del IDE**:
```
**Comando siguiente** (pegar en nueva tab del IDE):
```
```
/milestone start <slug>
```
NUNCA `bash ~/.claude/milestone-new-session.sh ...` aquí.

### 5. Planes de `[complejo]` (OBLIGATORIO si existen)
- Con plan: línea anidada `- Plan: \`<nombre>.md\``.
- Con sub-pasos en plan: `- Sub-pasos: a) ..., b) ..., c) ...`.
- Sin plan aún: `- Plan: (por crear)`.
- `[simple]` no llevan bloque.

### 6. Sin horas
En líneas de subtarea ni nombres de fase. Ver "Hours on subtasks" en SKILL.md.

### 7. Numeración `X.Y` OBLIGATORIA
Justo después del checkbox, dentro del énfasis tipográfico (cursiva/negrita según regla 2).

### 8. Agrupación
Por fases si el milestone las tiene; si no, lista plana `1`, `2`, `3`.

### 9. Checkbox visible
`[ ]`/`[~]`/`[x]`/`[-]` siempre, fuera de cursiva/negrita.

### 10. Complejidad
`[simple]` o `[complejo]` tras la numeración.

### 11. Departamentos (OBLIGATORIO en TODA subtarea)
Línea termina con `[Dept1, Dept2, ...]`. Nunca omitir.

Departamentos válidos (literales exactos):
- `Frontend` — JS, AJAX, interacción cliente, behaviors
- `UX/UI` — diseño Figma, skeletons, jerarquía visual, flujos
- `Backend` — PHP, servicios, controllers, forms, routing, cache, DI
- `QA` — tests PHPUnit, funcionales, smoke, validación manual
- `Sitebuilding` — config Drupal UI (permisos, rutas, menús, content types)
- `CTO` — arquitectura, revisión plan, aprobación PR, merge

Formato exacto: ` [Backend, QA]` al final, espacio antes de `[`, fuera de cursiva/negrita/backticks. Múltiples deptos en orden de peso.

### 12. Descripción breve de fase (OBLIGATORIO con fases)
Justo debajo del título de la fase, SIN línea en blanco entre título y descripción, una línea de resumen en lenguaje llano.

Formato:
- SIN prefijo ("Resumen sencillo:", "Descripción:" → prohibido).
- SIN blockquote (`>` prohibido — rompe ritmo visual).
- En *cursiva*, una sola línea, máx ~140 chars.
- Indentada al mismo nivel que subtareas (2 espacios).

**Espaciado OBLIGATORIO**:
- Línea en blanco ANTES de cada título de fase, **incluida la primera** (entre `**Subtareas**:` y `- Fase 1 — …`).
- NINGUNA línea en blanco entre título de fase y su descripción.
- Línea en blanco entre descripción y primera subtarea.
- Línea en blanco entre fases (consecuencia del primer punto).

Propósito: un humano no técnico (CTO, cliente) debe entender el "para qué" de cada fase sin leer nombres técnicos. Las subtareas son el "cómo".

Contenido:
- Evitar jerga del stack salvo imprescindible.
- No repetir el nombre de la fase — enriquecerlo.
- No listar subtareas ni números.
- Si lista plana (sin fases), no aplica.
- Si ya existe en `.milestones/<slug>.md`, usar esa; si no, generar y guardar al siguiente `/milestone update`.

## Por qué el desglose va en el listing

Objetivo: el usuario decide siguiente acción SIN ejecutar `/milestone <nombre>`. Con snapshots en contexto, completar desglose es barato. Si un snapshot no trae subtareas, está mal generado — regenerar, no omitir.

## Checkpoint >3 milestones en progreso
Advertir: dispersión reduce calidad. Sugerir priorizar.
