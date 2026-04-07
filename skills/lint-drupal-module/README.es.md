# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)**

> **Tu review manual encuentra 29 issues. Ejecutas PHPStan y PHPCS a mano. Le pides a un reviewer que mire estándares y seguridad. 45 minutos después por fin tienes una vista consolidada — y se te pasaron 140 violaciones en los JS del módulo porque nadie le pasó PHPCS al JavaScript.**

`lint-drupal-module` es una skill de lint review para Drupal 11 que ejecuta **cuatro fuentes en paralelo** — PHPStan level 5 (con `phpstan-drupal`), PHPCS (Drupal/DrupalPractice), un agente `drupal-qa` para estándares y un agente `drupal-security` para vectores OWASP — y consolida los hallazgos en un único informe accionable. Lo que antes eran 12 pasos manuales y 30 minutos ahora es una sola invocación que termina en lo que tarda la fuente más lenta (2-5 min en modo completo, 30s-1min en modo diff).

## Instalación

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## Cómo funciona

```
Tú: "lint review del módulo chat_soporte_tecnico_ia"
        |
        v
Identifica el módulo (por nombre, ruta o Glob)
        |
        v
Elige modo: completo (default) | diff (vs develop)
        |
        v
Detecta el entorno (DDEV con ddev exec, o composer local)
        |
        v
Instala PHPStan + phpstan-drupal si faltan (preguntando antes)
        |
        v
Carga references/prompts-agentes.md (obligatorio antes de invocar agentes)
        |
        v
Lanza las 4 fuentes en paralelo, en el mismo mensaje:
  • Agent drupal-qa        (estándares)
  • Agent drupal-security  (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Carga references/plantilla-informe.md (obligatorio antes de escribir)
        |
        v
Consolida las 4 salidas en un informe markdown
        |
        v
Auto-detecta el IDE (Antigravity / Cursor / VS Code)
        |
        v
Escribe en <ide>/Lint reviews/lint-review-<modulo>-<modo>-<rama>.md
        |
        v
Resume los top bloqueantes en chat y pregunta:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## Dos modos

**Completo (default)** — analiza todos los archivos del módulo. Más exhaustivo, más lento (~2-5 min). Úsalo antes de un release, en módulos recién creados o para auditorías periódicas.

**Diff** — analiza solo los archivos cambiados en la rama actual respecto a `origin/develop`. Más rápido (~30s-1min). Úsalo en reviews intermedios durante desarrollo, validación pre-push, o cuando solo te importa lo nuevo.

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<nombre>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## Qué detecta que una review manual no ve

La skill se validó contra un módulo Drupal 11 real (32 archivos). Una review manual solo con agentes reportó 29 issues. La skill ejecutando su pipeline paralelizado completo encontró **65 issues** — incluyendo 166 violaciones PHPCS en los JavaScript del módulo (la mayoría auto-corregibles con `phpcbf`) que la review manual nunca comprobó porque el JS estaba fuera de su alcance.

Esa es la idea: una lint review vale lo que vale su capa más débil. Combinar análisis estático (PHPStan), estándares de estilo (PHPCS) y agentes expertos en paralelo detecta cosas que ninguna fuente por separado ve.

## Estructura del informe

Cada informe sigue la misma plantilla fija (para que el equipo pueda leer informes de distintos módulos sin reaprender):

1. **Resumen ejecutivo** — tabla de hallazgos por fuente, top 5 bloqueantes, veredicto categórico (`APTO`, `APTO con correcciones menores`, `APTO con correcciones críticas`, `NO APTO`)
2. **PHPStan level 5** — errores agrupados por archivo
3. **PHPCS Drupal/DrupalPractice** — violaciones agrupadas por archivo
4. **Estándares (drupal-qa)** — hallazgos por severidad con fixes sugeridos
5. **Seguridad (drupal-security)** — vulnerabilidades clasificadas 🔴 CRÍTICO / 🟠 ALTO / 🟡 MEDIO / 🟢 BAJO / ℹ️ INFO
6. **Acciones priorizadas** — P0 (bloqueantes), P1 (recomendados), P2 (mejoras)
7. **Cobertura de buenas prácticas** — checklist de strict_types, hooks OOP, DI, CSRF en routing, cache metadata, config schema, permissions, translation, behaviors, tests
8. **Comandos de verificación** — comandos exactos para re-ejecutar en local

## NEVER (lecciones aprendidas a las malas)

- **Nunca modifica archivos durante la skill.** Solo reporta. Los fixes son una fase posterior con confirmación explícita del usuario.
- **Nunca ejecuta las 4 fuentes en mensajes separados.** La paralelización es el valor principal; la ejecución en serie tarda 4× más.
- **Nunca marca el veredicto como "APTO" con hallazgos ALTO/CRÍTICO sin resolver.**
- **Nunca lista `Unsafe usage of new static()` en Controllers como bloqueante** — falso positivo conocido de phpstan-drupal con el patrón estándar de Drupal.
- **Nunca elimina aliases FQCN en `services.yml` sin verificar si el Hook OOP los usa por type-hint.** Forma conocida de romper `drush cr`.
- **Nunca asume que los tests funcionales pasan solo porque PHPUnit no falla.** Si PHPStan reporta métodos inexistentes (`getClient()`, `post()`) en el directorio `tests/`, el test probablemente falla silenciosamente en CI.
- **Nunca escribe el informe en inglés.** Código, comandos y nombres de clase en inglés; explicaciones en español.

## Relación con skills hermanas

- **`codex-diff-develop`** — revisa lógica de negocio sobre el diff usando la metodología Codex de 18 reglas. Complementa esta skill (que hace análisis estático y estándares) detectando bugs de lógica.
- **`codex-pr-review`** — review arquitectónica de un PR completo. Un nivel por encima de esta skill.
- **Workflow ideal pre-merge:**
  1. `lint-drupal-module` → fixes mecánicos (tipos, estándares, vectores de seguridad)
  2. `codex-diff-develop` → fixes de lógica de negocio
  3. `codex-pr-review` → review arquitectónica final antes de mergear

## Requisitos

- Proyecto Drupal 11 (detecta el módulo con `Glob "**/web/modules/custom/*/*.info.yml"`)
- DDEV recomendado (la skill ejecuta herramientas dentro del contenedor con `ddev exec`)
- Subagentes `drupal-qa` y `drupal-security` disponibles (degrada a solo PHPStan + PHPCS si faltan)
- Claude de Anthropic con tool use en paralelo (la ejecución secuencial funciona pero es 4× más lenta)

## Licencia

MIT. Ver el LICENSE del repo.
