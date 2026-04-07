---
name: lint-drupal-module
description: Lint review completo de un módulo Drupal 11 combinando 4 fuentes en paralelo — PHPStan level 5 + phpstan-drupal, PHPCS Drupal/DrupalPractice, agente drupal-qa (estándares) y agente drupal-security (OWASP). Dos modos — completo (todo el módulo) y diff (solo archivos cambiados vs develop). Genera informe markdown estructurado en la carpeta del IDE con resumen ejecutivo, hallazgos clasificados por severidad, acciones P0/P1/P2 y comandos de verificación. Úsalo siempre que el usuario quiera auditar calidad o seguridad de un módulo Drupal custom, aunque no diga "lint". Triggers — "lint review", "lint del módulo", "auditar módulo Drupal", "revisar módulo custom", "phpstan del módulo", "validar módulo", "qa del módulo", o cuando el usuario pregunta "¿está bien este módulo?", "¿hay errores?", "¿es seguro?". También antes de un release, antes de un PR a develop, o al validar un módulo recién creado.
allowed-tools: Bash(ddev:*) Bash(git:*) Bash(ls:*) Bash(find:*) Bash(printenv:*) Bash(mkdir:*) Bash(cd:*) Bash(wc:*) Bash(grep:*) Read Write Edit Grep Glob Agent
---

# Lint Review — Módulo Drupal 11

Primera línea del informe generado: **"Español confirmado."**

## Para qué sirve

Combina 4 fuentes de análisis (PHPStan, PHPCS, agente drupal-qa, agente drupal-security) en una sola invocación paralelizada, y consolida los hallazgos en un informe accionable. A mano son ~12 pasos y ~30 minutos; con la skill, lo que tarda la fuente más lenta (~2-5 min en completo, ~30s-1min en diff).

## Fast path

```
1. Identificar módulo (nombre/ruta del usuario, o Glob si no especifica)
2. Detectar modo: completo (default) | diff (si dice "diff", "rápido", "vs develop")
3. Detectar entorno: ddev describe → ejecutar via "ddev exec"
4. Verificar herramientas (vendor/bin/phpstan, vendor/bin/phpcs); instalar si faltan PREGUNTANDO
5. Verificar agentes drupal-qa y drupal-security disponibles (si no, ver "Recovery")
6. Leer references/prompts-agentes.md (necesario para el paso 7)
7. Ejecutar las 4 fuentes EN PARALELO en el mismo mensaje:
   a) Agent drupal-qa  — prompt literal de references/prompts-agentes.md
   b) Agent drupal-security — prompt literal de references/prompts-agentes.md
   c) PHPStan level 5 vía Bash (ver "Ejecución en paralelo")
   d) PHPCS Drupal,DrupalPractice vía Bash
8. Leer references/plantilla-informe.md y consolidar las 4 salidas en un informe markdown
9. Detectar IDE → escribir en <carpeta-IDE>/Lint reviews/<nombre-modo-rama>.md
10. Resumir top bloqueantes en chat; preguntar "arregla todo" / "solo crítico" / "déjalo así"
```

Si cualquier paso falla, **detente** y consulta [`references/edge-cases.md`](references/edge-cases.md). No improvises.

## Referencias bajo demanda

Tres archivos en `references/`, cargados solo cuando los necesitas (progressive disclosure):

| Archivo | Cuándo cargarlo | Por qué |
|---|---|---|
| [`references/prompts-agentes.md`](references/prompts-agentes.md) | Antes del paso 7 (invocar agentes) | Contiene los prompts literales para `drupal-qa` y `drupal-security`. Son largos a propósito — sin brief explícito los agentes devuelven reviews superficiales. Cópialos literales, solo sustituye `<ruta-absoluta>`, `<modo>`, `<lista-archivos>`. |
| [`references/plantilla-informe.md`](references/plantilla-informe.md) | Antes del paso 8 (redactar informe) | Plantilla fija. La consistencia entre informes de distintos módulos es lo que hace que el equipo los lea rápido. |
| [`references/edge-cases.md`](references/edge-cases.md) | Cuando algo falle | Síntoma → causa → solución para los problemas más comunes (DDEV, PHPStan, services.yml, OAuth, modo diff). |

Si ya leíste un archivo en esta sesión, no recargues — el contexto lo conserva.

## Modos

### Modo completo (default)
Analiza TODOS los archivos del módulo. Más exhaustivo (~2-5 min). Úsalo:
- Antes de un release
- En módulos recién creados
- Auditorías periódicas
- Cuando el usuario no especifica modo

### Modo diff
Analiza SOLO los archivos cambiados en la rama actual respecto a `origin/develop`. Más rápido (~30s-1min). Úsalo:
- Reviews intermedias durante desarrollo
- Validación pre-push
- Cuando el usuario dice "diff", "rápido", "solo lo que cambié", "vs develop"

Obtener la lista de archivos analizables del módulo (filtrando extensiones que PHPStan/PHPCS pueden procesar):

```bash
cd drupal
git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<nombre>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

El segundo `grep` es importante: sin él recibirás `.css`, `.md` o imágenes que PHPStan rechaza con "no PHP files found". Para PHPStan específicamente, restringe aún más a `\.(php|module|inc|install|profile|theme)$` (sin yml/twig).

Si el resultado está vacío o estás en `develop` → ver [`references/edge-cases.md`](references/edge-cases.md), sección "Modo diff".

## Identificación del módulo

| Lo que dice el usuario | Acción |
|---|---|
| Nombre exacto (`chat_soporte_tecnico_ia`) | `Glob: "**/web/modules/custom/<nombre>/*.info.yml"` |
| Ruta (`web/modules/custom/foo`) | Validar que existe `<ruta>/<basename>.info.yml` |
| Sin especificar | `Glob: "**/web/modules/custom/*/*.info.yml"`. Si hay 1 → usar; si >1 → listar y preguntar; si 0 → parar |

## Entorno de ejecución

1. `ddev describe` (silencioso) → si OK, todo dentro de DDEV con `ddev exec`.
2. Si no hay DDEV → buscar `vendor/bin/phpstan` directo.
3. Si nada → preguntar al usuario qué entorno usa.

**Path en contenedor DDEV:** verifica con `ddev exec "ls /var/www/html"`. Suele ser `/var/www/html/drupal` o `/var/www/html` según el `docroot` del `.ddev/config.yaml`.

## Instalación de herramientas

Si `vendor/bin/phpstan` no existe:
```bash
ddev composer require --dev phpstan/phpstan mglaman/phpstan-drupal phpstan/phpstan-deprecation-rules
```

**Pedir confirmación antes de instalar.** PHPCS suele venir con `drupal/coder` (verificar con `ddev exec "vendor/bin/phpcs -i" | grep -i drupal`).

## Configuración PHPStan

Crea `phpstan.lint-review.neon` en la raíz del proyecto Drupal (no en el módulo):

```neon
parameters:
  level: 5
  paths:
    - web/modules/custom/<nombre>
  excludePaths:
    - web/modules/custom/<nombre>/js/vendor/*
    - web/modules/custom/<nombre>/tests/fixtures/*
  reportUnmatchedIgnoredErrors: false
includes:
  - vendor/mglaman/phpstan-drupal/extension.neon
  - vendor/mglaman/phpstan-drupal/rules.neon
  - vendor/phpstan/phpstan-deprecation-rules/rules.neon
```

**No** uses `drupal_root` (deprecated en phpstan-drupal 2.x — ver edge-cases).

## Ejecución en paralelo

**Crítico:** lanza las 4 fuentes en el MISMO mensaje (mismo bloque de tool calls). Sin paralelización pierdes el principal valor de la skill.

### Modo completo

```bash
# PHPStan — usa el bloque paths: del .neon
ddev exec "cd /var/www/html/drupal && vendor/bin/phpstan analyse -c phpstan.lint-review.neon --no-progress --error-format=raw"

# PHPCS — apunta al directorio del módulo. --ignore excluye JS vendor (html2canvas, etc.)
# PHPCS NO respeta el excludePaths del .neon de PHPStan; hay que pasar --ignore explícito.
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcs --standard=Drupal,DrupalPractice --report=full --ignore='*/vendor/*,*/js/vendor/*' web/modules/custom/<nombre>"
```

### Modo diff

Tras obtener la lista de archivos cambiados (ver sección "Modo diff"), pásalos como argumentos posicionales — sobreescriben el bloque `paths:` del `.neon`:

```bash
# PHPStan — solo archivos PHP cambiados
ddev exec "cd /var/www/html/drupal && vendor/bin/phpstan analyse -c phpstan.lint-review.neon --no-progress --error-format=raw \
  web/modules/custom/<nombre>/src/Foo.php \
  web/modules/custom/<nombre>/src/Bar.php"

# PHPCS — admite también yml y twig
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcs --standard=Drupal,DrupalPractice --report=full --ignore='*/vendor/*,*/js/vendor/*' \
  web/modules/custom/<nombre>/src/Foo.php \
  web/modules/custom/<nombre>/src/Bar.php \
  web/modules/custom/<nombre>/<modulo>.routing.yml"
```

> **Nota sobre `phpcbf`**: PHPCS a menudo reporta "PHPCBF CAN FIX N OF THESE SNIFF VIOLATIONS AUTOMATICALLY". Si el número es alto (>50% de los ERRORS), merece la pena ofrecerle al usuario `phpcbf` como acción rápida tras el informe (ver "Después del informe"). Es especialmente frecuente en archivos JS del módulo, donde las violaciones suelen ser formato auto-corregible.

### Agentes (en el mismo mensaje que los dos comandos anteriores)

1. **Agent `drupal-qa`** — prompt literal de [`references/prompts-agentes.md`](references/prompts-agentes.md), sección "Prompt para `drupal-qa`".
2. **Agent `drupal-security`** — prompt literal de la misma referencia, sección "Prompt para `drupal-security`".

En modo diff, pasa la lista de archivos a los agentes con la ruta **completa relativa al repo** (`web/modules/custom/<nombre>/src/Foo.php`), no la subruta del módulo. Los agentes hacen Read sobre esas rutas.

## Consolidación del informe

Sigue la plantilla literal de [`references/plantilla-informe.md`](references/plantilla-informe.md). La estructura es fija: cabecera, resumen ejecutivo, una sección por fuente (PHPStan/PHPCS/QA/Security), acciones priorizadas P0/P1/P2, cobertura buenas prácticas, comandos de verificación.

**Reglas críticas** (todas detalladas en la plantilla):
- Severidades fijas: 🔴 ERROR/CRÍTICO, 🟠 ALTO, 🟡 MEDIO/WARNING, 🟢 BAJO, ℹ️ INFO.
- `archivo:línea` siempre clickable, ruta relativa al proyecto.
- Top 5 bloqueantes con ID corto reusable (`SEC-ALTO-1`, `QA-ROUTING`, etc.).
- P0 deben ser accionables — "añadir `_csrf_request_header_token` en las 9 rutas POST", no "mejorar la seguridad".
- Veredicto categórico al final del resumen ejecutivo.

## Ubicación del informe

**Paso 1 — IDE por env var (PRIORITARIO).** Ejecuta `printenv CLAUDE_CODE_ENTRYPOINT`:
| `CLAUDE_CODE_ENTRYPOINT` | Carpeta |
|---|---|
| `claude-antigravity` | `.antigravity/Lint reviews/` |
| `claude-cursor` | `.cursor/Lint reviews/` |
| `claude-vscode` | `.vscode/Lint reviews/` |
| otros (`cli`, vacío) | continuar al Paso 2 |

**Paso 2 — fallback por existencia:** `.antigravity/` > `.cursor/` > `.vscode/` > `docs/lint-reviews/`.

**Nombre:** `lint-review-<nombre-modulo>-<modo>-<rama>.md`. Sobrescribir si existe (es la versión más reciente). NUNCA caigas a detección por carpeta cuando el env var es claro — eso causa el bug de elegir `.cursor/` solo porque sobrevive de un uso anterior del IDE.

## Después del informe

1. **Resumen 3-5 líneas** en chat: total hallazgos, top 3 bloqueantes, veredicto.
2. **Link clickable** al informe (ruta relativa).
3. **Pregunta** al usuario qué hacer (no asumas). Las opciones dependen de lo que encontraste:
   - **"arregla todo"** → delegar a `drupal-backend` con la lista P0 estructurada (archivo:línea + acción)
   - **"solo crítico"** → solo HIGH/CRITICAL de seguridad
   - **"auto-fix PHPCS"** → ofrece esta opción SOLO si PHPCS reportó que phpcbf puede arreglar una cantidad significativa (>50% de los ERRORS de PHPCS). Ejecuta: `ddev exec "cd /var/www/html/drupal && vendor/bin/phpcbf --standard=Drupal,DrupalPractice --ignore='*/vendor/*,*/js/vendor/*' web/modules/custom/<nombre>"`. Avisa al usuario de que `phpcbf` **modifica archivos in-place** (a diferencia del resto de la skill que es solo-lectura).
   - **"déjalo así"** → cerrar
4. **Recordar:** tras fixes en `routing.yml` o `services.yml` → `drush cr` obligatorio + tests del módulo + re-ejecutar la skill para verificar.

## NEVER (lecciones aprendidas a las malas)

Estas son las trampas que he visto romper la skill en sesiones reales. Cada una incluye el porqué, no solo la regla.

- **NUNCA modifiques archivos del módulo durante la skill.** Solo reportas. *Por qué:* los fixes son una fase posterior con confirmación explícita del usuario; mezclar análisis y fix dificulta auditar qué cambió.
- **NUNCA ejecutes las 4 fuentes en mensajes separados.** *Por qué:* la skill tarda ~4x más y pierdes el principal valor de tener herramientas + agentes corriendo en paralelo. Si tu cliente no soporta tool calls paralelas, dilo en voz alta antes de empezar para que el usuario lo sepa.
- **NUNCA parafrasees los prompts de los agentes.** Cópialos literales desde `prompts-agentes.md`. *Por qué:* sin la checklist explícita los agentes devuelven reviews superficiales (ver el docu del propio prompts-agentes.md).
- **NUNCA marques el veredicto como "APTO" con hallazgos ALTO/CRÍTICO sin resolver.** *Por qué:* el equipo lee solo el veredicto cuando va con prisa; un APTO falso bloquea la cultura de auditar.
- **NUNCA listes `Unsafe usage of new static()` en Controllers como bloqueante.** *Por qué:* es falso positivo conocido de phpstan-drupal con el patrón estándar de Drupal (ver edge-cases).
- **NUNCA elimines aliases FQCN en `services.yml` sin verificar la Forma A vs Forma B.** *Por qué:* la Forma A (alias real con `'@servicio'`) es necesaria para el autowiring del Hook OOP. Eliminarla rompe `drush cr`. Ver edge-cases.
- **NUNCA asumas que los tests funcionales pasan solo porque PHPUnit no falla.** *Por qué:* si PHPStan reporta métodos inexistentes (`getClient()`, `post()` sobre interfaces) en el directorio `tests/`, el test depende del driver actual y romperá silenciosamente en CI cuando cambie. Reportarlo como bloqueante.
- **NUNCA escribas el informe en inglés.** Código, comandos y nombres de clase en inglés; explicaciones en español. *Por qué:* el equipo trabaja en español y los informes mezclados son ruido.

## Checklist de auto-verificación (antes de entregar)

Verifica cada item leyendo el informe que has generado. Si algo falta, vuelve atrás antes de entregárselo al usuario.

- [ ] Primera línea del informe es exactamente `Español confirmado.`
- [ ] El informe está en `<carpeta-IDE>/Lint reviews/lint-review-<nombre>-<modo>-<rama>.md` (verifica con `ls`)
- [ ] Las 4 fuentes aparecen en el informe (PHPStan, PHPCS, drupal-qa, drupal-security). Si alguna no se ejecutó, debe estar marcada como `❌ no ejecutada — <razón>`, no omitida silenciosamente.
- [ ] Cada hallazgo tiene `archivo:línea` con ruta relativa al proyecto (no rutas absolutas del contenedor DDEV).
- [ ] Sección "P0 bloqueantes" con acciones concretas. Si una P0 dice "mejorar X", reescríbela hasta que diga "añadir/eliminar/cambiar Y en `archivo:línea`".
- [ ] Tabla de resumen ejecutivo con conteos por fuente y total.
- [ ] Veredicto explícito al final del resumen (`APTO`, `APTO con correcciones menores`, `APTO con correcciones críticas`, `NO APTO`). Nada de "depende".
- [ ] Si hay hallazgos ALTO/CRÍTICO sin resolver, el veredicto NO es "APTO".
- [ ] Sección "Comandos de verificación" al final, con los comandos reales que se usaron (no genéricos).
- [ ] El módulo no ha sido modificado: `git status` sobre la carpeta del módulo no muestra cambios atribuibles a esta skill.
- [ ] La última línea de tu mensaje en chat es una pregunta al usuario (`arregla todo`/`solo crítico`/`déjalo así`), no un asume "ahora arreglo todo".

## Recovery — qué hacer si algo falla

| Síntoma | Acción |
|---|---|
| `references/*.md` no existe | Avisar al usuario, no inventar plantillas |
| DDEV no levantado | Pedir al usuario antes de `ddev start` |
| PHPStan/PHPCS no instalados | Pedir confirmación para instalar (`ddev composer require --dev ...`) |
| Agentes `drupal-qa` o `drupal-security` no disponibles | Continuar con las otras fuentes (PHPStan + PHPCS) y pedir al usuario que confirme si quiere review manual del modelo (más lento, menos rigor) |
| Una de las 4 fuentes falla en runtime | Continuar con las otras 3, marcar la fallida en el informe |
| No se puede crear la carpeta del IDE | Crear con `mkdir -p`; si falla, usar `docs/lint-reviews/` |
| Modo diff sin cambios en el módulo | Ofrecer cambiar a completo |
| Estás en `develop` (no hay rama feature) | Abortar con mensaje claro |
| Cliente no soporta tool calls paralelas | Avisar al usuario al inicio: la skill será 4x más lenta, ¿continuar? |
| Síntoma no listado | Consulta [`references/edge-cases.md`](references/edge-cases.md). Si tu síntoma no aparece, añádelo después de resolverlo |

## Relación con skills hermanas

- **`codex-diff-develop`** = revisión de **lógica de negocio** Codex sobre el diff (los 18 puntos del framework). Esta skill = lint **estático** (tipos, estándares, seguridad) sobre módulo o diff.
- **`codex-pr-review`** = revisión arquitectónica de PR completo, opinión humana. Esta skill = nivel inferior, herramientas automatizadas + agentes especializados.
- **Las tres son complementarias.** Workflow ideal pre-merge:
  1. `lint-drupal-module` (esta skill) → fixes mecánicos
  2. `codex-diff-develop` → fixes de lógica
  3. `codex-pr-review` → revisión final antes de mergear
