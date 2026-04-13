# QA Validation — `/milestone done`

La QA no es genérica — debe verificar **exactamente lo que pide la subtarea**. Leer el texto de la subtarea y extraer las afirmaciones verificables.

## Paso 1 — Extraer criterios de la subtarea

Descomponer el texto de la subtarea en afirmaciones concretas. Ejemplo:
- "Añadir endpoint AJAX para guardar config" → (a) la ruta existe, (b) responde a POST, (c) persiste datos
- "Fix bug: Hoy no carga productos" → (a) la query devuelve resultados cuando hay datos, (b) el bug original ya no se reproduce
- "Añadir botón de ajustes para superadmin" → (a) el botón se renderiza en el HTML, (b) solo para usuarios con el permiso, (c) el JS responde al click

## Paso 2 — Verificar CADA criterio: backend + frontend + diseño

No aceptar "debería funcionar". Ejecutar comandos y pruebas reales que demuestren el resultado.

### 2a — Backend

Ejecutar siempre que haya cambios en código server-side.

**Detectar stack del proyecto** y aplicar los checks correspondientes:

| Criterio | Drupal/PHP | Node/JS | Python | General |
|----------|-----------|---------|--------|---------|
| Sintaxis válida | `php -l` en cada archivo | `tsc --noEmit` o `node -c` | `python -m py_compile` | Linter del lenguaje |
| Ruta/endpoint | `drush eval` resolver ruta | `curl` al path | `curl` al path | `curl` al path esperado |
| Servicio/DI | `drush eval` obtener del contenedor | Import sin error | Import sin error | N/A |
| Variable en template | `drush eval` renderizar controller, comprobar key | Inspect render output | Inspect render output | N/A |
| Query/datos | `drush eval` ejecutar método | Test unitario o script | Test unitario o script | Ejecutar la lógica y verificar output |
| Permisos/auth | `drush eval` verificar hasPermission | Test con/sin token | Test con/sin credenciales | Probar con y sin autorización |
| Cache/rebuild | `drush cr` + re-verificar | `npm run build` sin errores | N/A | Reiniciar servicio + verificar |

### 2b — Frontend

Ejecutar siempre que la subtarea implique UI, JS, CSS, template o interacción.

**Opción A — `webapp-testing` (Playwright)** (preferida):

| Criterio | Verificación |
|----------|-------------|
| Elemento se renderiza | Navegar a la página, screenshot, comprobar que el elemento existe en el DOM |
| Botón/interacción funciona | Click en el elemento, verificar cambio de estado (panel se abre, clase CSS cambia, etc.) |
| Formulario/guardado funciona | Rellenar, enviar, verificar respuesta y que los datos persisten tras reload |
| Texto/contenido correcto | Capturar screenshot, verificar texto visible en la página |
| Solo visible para rol X | Navegar como usuario sin permiso, verificar que el elemento NO aparece |
| Responsive/layout | Screenshot a distintos viewports si la subtarea lo requiere |
| Sin errores JS en consola | Revisar logs del navegador tras la interacción |

**Opción B — Sin Playwright** (fallback):
- Renderizar HTML del servidor y buscar markup esperado
  - Drupal: `drush eval` que renderice la ruta y busque con `str_contains` o regex
  - Otros: `curl -b cookie.txt <url>` autenticado + grep del elemento
- Verificar JS: `node -c archivo.js` para sintaxis, revisar que los selectores (`data-*`, clases) del JS coinciden con los del template

### 2c — Diseño / Figma

Ejecutar cuando la subtarea tiene componente visual.

**Opción A — Figma MCP disponible** (preferida):
Usar `figma:figma-use` + `get_screenshot` para obtener el diseño original y comparar pixel-perfect.

| Criterio | Verificación |
|----------|-------------|
| Todos los elementos presentes | Comparar screenshot web vs Figma: cada elemento del diseño debe existir en la implementación |
| Espaciado y alineación | Verificar margins, paddings y gaps coinciden con el diseño (tolerancia ±2px) |
| Tipografía | Font family, size, weight, line-height y color coinciden con los tokens del diseño |
| Colores y fondos | Verificar colores de fondo, bordes, iconos y textos contra los valores del Figma |
| Iconos correctos | Cada icono usa el nombre/variante exacta del diseño |
| Estados interactivos | Hover, focus, active, disabled — verificar que existen y coinciden con el Figma si están diseñados |
| Responsive | Si el Figma tiene breakpoints, verificar layout en cada uno |

**Flujo de comparación:**
1. Obtener screenshot del Figma con `get_screenshot` del nodo correspondiente
2. Capturar screenshot de la implementación con `webapp-testing` al mismo viewport
3. Comparar visualmente ambas capturas — reportar diferencias concretas (elemento X está 8px más abajo, color del borde es #e5e7eb pero Figma dice #d1d5db, etc.)

**Opción B — Figma MCP no disponible o no responde** (fallback):
1. Buscar screenshots de referencia en `.milestones/designs/` o `assets/` del proyecto
2. Si hay screenshot de referencia → comparar visualmente contra screenshot del navegador
3. Si no hay ninguna referencia visual → indicar `⚠️ QA diseño: sin referencia Figma ni screenshot — validación visual pendiente de revisión manual`
4. **No bloquear** la subtarea por falta de Figma, pero dejar constancia en el reporte QA

**Opción C — Subtarea sin componente visual:**
Saltar este paso. Indicar "N/A — sin cambios visuales" en el reporte QA.

## Paso 3 — Veredicto estricto

- **TODOS los criterios aplicables (backend + frontend + diseño) pasan** → marcar `[x]`, añadir `✅ QA` en `## Contexto`
- **CUALQUIER criterio falla** → **NO marcar `[x]`**. Reportar: qué falló, por qué, y fix propuesto. La subtarea queda pendiente hasta que se corrija y se re-verifique.

**Formato del reporte en `## Contexto`** — una línea por fase, separadas con `|`:
```
### 2026-04-13 — Subtarea completada: Añadir botón ajustes en Te recomendamos
✅ QA backend: ruta `rec_sources_save` resuelve OK | permiso asignado a admin | `php -l` limpio | `drush cr` OK
✅ QA frontend: botón gear visible (screenshot) | click abre panel | 6 fuentes listadas | guardar mantiene datos | consola sin errores JS
✅ QA diseño: comparado vs Figma nodo 123:456 — todos los elementos presentes | spacing OK | colores match tokens Gin | icono ri-settings-4-line correcto
```
