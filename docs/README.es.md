# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de nivel experto para Claude Code. Cada skill puntuada **A+ (120/120)** antes de publicarse.

## Instalar

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | Que hace | Puntuacion |
|-------|----------|------------|
| **[skill-advisor](../skills/skill-advisor/)** | Analiza cada instruccion y recomienda la skill correcta antes de ejecutar. No vuelvas a olvidar una skill instalada. | 120/120 |

## skill-advisor

> **Instalas 50 skills. Usas 5. Las otras 45 acumulan polvo.**

skill-advisor arregla esto. Se situa entre tu y Claude, analizando cada instruccion para encontrar la mejor skill de TU coleccion instalada — antes de empezar a trabajar.

### Como funciona

```
Escribes una instruccion
        |
        v
skill-advisor escanea tus skills instaladas
        |
        v
Coincidencia? --> Recomienda 1-5, ordenadas por impacto
Sin match?    --> Continua en silencio (o sugiere una para instalar)
```

### Dos modos

**Pre-accion** — Antes de que Claude empiece a trabajar, recomienda skills que mejorarian el resultado:

```
> "arregla este bug de login"

Evaluacion de skills:
1. /systematic-debugging — coincide con "bug, test failure, unexpected behavior"
2. /webapp-testing — verificar el fix despues

Procedo con estas? O directamente sin skill?
```

**Post-accion** — Al terminar un trabajo, sugiere el siguiente paso logico:

```
> [codigo modificado]

Skills recomendadas:
1. /webapp-testing — codigo modificado, tests necesarios
2. /verification-before-completion — antes de dar por terminado
```

### Que lo hace diferente

- **Lee TUS skills** — Sin lista fija. Escanea el system-reminder dinamicamente. Instala una skill hoy, skill-advisor la ve manana.
- **Piensa lateralmente** — "hazlo mas bonito" encuentra skills de diseno, animacion Y auditoria de accesibilidad. No solo busqueda literal.
- **Sabe cuando callarse** — Tareas simples (renombrar variable, leer archivo) no reciben recomendaciones. Se pregunta: "el usuario me agradeceria esto o le molestaria?"
- **Recomienda pipelines** — Detecta escenarios multi-paso y sugiere el combo completo: brainstorming -> writing-plans -> subagent-driven-development.
- **Fallback a la comunidad** — Si nada local coincide, sugiere skills instalables via `find-skills` o `npx skills find`.

### Primera ejecucion

En la primera invocacion explicita (`/skill-advisor`), escanea tu ecosistema:

```
Ecosystem detectado:
- 47 skills instaladas (global + proyecto)
- Categorias: debugging, testing, frontend, docs, planning, ...
- Listo para recomendar en cada instruccion.
```

### Overrides por proyecto

Personaliza el comportamiento por proyecto sin modificar la skill global:

```yaml
# .claude/skills/skill-advisor/SKILL.md
---
name: skill-advisor
description: "Overrides de proyecto para skill-advisor"
user-invocable: false
---

## Contexto del Stack
Este es un proyecto Django. Solo recomendar skills de Python/Django.

## Workflow Post-QA
Despues de QA, siempre crear PR en branch `feature/mi-nombre`.
```

## Estandares de Calidad

Cada skill se evalua con el framework [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensiones, 120 puntos max.

| Dimension | Que mide |
|-----------|----------|
| Knowledge Delta | Conocimiento experto que Claude no tiene por defecto |
| Mindset | Patrones de pensamiento, no solo procedimientos |
| Anti-Patterns | Reglas NEVER especificas con razones reales |
| Description | Optimizada para activacion automatica |
| Disclosure | Cuerpo conciso, referencias bajo demanda |
| Freedom | Nivel correcto de restriccion para el tipo de tarea |
| Pattern | Sigue patrones de diseno de skills probados |
| Usability | El agente puede actuar inmediatamente |

**Minimo para inclusion: B (96/120).** Coleccion actual: todo A+ (120/120).

## Contribuir

1. Fork este repo
2. Anade tu skill en `skills/<nombre>/SKILL.md`
3. Ejecuta `/skill-judge` — debe puntuar B o superior
4. Abre un PR con tu puntuacion

## Licencia

[MIT](../LICENSE)
