# Metodología Codex completa — 18 puntos con cicatrices

Cada punto incluye el **PORQUÉ**: la cicatriz que enseñó la regla en producción Drupal.

---

1. **hook_entity_insert vs hook_entity_update — completitud.**
   Si la lógica vive solo en `_update`, las entidades nuevas no se procesan hasta que alguien las edite.
   *Por qué:* incidente típico — campañas que no se enviaban hasta que el editor reabría el nodo.

2. **Agregadas (MAX/MIN/COUNT) sobre tablas vacías devuelven NULL, no 0.**
   Comprobar fallback explícito.
   *Por qué:* en el primer registro de la vida del módulo, `$max + 1` se vuelve incoherente y rompe el orden de elementos.

3. **Interpolación directa en SQL** (sin `:placeholders` ni `Connection::escapeLike`).
   *Por qué:* SQL injection + apóstrofos en nombres reales rompen la query antes de que llegue a producción.

4. **Recursión en hooks de entidad.**
   Si dentro de `hook_entity_update` se llama a `$entity->save()` o algo que vuelve a disparar el mismo hook, debe haber guarda estática.
   *Por qué:* loops infinitos detectados solo en cron, no en pruebas manuales.

5. **Múltiples escrituras sin transacción.**
   Si se escribe en varias tablas o se mezcla BD + API externa, evaluar `\Drupal::database()->startTransaction()`.
   *Por qué:* estados inconsistentes tras fallo parcial = pesadilla de soporte.

6. **APIs externas sin timeout, retry ni logging estructurado.**
   Verificar `connect_timeout`, `timeout`, manejo de `RequestException`, y qué pasa con datos locales si falla la llamada.
   *Por qué:* un proveedor lento bloquea workers de cola y agota PHP-FPM.

7. **`accessCheck(FALSE)` en entityQuery sin comentario justificativo en el propio código.**
   *Por qué:* bypass silencioso de permisos que nadie revisa en PRs futuros — la línea sobrevive años.

8. **Cache invalidation insuficiente.**
   Modificar datos cacheados sin invalidar `cache_tags` correctos → contenido obsoleto en producción.
   *Por qué:* "en local funciona" clásico tras deploy en multi-instance.

9. **Idempotencia en operaciones expuestas a retry/doble clic.**
   Webhooks, formularios, cron — ¿qué pasa si se ejecuta dos veces?
   *Por qué:* duplicados en pedidos, emails enviados dos veces, cobros repetidos.

10. **Coherencia de tipos** entre código, schema y BD (bool vs int 0/1, string vs int en IDs).
    *Por qué:* `===` falla silencioso, queries con `WHERE id = '5'` vs `5` en MySQL strict mode.

11. **Funcionalidad sin kill-switch.**
    Toda feature que pueda dar problemas debe poder desactivarse vía config/settings sin redeploy.
    *Por qué:* incidentes a las 3am sin tiempo de hacer rollback de código.

12. **Form alterations en formularios AJAX** sin `#process` / `#after_build`.
    *Por qué:* el alter solo se aplica en el primer render, no tras AJAX rebuild — bug invisible en QA.

13. **DI vs `\Drupal::service()` en código nuevo.**
    Aceptable solo en `.module` files o legacy; nunca en clases nuevas (Controllers, Plugins, Forms, Services).
    *Por qué:* bloquea tests unitarios y kernel tests, perpetúa deuda.

14. **Field formatters / blocks custom sin `getCacheableMetadata()`.**
    *Por qué:* rompe BigPipe y Dynamic Page Cache silenciosamente — degradación detectada solo en producción.

15. **Config schema desactualizado tras añadir/cambiar campos.**
    *Por qué:* `drush cex` exporta valores, pero al importar en otro entorno revienta por validación de schema.

16. **Migraciones sin `id_map` limpio o sin `MigrateSkipRowException` en filtros.**
    *Por qué:* rollbacks corruptos detectados meses después, datos huérfanos sin trazabilidad.

17. **Update hooks no idempotentes** (asumen estado inicial).
    *Por qué:* re-ejecución manual tras fallo parcial deja la BD peor que antes.

18. **Config overrides en `settings.php` que se solapan con config split.**
    *Por qué:* el override no aparece en `cex` y los cambios se pierden silenciosamente en cada deploy.
