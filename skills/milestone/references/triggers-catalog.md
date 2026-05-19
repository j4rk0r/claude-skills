# Triggers Catalog — frases que deben invocar milestone

Catálogo exhaustivo de señales lingüísticas que deben disparar una operación de milestone. Consultar cuando haya duda sobre si una petición ambigua justifica cargar el skill.

## Principios

- **Duda razonable → cargar**. El coste de cargar milestone y no usarlo (~2k tok) es menor que el coste de no cargarlo y perder contexto multi-sesión (snapshot obsoleto, trabajo duplicado, decisiones olvidadas).
- **Mencionar no es pedir**. "ese milestone está mal" describe un hecho, no pide acción. Solo cargar si la frase implica una operación (crear, listar, actualizar, cerrar).
- **Verbo > sustantivo**. "retomamos X" es más fuerte que "X es un milestone".

## Triggers fuertes (cargar siempre)

### Discovery / load context
- "dónde lo dejé" / "dónde lo dejamos" / "where did we leave off"
- "qué hicimos la última vez" / "what did we do last time"
- "retomamos X" / "retomar X" / "resume X"
- "seguimos con X" / "continuemos con X" / "let's continue X"
- "estado del proyecto" / "status del proyecto" / "cómo va X"
- "qué falta" / "qué queda" / "pendientes" / "what's left"
- "siguiente tarea" / "siguiente paso" / "next up"

### Planning
- "planear fase N" / "planificar fase N" / "plan phase N"
- "descompón X en subtareas" / "break X into subtasks"
- "crea un milestone" / "nuevo milestone" / "create milestone"
- "audita el proyecto" / "audit the project" / "sync milestones"

### Execution
- "arranca la X.Y" / "empieza la X.Y" / "start subtask X.Y"
- "empezamos fase N" / "arrancamos X"
- "nueva ventana para X" / "session nueva para X"

### Close
- "apruebo X.Y" / "marca X.Y como terminada" / "mark X.Y done"
- "cierra el milestone" / "close milestone X"
- "confirmed X.Y" / "done, X.Y"

## Triggers medios (cargar si hay contexto de proyecto multi-sesión)

- "fase 2" / "phase 3" — si el proyecto ya tiene fases definidas
- "bloqueado en X" / "stuck on X" — si X es identificable como subtarea
- "ya hice X" / "completé X" — candidato a promover `[ ]`→`[~]` via `/milestone update`
- "volvamos a X" — si X ya existe como milestone

## Triggers débiles (evaluar, no cargar por defecto)

- "proyecto" solo → demasiado genérico
- "tarea" solo → usar TodoWrite
- Pregunta factual sobre código ("cómo funciona X") → lectura directa, no milestone

## Anti-triggers (NO cargar aunque aparezca la palabra)

- "ese milestone está mal redactado" → comentario, no operación
- "milestone 2026 Q2 OKR" → otro dominio (OKR), no development tracking
- "milestone release v3.2" → release management, usar otro skill si existe
- Documentación/README mencionando milestone → lectura, no operación

## Señales contextuales de refuerzo

Si alguna de estas aparece junto a un trigger débil, promover a trigger medio:

- Carpeta `.milestones/` existe en el proyecto
- `MEMORY.md` del proyecto ya tiene entradas `milestone_*.md`
- La conversación anterior mencionó un milestone específico
- Hay un `.milestones/config.yml` detectable

## Falsos positivos conocidos

- "milestone" en nombres de productos (GitHub Milestones) — contexto API/UI, no operación local.
- "fase lunar" / "fase de sueño" / "phase shift" — fase en sentidos no-proyecto.
- "seguimos con la reunión" — seguimos ≠ retomamos trabajo multi-sesión.

## Qué hacer cuando disparas

1. Cargar SKILL.md milestone (si no está ya en contexto).
2. Decidir qué comando aplica:
   - "dónde lo dejé" → `/milestone <nombre>` o `/milestone` si no especifica.
   - "planear X" → `/milestone init` si es nuevo, `/milestone update` si existe.
   - "apruebo X.Y" → `/milestone done <slug> X.Y`.
3. Si es `init` o `sync`, verificar antes `config.yml`.
4. Si es `start`, no olvidar pre-start sync obligatorio (R8).
