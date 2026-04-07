# Edge cases y troubleshooting

Lecciones aprendidas ejecutando lint reviews reales. Cada entrada incluye **síntoma**, **causa raíz** y **solución**, para que la próxima vez no haya que redescubrirlo.

---

## DDEV / entorno

### DDEV no está levantado
**Síntoma:** `ddev exec` falla con "container not running" o `ddev describe` devuelve "Stopped".
**Causa:** El proyecto DDEV no está iniciado.
**Solución:** Pregunta al usuario antes de levantarlo (puede tener otro proyecto activo). Si autoriza, `ddev start` desde la raíz del proyecto Drupal. Espera ~30s antes de reintentar.

### Path dentro del contenedor incorrecto
**Síntoma:** `ddev exec "cd drupal && ..."` devuelve `cd: drupal: No such file or directory`.
**Causa:** El working directory por defecto del contenedor DDEV no siempre es la raíz del proyecto host. Puede ser `/var/www/html` o `/var/www/html/drupal` según el `docroot` del `.ddev/config.yaml`.
**Solución:** Verifica con `ddev exec "ls /var/www/html"`. Si ves el subdirectorio `drupal`, usa `cd /var/www/html/drupal`. Si ya estás en él, usa `cd /var/www/html`.

### `composer not found` en el host
**Síntoma:** El usuario no tiene `composer` instalado en su Mac.
**Causa:** El proyecto solo lo usa via DDEV.
**Solución:** Usa `ddev composer` en lugar de `composer` directo. Funciona transparentemente.

---

## PHPStan

### `drupal_root parameter is deprecated`
**Síntoma:** Warning ruidoso al ejecutar PHPStan: `The drupal_root parameter is deprecated. Remove it from your configuration.`
**Causa:** En `phpstan-drupal` 2.x, el `drupal_root` se autodetecta. El parámetro fue eliminado.
**Solución:** Borra `drupal_root: web` del `.neon`. PHPStan lo detecta solo desde `composer.json`.

### `Unsafe usage of new static()` en Controllers
**Síntoma:** PHPStan reporta este error en `Foo::create()` aunque el código sigue el patrón estándar de Drupal.
**Causa:** Falso positivo conocido de phpstan-drupal con el patrón `public static function create(ContainerInterface $container): static { return new static(...); }`. Drupal lo usa en TODOS los Controllers desde Drupal 8.
**Solución:** **No corregir.** Documentar en el informe como "falso positivo conocido" y dejarlo. Si hay muchos, añadir al `ignoreErrors` del `.neon`:
```neon
ignoreErrors:
  - '#Unsafe usage of new static\(\)#'
```

### `Ignored error pattern was not matched`
**Síntoma:** Mensaje al inicio de la salida: `?:?:Ignored error pattern #...# was not matched in reported errors.`
**Causa:** Tienes un `ignoreErrors` en el `.neon` pero el patrón ya no aplica (porque PHPStan dejó de reportarlo o el archivo cambió).
**Solución:** Añadir al `.neon` el parámetro `reportUnmatchedIgnoredErrors: false`, o eliminar el patrón obsoleto.

### `method_exists() always evaluate to true`
**Síntoma:** Warnings de comparación siempre verdadera en código defensivo (`method_exists($e, 'getCode')`).
**Causa:** PHPStan resuelve los tipos y sabe que `GuzzleException` siempre tiene `getCode()`. El código defensivo es redundante.
**Solución:** Casi siempre es seguro eliminar el `method_exists()`. No urgente.

### `assertIsArray()` always true en tests
**Síntoma:** PHPStan en tests reporta `Call to method assertIsArray() with array<...> will always evaluate to true`.
**Causa:** El tipo del valor ya está garantizado por la firma del método anterior. La aserción no aporta.
**Solución:** Eliminar la aserción o sustituir por `assertCount(N, $array)` que sí aporta valor.

---

## Services / Autowiring

### Romper el Hook OOP al "limpiar" `services.yml`
**Síntoma:** Tras eliminar definiciones FQCN aparentemente duplicadas, `drush cr` falla con:
```
Cannot autowire service "Drupal\<modulo>\Hook\<Hook>": argument "$foo" of method "__construct()"
references class "Drupal\<modulo>\Service\Foo" but no such service exists.
```
**Causa raíz:** El Hook OOP usa autowiring por type-hint. El "duplicado" FQCN sin args en realidad era un alias necesario para que el container pudiera resolver `Drupal\<modulo>\Service\Foo` al servicio real `<modulo>.foo`.

**Diagnóstico:** Lo que parece "duplicado" suele ser una de estas dos formas válidas:

```yaml
# Forma A: definición principal + alias FQCN
services:
  modulo.foo:
    class: Drupal\modulo\Service\Foo
    arguments: ['@bar']
  Drupal\modulo\Service\Foo: '@modulo.foo'    # ← alias real, NO duplicado

# Forma B: dos definiciones, la del FQCN sin args (BUG real)
services:
  modulo.foo:
    class: Drupal\modulo\Service\Foo
    arguments: ['@bar']
  Drupal\modulo\Service\Foo:                  # ← BUG: redefine la clase sin args
    class: Drupal\modulo\Service\Foo
```

**Solución correcta:**
- Si encuentras la **Forma B** (BUG real), sustitúyela por la Forma A: `Drupal\modulo\Service\Foo: '@modulo.foo'` (alias con `@`).
- Si encuentras la **Forma A**, NO la toques. Es necesaria para autowiring.

**Test rápido:** `grep -A 1 "Drupal\\\\<modulo>" services.yml` — si ves `class:` debajo, es la Forma B (BUG). Si ves un `'@...'`, es la Forma A (correcto).

---

## PHPCS

### PHPCS no encuentra el standard `Drupal`
**Síntoma:** `vendor/bin/phpcs --standard=Drupal` falla con "ERROR: the Drupal coding standard is not installed".
**Causa:** `drupal/coder` está instalado pero `phpcs` no sabe dónde encontrar los sniffs.
**Solución:**
```bash
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer"
```

### PHPCS reporta miles de errores en `vendor/`
**Síntoma:** El comando se ejecuta pero analiza también `vendor/` y devuelve >10k errores.
**Causa:** No estás filtrando el path al módulo.
**Solución:** Apunta al directorio del módulo, no a la raíz: `... web/modules/custom/<nombre>` (no solo `.`).

### ⚠️ phpcbf rompe archivos JavaScript convirtiendo `null`/`true`/`false` a mayúsculas
**Síntoma:** Tras `phpcbf --standard=Drupal` sobre un módulo, los archivos `.js` quedan corruptos:
```diff
- this.isOpen = false;
- this.sessionItemId = null;
- this.sendBtn.disabled = true;
+ this.isOpen = FALSE;           ← ReferenceError en runtime
+ this.sessionItemId = NULL;     ← ReferenceError en runtime
+ this.sendBtn.disabled = TRUE;  ← ReferenceError en runtime
```
El chat / frontend rompe al cargar con `ReferenceError: NULL is not defined`.

**Causa raíz:** El standard `Drupal` de PHPCS (distribuido con `drupal/coder`) incluye la regla `Drupal.Semantics.ConstantName` pensada para constantes PHP. PHPCS la aplica a **cualquier archivo que procese**, incluyendo `.js`, porque el módulo `Coder` registra sniffs para JS con el mismo standard. Phpcbf corrige la supuesta "violación" convirtiendo los literales JS a mayúsculas, rompiendo el código.

Esto es un problema conocido (hay issues abiertos en drupal.org desde hace años) y no se va a arreglar pronto en el standard oficial.

**Solución obligatoria al usar phpcbf/phpcs sobre módulos Drupal que contengan JS:**

1. Restringe las extensiones con `--extensions=php,module,inc,install,profile,theme` (nunca incluyas `js`).
2. Excluye rutas de JS con `--ignore='*/js/*'` (por si alguien lo pasa como argumento posicional).
3. Nunca pases archivos `.js` como argumentos posicionales a phpcbf/phpcs.

```bash
# ✅ Correcto — phpcbf solo toca archivos PHP
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcbf \
  --standard=Drupal,DrupalPractice \
  --extensions=php,module,inc,install,profile,theme \
  --ignore='*/vendor/*,*/js/*' \
  web/modules/custom/<nombre>"

# ❌ Peligroso — el .js del módulo será "corregido" con NULL/TRUE/FALSE
ddev exec "cd /var/www/html/drupal && vendor/bin/phpcbf \
  --standard=Drupal,DrupalPractice \
  web/modules/custom/<nombre>"
```

**Recovery si ya se ejecutó sin los flags:**
1. `git status` para ver qué archivos se modificaron.
2. Si los cambios NO están commiteados → `git checkout -- <archivo.js>` revierte limpiamente.
3. Si los cambios ya están commiteados → `git revert <sha>` o reverso manual buscando `NULL`/`TRUE`/`FALSE` en mayúsculas en archivos `.js`.

**Para lint de JavaScript, usa herramientas específicas** (ESLint + prettier con un preset Drupal/Airbnb/standard). PHPCS no es la herramienta correcta para JS por mucho que el standard Drupal lo permita.

**Lección aprendida:** validado en un módulo real (`chat_soporte_tecnico_ia`). Phpcbf reportó "165 ERRORS FIXED" que incluían 80+ conversiones JS a mayúsculas. Se detectó revisando el `git diff` antes de commitear; de no haberlo revisado, el chat habría roto en producción.

---

## PHPUnit / tests funcionales

### `SIMPLETEST_BASE_URL environment variable` faltante
**Síntoma:** Tests funcionales fallan con `Exception: You must provide a SIMPLETEST_BASE_URL environment variable to run some PHPUnit based functional tests.`
**Causa:** PHPUnit funcional necesita conocer la URL del sitio para arrancar el browser headless.
**Solución:** Pasar las variables al ejecutar:
```bash
ddev exec "cd /var/www/html/drupal && \
  SIMPLETEST_BASE_URL=https://<proyecto>.ddev.site \
  SIMPLETEST_DB=mysql://db:db@db/db \
  BROWSERTEST_OUTPUT_DIRECTORY=/tmp \
  vendor/bin/phpunit -c web/core/phpunit.xml.dist web/modules/custom/<nombre>/tests"
```

Detecta el `<proyecto>` con `ddev describe | grep "ddev.site"`.

### Test funcional pasa pero PHPStan dice que está roto
**Síntoma:** PHPStan reporta `Call to an undefined method Behat\Mink\Driver\DriverInterface::getClient()` o similar en un test funcional, pero el test "pasa".
**Causa raíz:** El test posiblemente falla silenciosamente en CI porque llama a métodos que no existen en la interfaz declarada. Solo "pasa" si el método llamado existe en la implementación concreta del driver actual — pero PHPStan analiza por interfaz, no por implementación. Si cambia el driver (Goutte → BrowserKit → ChromeDriver), el test rompe.
**Bandera roja:** `$session->getDriver()->getClient()->getCookieJar()`, `$client->post()`, etc.
**Solución:** Refactorizar usando la API de `BrowserTestBase`:
- `$this->getSessionCookies()` para cookies
- `$client = $this->getHttpClient()` para Guzzle real
- `$client->request('POST', $url, [...])` (no `$client->post(...)`)

---

## OAuth y secretos

### Token OAuth se filtra a `drush cex`
**Síntoma:** Después de OAuth callback, `git status` muestra que `config/sync/<modulo>.settings.yml` ahora contiene un token real.
**Causa raíz:** El callback escribe el token con `$this->configFactory->getEditable(...)->set('token', $value)->save()`. Drupal lo trata como config normal y `drush cex` lo exporta.
**Solución:** Token NO debe ir en config editable. Opciones (de menos a más seguro):
1. **`State` API** (`@state` service) — sobrevive entre requests, NO se exporta. Mínimo cambio.
2. **`settings.php`** vía `Settings::get()` — fuera del DB, requiere intervención del admin.
3. **Módulo `key`** — almacenamiento cifrado con backends pluggables (file, AWS Secrets, Vault).

Patrón con backward compat:
```php
$token = Settings::get('mi_modulo.token')              // Más seguro
      ?? $this->state->get('mi_modulo.token')           // Migración
      ?? $config->get('token');                          // Legacy compat
```

### Forms de admin que muestran el token plano
**Síntoma:** El SettingsForm muestra el valor del token en `#default_value`.
**Causa:** Conveniencia, pero expone el secreto a cualquiera que abra "View source" o "Edit settings".
**Solución:** Si el campo tiene valor, mostrar `••••••••` y un botón "Reset". Solo guardar si el usuario escribe algo distinto del placeholder.

---

## Modo diff

### Diff vacío
**Síntoma:** `git diff --name-only origin/develop...HEAD` no devuelve nada relacionado con el módulo.
**Causa:** O bien el módulo no tiene cambios en esta rama, o estás en `develop`.
**Solución:**
1. Si `git rev-parse --abbrev-ref HEAD` == `develop` → abortar con mensaje claro.
2. Si no hay cambios → ofrecer cambiar a modo completo.

### `origin/develop` no existe
**Síntoma:** `git diff origin/develop...HEAD` falla.
**Causa:** Nunca se hizo `fetch` o el remote se llama distinto.
**Solución:** `git fetch origin develop` primero. Si falla, listar remotes con `git remote -v` y preguntar al usuario.

### Diff demasiado grande
**Síntoma:** >50 archivos cambiados en el módulo.
**Causa:** PR muy grande o rebase con muchos commits.
**Solución:** Avisar al usuario del tamaño y ofrecer:
- (a) Continuar con el modo diff (puede ser lento).
- (b) Cambiar a modo completo (puede ir más rápido si los archivos son pocos en absoluto).
- (c) Abortar y dividir el PR.

---

## Recovery

| Síntoma | Acción |
|---|---|
| Una de las 4 fuentes falla (PHPStan, PHPCS, agente) | Continuar con las otras 3, marcar la fallida en el informe con `❌ no ejecutada — <razón>` |
| El informe no se puede escribir en la carpeta detectada | Crear la carpeta con `mkdir -p`, si falla → escribir en `docs/lint-reviews/` como fallback |
| `drush cr` falla tras los fixes | Diagnosticar con `drush watchdog:show` y `vendor/bin/drupal cache:rebuild`. Si es un YAML mal formado, validar con `php -r "print_r(yaml_parse_file('archivo.yml'));"` |
| El usuario rechaza la instalación de PHPStan | Continuar solo con drupal-qa + drupal-security + PHPCS. Reportar en el informe que PHPStan no se ejecutó |
