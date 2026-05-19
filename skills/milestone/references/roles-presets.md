# Project Config Presets — Project Type + Role Templates

Milestone es agnóstico: cada proyecto define en `.milestones/config.yml` su **tipo de proyecto** y sus **roles/departamentos**. Este archivo contiene presets que se ofrecen en `/milestone init` la primera vez.

Dos dimensiones independientes:

1. **`project_type`** — el stack/dominio técnico del proyecto (drupal, laravel, react, non-code, …). Afecta cómo Claude verifica evidencia en código, qué QA aplica, y qué pistas usa para sugerir roles.
2. **`roles`** — los departamentos del equipo que ejecuta el proyecto (Frontend, Backend, Strategy, Analyst, Partner, …). Afecta las etiquetas `[Dept]` obligatorias de cada subtarea.

Los dos se almacenan en `.milestones/config.yml`. Un equipo puede ser "dev web" (`industry: software-dev`) trabajando en un proyecto Laravel (`project_type: laravel`), o una consultora (`industry: consulting`) trabajando en un entregable no-código (`project_type: non-code`).

## Flujo en `/milestone init` (primera vez en un proyecto)

Cuando `.milestones/config.yml` NO existe, ejecutar en este orden:

### Step 0 — Project type

Defaults a `drupal` (el preset del mantenedor). Preguntar:

```
¿Qué tipo de proyecto es este?

Por defecto uso: drupal

Otras opciones:
  a) drupal (default)
  b) laravel
  c) react / react-native
  d) nextjs
  e) vue / nuxt
  f) wordpress
  g) symfony
  h) django / fastapi
  i) rails
  j) spring-boot / java
  k) dotnet
  l) mobile-ios (swift)
  m) mobile-android (kotlin)
  n) non-code (consultoría, auditoría, legal, investigación, entregable sin repo)
  o) otro — dime cuál
```

El valor elegido se guarda en `project_type` del YAML y afecta:

- Cómo Claude hace grep/evidencia de código al evaluar subtareas en `init` y `sync`.
- Qué cargar de `qa-validation.md` (p.ej. `non-code` salta QA técnico y usa checklist de deliverable).
- Qué rol preset sugerir por defecto en Step A (p.ej. `drupal` → roles web dev; `non-code` → preguntar industria en Step B directamente).

### Step A — Roles por defecto

Si `project_type` es un stack de código (drupal/laravel/react/…), sugerir los roles del mantenedor:

```
Proyecto: <project_type>.

Todavía no hay roles definidos para este proyecto. Por defecto uso estos (web/software dev):
  • Frontend — UI, interacción cliente, behaviors
  • UX/UI — diseño, skeletons, jerarquía visual, flujos
  • Backend — servicios, controllers, APIs, cache, DI
  • QA — tests unitarios/funcionales, validación manual
  • Sitebuilding — configuración CMS (permisos, rutas, content types)
  • CTO — arquitectura, revisión PR, merge

¿Los uso para este proyecto?
  a) Sí, úsalos tal cual
  b) No, personaliza
  c) Añade/quita alguno (dime cuáles)
```

Si `project_type: non-code` → saltar directo a Step B (preguntar industria).

### Step B — Industria (si el usuario elige "b" o project_type es non-code)

```
¿Qué tipo de empresa/proyecto?
  1) Consultoría (estrategia, transformación, change management)
  2) Auditoría financiera / compliance
  3) Bufete legal / abogados
  4) Agencia creativa / marketing
  5) Investigación académica / I+D
  6) Farmacéutica / salud / medical device
  7) Fintech / banca / seguros
  8) E-commerce / retail
  9) Industrial / manufactura / supply chain
  10) Otro — descríbemelo y te propongo roles
```

Tras la selección, cargar preset correspondiente y preguntar: *"¿Los acepto tal cual, o editamos?"*

### Step C — Guardar elección

```yaml
# .milestones/config.yml
# Configuración del proyecto. Toda subtarea termina en [Role1, Role2, ...].
project_type: drupal       # metadata: cómo verificar código y qué QA aplicar
industry: software-dev     # metadata: tipo de equipo que opera
roles:
  - name: Frontend
    description: UI, interacción cliente, behaviors
  - name: Backend
    description: Servicios, controllers, APIs, cache, DI
  # ...
```

### Step D — Validación permanente

En todos los milestones subsiguientes, validar que cada `[Role]` exista en `config.yml`. Si no → pedir elegir uno válido o añadirlo al archivo.

## Presets de `project_type`

### drupal (default)
- Verificación código: módulos en `web/modules/custom/`, `.info.yml`, `composer.json` con `drupal/core`, configuración en `config/sync/`.
- QA técnico: backend (Drupal/PHP) + frontend (Twig/JS/Theme) + sitebuilding (config export) + Figma match.
- Roles sugeridos: preset web/software dev.

### laravel
- Verificación: `app/`, `routes/`, `resources/views/`, `composer.json` con `laravel/framework`.
- QA: backend (PHP/Eloquent) + frontend (Blade/Livewire/Inertia) + Figma match.
- Roles sugeridos: preset web/software dev (Sitebuilding → omitido o renombrado).

### react / react-native
- Verificación: `src/`, `package.json` con `react`, hooks/componentes/routing.
- QA: frontend (tests + render) + integración API + Figma match.
- Roles sugeridos: Frontend, UX/UI, Backend (si hay API), QA, CTO.

### nextjs
- Verificación: `app/` o `pages/`, `package.json` con `next`, SSR/SSG, API routes.
- QA: frontend + API routes + deploy Vercel/edge + Figma match.
- Roles sugeridos: Frontend, UX/UI, Backend, DevOps, QA, CTO.

### vue / nuxt
- Verificación: `src/` o `pages/`, `package.json` con `vue` o `nuxt`.
- QA: frontend + SSR (Nuxt) + Figma match.
- Roles sugeridos: preset web/software dev (Sitebuilding → omitido).

### wordpress
- Verificación: `wp-content/themes/`, `wp-content/plugins/`, `functions.php`.
- QA: backend (PHP/hooks) + frontend (theme) + admin (custom post types, ACF) + Figma match.
- Roles sugeridos: Frontend, UX/UI, Backend, Sitebuilding (ACF/admin), QA, CTO.

### symfony
- Verificación: `src/`, `config/`, `composer.json` con `symfony/framework-bundle`.
- QA: backend (Symfony/Doctrine) + frontend (Twig) + Figma match.
- Roles sugeridos: preset web/software dev.

### django / fastapi
- Verificación: `apps/` o `<project>/`, `requirements.txt` / `pyproject.toml`, `urls.py` / FastAPI routers.
- QA: backend (Python/tests) + frontend si aplica (templates o SPA) + API contract.
- Roles sugeridos: Frontend (si aplica), UX/UI (si aplica), Backend, QA, CTO.

### rails
- Verificación: `app/`, `config/`, `Gemfile` con `rails`.
- QA: backend (Ruby/ActiveRecord) + frontend (ERB/Turbo/Stimulus) + Figma match.
- Roles sugeridos: preset web/software dev.

### spring-boot / java
- Verificación: `src/main/java/`, `pom.xml` / `build.gradle` con `spring-boot`.
- QA: backend (Java/JUnit) + API contract.
- Roles sugeridos: Backend, Frontend (si aplica), DevOps, QA, Arquitecto.

### dotnet
- Verificación: `*.csproj`, `Program.cs`, `Startup.cs` / minimal API.
- QA: backend (C#/xUnit) + frontend (Blazor/Razor/SPA) + API contract.
- Roles sugeridos: Backend, Frontend, DevOps, QA, Arquitecto.

### mobile-ios (swift)
- Verificación: `*.xcodeproj`, `Package.swift`, `Sources/`, SwiftUI/UIKit.
- QA: unit tests (XCTest), UI tests, App Store compliance, Figma match.
- Roles sugeridos: iOS Dev, UX/UI, Backend (API), QA, Release Manager.

### mobile-android (kotlin)
- Verificación: `app/src/main/java/`, `build.gradle.kts`, Jetpack Compose / XML.
- QA: unit tests (JUnit), instrumented tests (Espresso), Play Store compliance, Figma match.
- Roles sugeridos: Android Dev, UX/UI, Backend (API), QA, Release Manager.

### non-code
- Verificación: sin grep en código; evidencia por entregables en `deliverables/`, `docs/`, drive, docs externos. Claude pregunta al usuario por el estado real de cada subtarea.
- QA: checklist del entregable (revisión por cliente / comité / steering), no QA técnico.
- Roles sugeridos: saltar Step A y preguntar industria (Step B) — consultoría/auditoría/legal/research/etc.

### otro (custom)
- Preguntar al usuario: *"Descríbeme el stack, el tipo de artefacto que produce y cómo validáis que una tarea está terminada"*.
- Generar descripción en `config.yml` con `project_type: custom` y `custom_notes: <resumen>`.
- Roles sugeridos: preguntar industria (Step B).

## Presets de `roles` por industria

### 1. software-dev (default para project_type = drupal/laravel/symfony/wordpress/rails/vue)
- **Frontend** — UI, interacción cliente, behaviors
- **UX/UI** — diseño, skeletons, jerarquía visual, flujos
- **Backend** — servicios, controllers, APIs, cache, DI
- **QA** — tests unitarios/funcionales, validación manual
- **Sitebuilding** — configuración CMS (permisos, rutas, content types)
- **CTO** — arquitectura, revisión PR, merge

### 2. consulting
- **Strategy** — diagnóstico del problema, hipótesis, framing para comité
- **Research** — benchmarks, entrevistas, análisis de mercado/datos
- **Analyst** — modelado cuantitativo, decks, deliverables
- **Manager** — calidad de entregable, coordinación cliente
- **Partner** — sign-off final, steering committee, relación senior

### 3. audit (financiera / compliance)
- **Staff** — ejecución de pruebas, papeles de trabajo
- **Senior** — revisión de papeles, coordinación equipo
- **Manager** — revisión de riesgo, ajustes, comunicación cliente
- **Partner** — firma de dictamen, responsabilidad final
- **Technical Review** — consulta técnica (NIA, IFRS, normativa sectorial)
- **Quality** — revisión independiente EQCR

### 4. legal
- **Associate** — redacción de escritos, investigación jurídica
- **Senior Associate** — revisión y estrategia de caso
- **Partner** — estrategia global, comparecencias, cliente
- **Paralegal** — documentación, plazos procesales, notificaciones
- **Compliance** — conflicto de intereses, KYC, blanqueo

### 5. creative (agencia / marketing)
- **Creative** — dirección creativa, copy, storyboard
- **Art Director** — diseño visual, guidelines, selección fotografía
- **Strategy** — planning, brief, research audiencia
- **Account** — cliente, brief, coordinación
- **Production** — producción audiovisual, postpro, tráfico
- **Media** — planificación y compra de medios

### 6. research (académica / I+D)
- **PI** — principal investigator, dirección científica
- **Postdoc** — diseño experimental, análisis
- **PhD Student** — ejecución experimental, papers
- **Lab Tech** — operación equipos, reactivos, protocolos
- **Statistician** — diseño estadístico, modelado
- **Ethics** — comité ético, consentimientos, IRB

### 7. pharma (farma / salud / medical device)
- **Regulatory** — dosieres, FDA/EMA/AEMPS submissions
- **Clinical** — diseño ensayo, CRF, monitorización
- **QA** — validación sistemas, CAPA, auditoría interna
- **Medical** — medical affairs, publicaciones, MSL
- **R&D** — formulación, escalado, analítica
- **Pharmacovigilance** — farmacovigilancia, señales, PSUR
- **Legal** — contratos, licencias, patentes

### 8. fintech (banca / seguros)
- **Product** — roadmap, user stories, métricas producto
- **Engineering** — backend, frontend, mobile
- **Risk** — modelos de riesgo, credit scoring, fraud
- **Compliance** — KYC/AML, PSD2, GDPR, regulatorio
- **Operations** — payment ops, reconciliación, soporte
- **Legal** — contratos, términos, regulatorio bancario

### 9. ecommerce (retail)
- **Merchandising** — catálogo, pricing, promociones
- **Marketing** — SEO, SEM, social, email
- **Operations** — fulfillment, inventario, devoluciones
- **CX** — atención cliente, post-venta
- **Tech** — plataforma, integraciones, POS
- **Finance** — márgenes, forecast, P&L

### 10. industrial (manufactura / supply chain)
- **Engineering** — diseño producto, CAD, prototipos
- **Production** — planta, líneas, OEE
- **Quality** — QC, ISO, ensayos
- **Supply Chain** — compras, logística, inventario
- **Maintenance** — mantenimiento preventivo, predictivo
- **EHS** — environment, health, safety

## Roles custom (industria "otro")

Si el usuario elige "10) Otro" en Step B:

1. Preguntar: *"Descríbeme el tipo de empresa, tamaño, y qué tipo de proyectos gestionas"*.
2. Generar lista de 5-8 roles específicos con descripción.
3. Mostrar propuesta y permitir editar.
4. Guardar en `config.yml` con `industry: custom`.

## Edición posterior

El usuario puede en cualquier momento:
- **Cambiar `project_type`**: editar `config.yml` directamente, o decir "cambia el tipo a laravel". Advertir si hay milestones con subtareas verificadas contra código del tipo anterior (pueden quedar desalineadas).
- **Añadir rol**: editar `config.yml`, o pedir "añade el rol X al proyecto".
- **Renombrar rol**: Claude hace `grep` + rename en todos los `.milestones/*.md` existentes.
- **Eliminar rol**: avisar si hay subtareas usándolo y preguntar reasignación.

## Validación en cada operación

- `/milestone init` → Si no hay `config.yml`, ejecutar Step 0 → A → B → C → D. Después proponer subtareas usando solo roles válidos y verificando evidencia según `project_type`.
- `/milestone update` y `/milestone sync` → validar que cada `[Role]` en subtareas exista en `config.yml`. Roles inválidos → flag como "rol desconocido, ¿renombrar o añadir al proyecto?".
- Rendering (B) → funciona idéntico; el formato `[Role1, Role2]` es igual para cualquier lista.

## Compatibilidad con archivos legacy

- `.milestones/roles.yml` sin `project_type` → asumir `drupal` + `industry: software-dev` y migrar al siguiente `/milestone sync` renombrando a `config.yml`.
- Milestones existentes sin `config.yml` → al primer comando, preguntar Step 0 + A y generar. No romper milestones viejos.
