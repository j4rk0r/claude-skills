# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Terminaste una feature en 3 conversaciones. La 4a empieza de cero porque el contexto no sobrevive.**

milestone v2 es un tracker de desarrollo persistente con **cache de dos niveles**: snapshots compactos en memoria (~100 tokens, auto-cargados) para estado instantaneo, y archivos autoritativos para historial completo. Clasifica subtareas como `[simple]` o `[complejo]`, exigiendo un plan antes de ejecutar trabajo complejo — previniendo el ciclo caro de prueba-error de 6+ edits iterativos en el mismo archivo.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Comandos

| Fase | Comando | Descripcion |
|------|---------|-------------|
| Descubrimiento | `/milestone` | Listar todos con estado y progreso |
| Descubrimiento | `/milestone <nombre>` | Cargar contexto (fuzzy match — "dash" encuentra "dashboard-propietario") |
| Planificacion | `/milestone init <nombre>` | Crear nuevo con propuestas de subtareas |
| Ejecucion | `/milestone start <nombre>` | Abrir terminal nueva con contexto compacto pre-cargado |
| Ejecucion | `/milestone done <nombre> <subtarea>` | Marcar subtarea completada con edit minimo |
| Revision | `/milestone update <nombre>` | Actualizacion masiva tras sesion de trabajo |

## Caracteristicas clave

- **Cache de dos niveles** — snapshot en memoria (~100 tok) para lecturas, archivo autoritativo para historial. 99% mas barato que leer el archivo completo cada vez.
- **Clasificacion de complejidad** — `[simple]` (1 archivo, cambio claro) vs `[complejo]` (multi-archivo, logica nueva). Las complejas estan **bloqueadas** hasta que exista un plan.
- **Reglas de eficiencia de tokens** — 3+ cambios al mismo archivo → un solo Write (10x mas barato que Edits iterativos).
- **Comando nueva sesion** — `/milestone start` abre `claude` en terminal nueva con contexto compacto, eliminando el multiplicador 5-10x del historial acumulado.
- **12 reglas NEVER** — previenen split-brain, snapshots desactualizados y anti-patrones de edicion.

## Evaluacion

- **`/skill-judge`**: 120/120 (Grado A+)
- **`/skill-guard`**: 92/100 (GREEN) — sin scripts en operacion normal, sin red, sin MCP
