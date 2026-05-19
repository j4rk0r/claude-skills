# Snapshot Format — hot memory cache

**Load when**: vas a crear o regenerar un snapshot de memoria, o detectas snapshot corrupto / en formato obsoleto. **Do NOT load** en list / update donde el snapshot ya existe y es válido.

## Destino del archivo

```
~/.claude/projects/$(pwd | sed 's|/|-|g; s|^-||')/memory/milestone_<slug>.md
```

Ejemplo para `/Applications/docker/Oltex`:
```
~/.claude/projects/-Applications-docker-Oltex/memory/milestone_dashboard-propietario.md
```

Crear pointer en `MEMORY.md` del mismo directorio si es nuevo:
```
- [milestone_<slug>.md](milestone_<slug>.md) — <hook line compacto>
```

## Formato compacto (por defecto)

```
**<Nombre>** | <status> | <done>/<total> (<active> en curso, <pending> pendientes) | <YYYY-MM-DD HH:MM>
Objetivo: <primera línea>
En curso [>]: <lista X.Y con nota W<k>/<N> o "(ninguna)">
Pendiente aprobación [~]: <lista X.Y o "(ninguna)">
No iniciadas [ ]: <lista X.Y o "(ninguna)">
Último avance: <primera línea del Contexto más reciente>
Archivos clave: <basenames, máx 6>
```

### Ejemplo real

```
**Dashboard Propietario** | in-progress | 3/7 (1 en curso, 2 pendientes) | 2026-04-18 17:32
Objetivo: Panel propietario multi-cliente con MenuTree dinámico.
En curso [>]: 1.4 (W3/4)
Pendiente aprobación [~]: 1.2, 1.6
No iniciadas [ ]: 1.5, 1.7
Último avance: W3 StripeSyncService implementada, phpcs OK.
Archivos clave: StripeSyncService.php, SubscriptionEntity.php, dashboard.twig
```

### Costes

- **~100 tok por snapshot** vs ~1.500 tok leyendo `.milestones/<slug>.md` completo.
- En una conversación de 40 mensajes, ahorro ≥ 50k tok (el contexto crece cuadráticamente por tool call).

## Formato expandido (recomendado para >6 subtareas o con fases)

Usar cuando el milestone tiene fases (grupos) o más de 6 subtareas. Permite renderizar el bloque (B) del listing sin leer `.milestones/<slug>.md`.

```
**<Nombre>** | <status> | <done>/<total> (<active>▶, <pending>⏳) | <YYYY-MM-DD HH:MM>
Objetivo: <primera línea>
Siguiente: <acción sugerida>

### Fase 1 — <nombre>
- [x] **1.1** [simple] Subtarea [Backend]
- [~] **1.2** [complejo] Subtarea — `⏳ pendiente aprobación (QA)` [Backend, QA]
- [>] **1.3** [complejo] Subtarea — W2/3 code-complete [Backend]

### Fase 2 — <nombre>
- [ ] **2.1** [complejo] Subtarea [Backend, APP]
- [ ] **2.2** [simple] Subtarea [Diseño]

Último avance: <primera línea del Contexto más reciente>
Archivos clave: <basenames, máx 6>
```

### Cuándo usar expandido vs compacto

| Escenario | Formato |
|-----------|---------|
| ≤6 subtareas, lista plana | Compacto |
| >6 subtareas o ≥2 fases | Expandido |
| Milestone muy activo (cambios diarios) | Expandido (evita re-read de `.milestones/`) |
| Milestone dormido (sin cambios >30 días) | Compacto |

## Reglas de regeneración

- **Cada write a `.milestones/<slug>.md`** → refrescar snapshot en el mismo Edit/Write.
- **No duplicar información** entre snapshot y archivo auth: el snapshot es vista materializada; el archivo es fuente.
- **Timestamp obligatorio** en la primera línea (formato `YYYY-MM-DD HH:MM`, hora local 24h).
- **Parser del snapshot** busca marcadores en un idioma fijo (`En curso`, `Pendiente aprobación`, `No iniciadas`). Si el milestone está en inglés, usar (`In progress`, `Pending approval`, `Not started`) — no mezclar.

## Qué NO va en el snapshot

- Historial completo de `## Contexto` (solo última línea).
- Decisiones arquitectónicas antiguas (viven en `.milestones/`).
- Planes de subtareas (viven en `.milestones/plans/`).
- Referencias externas detalladas (tickets, Figma, docs) — solo en `.milestones/`.

El snapshot responde a "¿qué miro primero al abrir sesión?". Cualquier dato que no ayude a esa pregunta va al archivo auth, no al snapshot.
