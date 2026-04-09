# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Terminaste una feature en 3 conversaciones. La 4a empieza de cero porque el contexto no sobrevive.**

milestone es un tracker de desarrollo persistente que almacena el contexto completo como archivos markdown en tu proyecto. Cada hito es una capsula autocontenida: objetivo, subtareas con estado, decisiones arquitectonicas, referencias a codigo y un log de lo que se hizo y por que. Cargalo en cualquier conversacion y retoma exactamente donde lo dejaste.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Como funciona

```
Tu: "/milestone dashboard"
        |
        v
Busca el archivo del hito en .milestones/ (fuzzy match)
        |
        v
Muestra: objetivo, subtareas pendientes, decisiones, log de contexto, referencias
        |
        v
Descubre herramientas de planificacion disponibles (Plan mode, /writing-plans, /gepetto...)
        |
        v
Sugiere siguiente subtarea + ofrece unificar planes de todos los planificadores
        |
        v
Despues del trabajo: actualiza subtareas, log de contexto y referencias
        |
        v
Siguiente conversacion: /milestone dashboard → contexto completo, listo para continuar
```

## Comandos

| Comando | Descripcion |
|---------|-------------|
| `/milestone` | Lista todos los hitos con estado, progreso y links de carga rapida |
| `/milestone <nombre>` | Carga el contexto completo de un hito (fuzzy match) |
| `/milestone init <nombre>` | Crea un nuevo hito con objetivo y subtareas |
| `/milestone add <nombre> <contenido>` | Agrega subtarea, decision, nota o referencia |
| `/milestone done <nombre> <subtarea>` | Marca una subtarea como completada |
| `/milestone update <nombre>` | Actualiza contexto en bloque tras una sesion de trabajo |

## Caracteristicas clave

- **Persistente entre conversaciones** — los archivos viven en `.milestones/` y sobreviven cualquier sesion
- **Contexto autocontenido** — cada archivo tiene todo lo necesario para retomar el trabajo
- **Descubrimiento de planificadores** — detecta automaticamente las skills de planificacion instaladas y ofrece unificar sus resultados
- **Auto-status** — el estado se recalcula desde los checkboxes de subtareas
- **Fuzzy matching** — escribe "dash" para cargar "dashboard-propietario"
- **Log de contexto append-only** — registro cronologico inverso de que paso y por que
- **Skill global, datos locales** — se instala una vez, crea datos especificos por proyecto

## Que lo hace diferente

A diferencia de listas de tareas o TODOs, un milestone captura la **narrativa** del desarrollo: no solo que esta pendiente, sino que se intento, que se decidio y por que. Es la diferencia entre un checklist y un briefing.

## Seguridad

- Auditado con Skill-Guard: **92/100 GREEN**
- Sin scripts, sin llamadas de red, sin acceso MCP
- Solo lee/escribe archivos locales `.milestones/*.md`
- `allowed-tools: Read Write Edit Glob Grep`
