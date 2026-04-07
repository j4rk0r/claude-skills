# Plantilla del informe consolidado

Esta es la estructura **obligatoria** del informe markdown que la skill genera. La consistencia entre informes (mismo orden de secciones, mismas tablas, mismos campos) hace que el equipo los lea más rápido y los compare entre módulos sin esfuerzo.

---

## Tabla de contenidos

- [Cabecera](#cabecera)
- [Resumen ejecutivo](#resumen-ejecutivo)
- [1. PHPStan](#1-phpstan-level-5)
- [2. PHPCS](#2-phpcs-drupaldrupalpractice)
- [3. Estándares (drupal-qa)](#3-estándares--drupal-qa)
- [4. Seguridad (drupal-security)](#4-seguridad--drupal-security)
- [5. Acciones priorizadas](#5-acciones-priorizadas)
- [6. Cobertura de buenas prácticas](#6-cobertura-de-buenas-prácticas)
- [7. Comandos de verificación](#7-comandos-de-verificación)

---

## Plantilla literal

```markdown
Español confirmado.

# Lint Review — `<nombre-módulo>`

**Fecha:** <YYYY-MM-DD>
**Drupal:** <versión, ej. 11>
**PHP:** <versión, ej. 8.4>
**Modo:** <completo|diff>
**Rama:** <rama-actual>
**Herramientas:** drupal-qa, drupal-security, PHPStan level 5 + phpstan-drupal, PHPCS Drupal/DrupalPractice
**Archivos analizados:** <N>

---

## Resumen ejecutivo

| Fuente | Hallazgos | Bloqueantes |
|---|---:|---:|
| Drupal QA (estándares) | <n> | <n ERROR> |
| Drupal Security (OWASP) | <n> | <n ALTO+CRÍTICO> |
| PHPStan level 5 | <n> | — |
| PHPCS Drupal/DrupalPractice | <n> | <n ERROR> |
| **TOTAL** | **<n>** | **<n>** |

**Veredicto:** <APTO | APTO con correcciones menores | APTO con correcciones críticas | NO APTO>

**Top 5 bloqueantes pre-go-live:**
1. 🔴 [SEC-ALTO-1] <título corto> — `archivo:línea`
2. 🔴 [QA-ROUTING] <título corto>
3. ...

---

## 1. PHPStan level 5

### ERROR (lógica / tipos)

| Archivo | Línea | Mensaje |
|---|---|---|
| `src/Controller/Foo.php` | 41 | Unsafe usage of `new static()` |
| ... | ... | ... |

### Tests

| Archivo | Línea | Mensaje |
|---|---|---|
| `tests/src/...` | ... | ... |

> **Nota:** los hallazgos `Unsafe usage of new static()` en Controllers son falsos positivos conocidos de phpstan-drupal con el patrón estándar de Drupal. Documentar pero no corregir.

---

## 2. PHPCS Drupal/DrupalPractice

### ERROR

<violaciones de severidad ERROR>

### WARNING

<violaciones de severidad WARNING>

---

## 3. Estándares — `drupal-qa`

### 🔴 ERROR

| Severidad | Archivo | Descripción | Fix |
|---|---|---|---|
| 🔴 | `routing.yml` (todas POST) | Sin `_csrf_token` en requirements | Añadir requirement |

### 🟡 WARNING

<lista>

---

## 4. Seguridad — `drupal-security`

### 🟠 ALTO (n)

#### 🟠 [SEC-ALTO-1] <Título descriptivo>

- **Archivos:** `src/Controller/Foo.php:143-146`, ...
- **Vector:** Storage de secretos
- **Problema:** ...
- **Impacto:** ...
- **Fix recomendado:**
  1. ...
  2. ...

### 🟡 MEDIO (n)

| ID | Archivo | Vector | Descripción | Fix |
|---|---|---|---|---|
| MEDIO-1 | `src/Service/...:401` | SSRF | ... | ... |

### 🟢 BAJO (n) y ℹ️ INFO (n)

<resumen breve, no expandir cada uno>

---

## 5. Acciones priorizadas

### P0 — Bloqueantes pre-go-live

1. **[SEC-ALTO-1]** <acción concreta>
2. **[QA-ROUTING]** <acción concreta>
3. ...

### P1 — Recomendados

<lista numerada>

### P2 — Mejoras

<lista numerada>

---

## 6. Cobertura de buenas prácticas

| Aspecto | Estado |
|---|---|
| `declare(strict_types=1)` | ✅ / ⚠️ / ❌ |
| Hooks OOP `#[Hook]` | ... |
| Dependency Injection | ... |
| CSRF en código | ... |
| CSRF en routing (`_csrf_token` / `_csrf_request_header_token`) | ... |
| Rate limiting (Flood) | ... |
| Cache metadata | ... |
| Config schema completo | ... |
| `restrict access: true` donde aplica | ... |
| Tests unitarios | ... |
| Tests funcionales | ... |
| Secretos via `Settings::get()` / `State` | ... |
| OAuth state validation | ... |
| Allow-list SSRF | ... |

**Cobertura buenas prácticas: <%>**

---

## 7. Comandos de verificación

\`\`\`bash
# PHPStan
ddev exec "cd /var/www/html/drupal && vendor/bin/phpstan analyse -c phpstan.lint-review.neon --no-progress"

# PHPCS Drupal standards
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/custom/<nombre>"

# Tests del módulo
ddev exec "cd /var/www/html/drupal && SIMPLETEST_BASE_URL=https://<proyecto>.ddev.site SIMPLETEST_DB=mysql://db:db@db/db BROWSERTEST_OUTPUT_DIRECTORY=/tmp vendor/bin/phpunit -c web/core/phpunit.xml.dist web/modules/custom/<nombre>/tests"
\`\`\`
```

---

## Reglas para el redactor del informe

1. **Severidades fijas — no inventes**. Solo usa: `🔴 ERROR/CRÍTICO`, `🟠 ALTO`, `🟡 MEDIO/WARNING`, `🟢 BAJO`, `ℹ️ INFO`. La consistencia visual hace el informe legible de un vistazo.

2. **`archivo:línea` siempre clickable**. Usa rutas relativas a la raíz del proyecto Drupal (ej. `web/modules/custom/foo/src/Foo.php:42`), no rutas absolutas del contenedor DDEV.

3. **Top 5 bloqueantes con ID**. Cada bloqueante del top tiene un ID corto (`SEC-ALTO-1`, `QA-ROUTING`, `PHPSTAN-1`) que se reusa en P0/P1/P2. Permite cross-referencing dentro del informe.

4. **Las P0 deben ser accionables**. No "mejorar la seguridad" → sí "añadir `_csrf_request_header_token: 'TRUE'` en las 9 rutas POST". Si no puedes describir la acción en una frase, no es P0.

5. **No mezclar fuentes en una misma tabla**. PHPStan, PHPCS, drupal-qa y drupal-security tienen sus propias secciones. Las acciones priorizadas son la única sección donde se cruzan.

6. **Si una fuente no devuelve hallazgos**, deja la sección con `Sin hallazgos.` (no la elimines). La estructura fija ayuda al lector.

7. **Veredicto explícito**. Siempre termina el resumen ejecutivo con un veredicto categórico, no "depende". Si hay hallazgos ALTO/CRÍTICO sin resolver, NO puede ser "APTO".

8. **Falsos positivos conocidos**. Documéntalos en el informe pero NO los listes como bloqueantes:
   - PHPStan: `Unsafe usage of new static()` en Controllers (patrón Drupal estándar).
   - PHPStan: `assertIsArray()` always true en tests (PHPUnit deprecación, no error real).
   - PHPCS: warnings de `txt` o `LongLine` en docblocks generados por core.
