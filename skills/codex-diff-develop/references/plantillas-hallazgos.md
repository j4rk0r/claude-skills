# Plantillas de hallazgos — Codex diff develop

Plantillas listas para copiar al informe. Cada una incluye **Problema (Severidad)**, **Riesgo** y **Solución** con código real.

---

## Twig — XSS por |raw

**Problema (Alta):** uso de `|raw` sobre `{{ user_input }}`.
**Riesgo:** XSS persistente. Cualquier `<script>` en el contenido se ejecuta en el navegador del visitante.
**Solución:** eliminar `|raw`; si necesitas HTML controlado:
```twig
{{ value|check_markup('basic_html') }}
```

---

## Twig — i18n faltante

**Problema (Media):** literal `"Continuar"` sin `|t` en `template.html.twig`.
**Riesgo:** rompe la traducción del sitio multi-idioma.
**Solución:**
```twig
{{ 'Continuar'|t }}
```

---

## Service — DI faltante en clase nueva

**Problema (Media):** `\Drupal::entityTypeManager()` en `MiController::build()`.
**Riesgo:** intestable, contradice PSR-12 y estándar del proyecto.
**Solución:**
```php
public function __construct(
  private readonly EntityTypeManagerInterface $entityTypeManager,
) {}

public static function create(ContainerInterface $container): self {
  return new self($container->get('entity_type.manager'));
}
```

---

## Hook — falta hook_entity_insert

**Problema (Alta):** lógica en `mymodule_node_update` sin `mymodule_node_insert`.
**Riesgo:** nodos nuevos no se procesan hasta una edición posterior. Funcionalidad invisible para todo el contenido recién creado.
**Solución:** extraer a función privada y llamarla desde ambos hooks:
```php
function mymodule_node_insert(NodeInterface $node): void {
  _mymodule_process_node($node);
}

function mymodule_node_update(NodeInterface $node): void {
  _mymodule_process_node($node);
}

function _mymodule_process_node(NodeInterface $node): void {
  // lógica común
}
```

---

## Hook — recursión sin guarda

**Problema (Alta):** `hook_entity_update` llama a `$entity->save()` sin guarda estática.
**Riesgo:** loop infinito, agotamiento de memoria, caída del worker de cron.
**Solución:**
```php
function mymodule_entity_update(EntityInterface $entity): void {
  static $processing = [];
  $key = $entity->getEntityTypeId() . ':' . $entity->id();
  if (isset($processing[$key])) {
    return;
  }
  $processing[$key] = TRUE;
  try {
    // lógica que puede llamar a save()
  } finally {
    unset($processing[$key]);
  }
}
```

---

## Query — sin parametrizar

**Problema (Alta):** `"SELECT ... WHERE name = '" . $name . "'"`.
**Riesgo:** SQL injection + rotura con apóstrofos en valores reales.
**Solución:**
```php
$query = $connection->select('foo', 'f')
  ->fields('f', ['id'])
  ->condition('name', $name);
$result = $query->execute()->fetchAll();
```

---

## Query — agregada sin fallback NULL

**Problema (Alta):** `SELECT MAX(weight) FROM ...` sin manejo del primer registro.
**Riesgo:** en tabla vacía devuelve `NULL`, luego `NULL + 1` rompe lógica de orden.
**Solución:**
```php
$max = (int) $connection->select('foo', 'f')
  ->fields('f', ['weight'])
  ->orderBy('weight', 'DESC')
  ->range(0, 1)
  ->execute()
  ->fetchField();
$next = $max + 1; // (int) NULL = 0, así que esto siempre funciona
```

---

## Update hook — no idempotente

**Problema (Alta):** `mymodule_update_9001()` asume que el campo no existe.
**Riesgo:** re-ejecución manual tras fallo parcial revienta con "column already exists".
**Solución:**
```php
function mymodule_update_9001(): void {
  $schema = \Drupal::database()->schema();
  if ($schema->fieldExists('mytable', 'mycolumn')) {
    return;
  }
  $schema->addField('mytable', 'mycolumn', [
    'type' => 'int',
    'not null' => TRUE,
    'default' => 0,
  ]);
}
```

---

## accessCheck(FALSE) injustificado

**Problema (Alta):** `->accessCheck(FALSE)` en query expuesta a usuario anónimo.
**Riesgo:** bypass silencioso de permisos, exposición de contenido privado.
**Solución:** quitar y validar acceso, o documentar inline:
```php
// accessCheck OK: ruta admin con _permission: 'administer site configuration'
$nids = \Drupal::entityQuery('node')
  ->accessCheck(FALSE)
  ->condition('status', 1)
  ->execute();
```

---

## Cache metadata faltante

**Problema (Media):** Block plugin sin `getCacheTags()` ni `getCacheContexts()`.
**Riesgo:** contenido obsoleto tras cambios, rompe Dynamic Page Cache y BigPipe.
**Solución:**
```php
public function getCacheTags(): array {
  return Cache::mergeTags(parent::getCacheTags(), ['node_list:article']);
}

public function getCacheContexts(): array {
  return Cache::mergeContexts(parent::getCacheContexts(), ['user.roles']);
}
```

---

## Config schema desactualizado

**Problema (Media):** nuevo key `mymodule.settings:retry_count` sin entrada en `config/schema/mymodule.schema.yml`.
**Riesgo:** `drush cim` falla en otros entornos con error de validación.
**Solución:**
```yaml
mymodule.settings:
  type: config_object
  label: 'My module settings'
  mapping:
    retry_count:
      type: integer
      label: 'Retry count'
```

---

## API externa sin timeout

**Problema (Alta):** `$this->httpClient->get($url)` sin opciones de timeout.
**Riesgo:** un proveedor lento bloquea workers de cola, agota PHP-FPM.
**Solución:**
```php
try {
  $response = $this->httpClient->get($url, [
    'connect_timeout' => 5,
    'timeout' => 15,
  ]);
} catch (RequestException $e) {
  $this->logger->error('External API failed: @msg', ['@msg' => $e->getMessage()]);
  return NULL;
}
```

---

## Form alter en AJAX sin #process

**Problema (Media):** `hook_form_alter` modifica un elemento que se recarga vía AJAX.
**Riesgo:** el alter solo se aplica en el primer render, AJAX rebuild lo pierde.
**Solución:** usar `#process` o `#after_build`:
```php
$form['my_field']['#process'][] = '_mymodule_process_my_field';

function _mymodule_process_my_field(array &$element, FormStateInterface $form_state, array &$form): array {
  $element['#description'] = t('Custom description');
  return $element;
}
```

---

## Migración sin id_map

**Problema (Alta):** migración custom sin `id_map` definido o sin `MigrateSkipRowException` en filtros.
**Riesgo:** rollbacks corruptos, registros huérfanos detectados meses después.
**Solución:** verificar que la migración tenga `id_map` y que el source plugin lance `MigrateSkipRowException` para filas inválidas en lugar de devolver `FALSE`.
