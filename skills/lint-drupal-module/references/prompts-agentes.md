# Prompts para drupal-qa y drupal-security

Estos son los prompts exactos a pasar a los agentes especializados. Sustituye `<ruta-absoluta>`, `<modo>` y `<lista-archivos>` antes de invocarlos.

---

## Por qué estos prompts son largos

Los agentes `drupal-qa` y `drupal-security` ya saben hacer reviews — pero sin un brief explícito tienden a:

1. **Ser superficiales** — listan 3 cosas obvias y paran. El brief les da una checklist concreta.
2. **Modificar archivos** — por defecto pueden empezar a "arreglar" cosas. El "NO modifiques archivos" lo previene.
3. **Devolver resultados en formato libre** — el brief especifica el entregable para que la consolidación sea trivial.
4. **Saltarse vectores no obvios** — ej. SSRF, prompt injection, storage de secretos. Hay que mencionarlos explícitamente.

---

## Prompt para `drupal-qa`

```
Realiza un lint review COMPLETO del módulo Drupal 11 ubicado en `<ruta-absoluta>`.

Modo: <completo|diff>
<si modo == diff:
Lista de archivos a revisar (NO revises nada fuera de esta lista):
  - <archivo1>
  - <archivo2>
  ...
>

Es un módulo custom. Necesito una auditoría exhaustiva de calidad de código y estándares Drupal 11.

**Qué revisar (Drupal 11 standards):**

1. **PHPCS Drupal + DrupalPractice**: indentación (2 espacios), nombrado (camelCase métodos, snake_case funciones procedurales), docblocks completos, type hints + return types en PHP 8.1+, line length 80 chars, espacios en operadores.

2. **Hooks OOP**: ¿están migrados a clases con atributo `#[Hook('hook_name')]` (Drupal 10.3+)? ¿O usan el estilo procedural en `.module`? El estilo OOP es preferido para módulos nuevos.

3. **Dependency Injection**: ¿Controllers, Forms y Services usan DI en lugar de `\Drupal::service()`? ¿Los `create()` están bien construidos? ¿Se inyectan interfaces en lugar de clases concretas?

4. **Cache metadata**: ¿Las respuestas usan `CacheableResponseInterface`? ¿Render arrays tienen `#cache` con tags/contexts/max-age cuando aplica? Atención a lazy builders sin `#cache.contexts`.

5. **Routing** (`*.routing.yml`): ¿`_permission` o `_access` configurados? ¿Las rutas POST tienen `_csrf_token: 'TRUE'` o `_csrf_request_header_token: 'TRUE'`? ¿`_format` declarado en endpoints JSON?

6. **Forms**: validación correcta, `#required`, `getEditableConfigNames()` en SettingsForm, schema YAML completo. Submit handlers usan `$this->config()` (que es editable en `ConfigFormBase`).

7. **Services YAML**: argumentos correctos, autowire si aplica, tags adecuados. Cuidado con FQCN duplicados (definidos como class + alias) — rompen autowiring del Hook OOP.

8. **Permissions**: granularidad (no usar `administer site configuration` para todo), `restrict access: true` cuando el permiso da acceso a datos sensibles.

9. **Translation**: uso correcto de `t()` / `$this->t()`, `formatPlural` para plurales, NO concatenación de strings traducibles. En hooks `help()`, cada fragmento de texto debe ir en su propio `t()`.

10. **Twig**: autoescape activo, sin lógica compleja, uso de `|t({'@param': value})` (no `|t|replace`), `attach_library` para CSS/JS.

11. **JS**: `Drupal.behaviors` con `attach`/`detach`, `once()` para evitar event listeners duplicados, sin globals, jQuery namespacing si se usa.

12. **Tests**: namespace correcto (`Drupal\Tests\<modulo>\Unit|Kernel|Functional`), extends apropiado (`UnitTestCase`, `KernelTestBase`, `BrowserTestBase`).

**Si hay `phpcs` instalado en el proyecto** (`vendor/bin/phpcs` o vía DDEV), úsalo con `--standard=Drupal,DrupalPractice`. Si no, haz revisión manual exhaustiva basada en los standards.

**Entregable estructurado:**

1. **Resumen ejecutivo**: total de issues, conteo por severidad (ERROR/WARNING/INFO), top 5 problemas críticos, % cobertura de buenas prácticas.
2. **Hallazgos por archivo**: tabla con columnas `Línea`, `Severidad`, `Regla`, `Descripción`, `Fix sugerido`.
3. **Checklist de buenas prácticas**: tabla con OK / PARCIAL / FALTA por aspecto (strict_types, hooks OOP, DI, CSRF en código, CSRF en routing, cache metadata, schema completo, permissions, translation, behaviors, tests).
4. **Acciones prioritarias**: lista numerada ordenada por impacto.

**IMPORTANTE: NO modifiques ningún archivo. Solo reporta.**
```

---

## Prompt para `drupal-security`

```
Realiza una auditoría de SEGURIDAD COMPLETA del módulo Drupal 11 en `<ruta-absoluta>`.

Modo: <completo|diff>
<si modo == diff:
Lista de archivos a auditar (NO audites nada fuera de esta lista):
  - <archivo1>
  - <archivo2>
  ...
>

**Contexto del módulo** (si lo conoces, incluye aquí: maneja datos sensibles, IA externa, OAuth, integraciones de terceros, datos de usuario, etc.). Esto ayuda a priorizar vectores.

**Vectores OWASP/Drupal a auditar:**

1. **Access bypass**: rutas sin `_permission` o con `access: TRUE`. Atención especial a EventSubscribers con palabras como "bypass", "skip", "ignore" en el nombre.

2. **CSRF**: rutas POST/mutadoras sin `_csrf_token: 'TRUE'` o sin `_csrf_request_header_token`. La validación manual en código es defensa en profundidad pero NO sustituye al requirement de routing.

3. **XSS**: salida sin escape en Twig (`|raw`, `|safe`), JS con `innerHTML`, render arrays con `#markup` sobre input no escapado, `Markup::create()` sobre input no controlado.

4. **SQL Injection**: queries sin placeholders, `db_query` legacy, concatenación de variables en SQL.

5. **SSRF**: llamadas HTTP a URLs controladas por usuario o admin (Monday API, IA externa, GitHub, etc.). Validar host allowlist, scheme (`https` only), y rechazar `userinfo` en URLs (`https://x@host/`).

6. **Storage de secretos**: API keys/tokens en config exportable (`drush cex` los vuelca a git). Deben estar en `Settings::get()`, módulo `key`, o `State` API. Logs no deben contener secretos.

7. **OAuth**: validación `state` parameter con `hash_equals()` (no `===`), `redirect_uri` whitelist, almacenamiento seguro de tokens (no en config editable), refresh logic.

8. **Validación de input**: datos enviados a IA sin sanear (prompt injection), sin límite de tamaño, sin allowlist de campos. Revisar `mb_strlen` en payloads grandes.

9. **Rate limiting / DoS**: endpoints sin throttling. Drupal expone `flood` service — verificar uso en endpoints sensibles (chat, login, OAuth, creación de recursos).

10. **Information disclosure**: errores con stack trace al usuario, debug info, IDs predecibles, logs con PII.

11. **Permisos**: granularidad (1 permiso por capacidad), `restrict access: true` donde aplique.

12. **File uploads** (si existen): validación MIME real (no extensión), paths fuera de webroot, no ejecución.

13. **Logging**: logs con datos sensibles (tokens, prompts con PII, emails). Considerar GDPR si propaga datos a terceros.

14. **Subida de imágenes/screenshots**: si el módulo usa `html2canvas`, `canvas.toDataURL`, o similar, auditar el endpoint de subida (MIME allowlist server-side, base64 decode check, tamaño máximo).

**Entregable estructurado:**

Vulnerabilidades clasificadas por severidad:
- 🔴 **CRÍTICO** — explotable remotamente sin auth, RCE, data loss masivo
- 🟠 **ALTO** — explotable con auth básica, escalada de privilegios, leak de secretos
- 🟡 **MEDIO** — requiere condiciones específicas, defense in depth roto
- 🟢 **BAJO** — buena práctica, hardening
- ℹ️ **INFO** — observación, contexto

Por cada hallazgo:
- **Archivo:línea**
- **Vector** (uno de los 14 anteriores)
- **Descripción** del problema
- **Impacto** (qué puede pasar)
- **PoC** si procede (no más de 5 líneas)
- **Fix recomendado**

**Resumen ejecutivo** con top 5 vulnerabilidades.

**Veredicto**: APTO / APTO con correcciones / NO APTO para producción. Lista de bloqueantes.

**IMPORTANTE: NO modifiques ningún archivo. Solo reporta.**
```

---

## Sustitución dinámica

Variables a sustituir en los prompts:

| Placeholder | Valor |
|---|---|
| `<ruta-absoluta>` | Path absoluto del módulo en el host (ej. `/Applications/docker/Oltex/drupal/web/modules/custom/foo`). Lo usa el agente como punto de partida. |
| `<modo>` | `completo` o `diff` |
| `<lista-archivos>` | (solo modo diff) Lista de archivos cambiados, **una por línea, indentada con `  - `, ruta relativa al repo del proyecto Drupal**. Ejemplo: `  - web/modules/custom/foo/src/Foo.php` |

Cuando el modo es `diff`, sustituye `<lista-archivos>` con la salida de este comando (mantiene el prefijo del módulo, no lo recorta):

```bash
cd drupal && git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<nombre>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$' \
  | sed 's|^|  - |'
```

**Importante:** los paths llegan al agente con la **ruta completa relativa al repo** (`web/modules/custom/foo/src/Foo.php`), no la subruta del módulo (`src/Foo.php`). Esto evita ambigüedad: el agente sabe que esos paths son `Read`-ables tal cual desde la raíz del proyecto Drupal.

Cuando el modo es `completo`, omite la sección "Lista de archivos a revisar" por completo del prompt (los agentes hacen `Glob` sobre `<ruta-absoluta>`).
