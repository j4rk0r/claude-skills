# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de nivel experto para Claude Code. Cada skill puntuada **A+ (120/120)** antes de publicarse.

## Instalar todas

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

O instalar individualmente:

```bash
npx skills add j4rk0r/claude-skills@skill-guard -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-advisor -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-learner -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review -y -g
```

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module -y -g
```

```bash
npx skills add j4rk0r/claude-skills@milestone -y -g
```

## Skills

| Skill | Que hace |
|-------|----------|
| **[skill-guard](../skills/skill-guard/)** | Auditor de seguridad — deteccion de amenazas en 9 capas para skills antes de instalarlas. Registro comunitario de auditorias. |
| **[skill-advisor](../skills/skill-advisor/)** | Construye planes de ejecucion que combinan tus skills instaladas con los gaps que te faltan — y ofrece instalarlos. Nunca empieces una tarea sin las herramientas adecuadas. |
| **[skill-learner](../skills/skill-learner/)** | Captura errores y persiste correcciones para que el mismo fallo no se repita. Funciona con skills Y comportamiento general de Claude. Opcionalmente genera propuestas de mejora para autores. |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Revision de codigo Drupal 11 de la rama actual contra `develop` siguiendo la metodologia Codex — 18 reglas probadas en produccion con el *por que* detras de cada una. Genera un informe `.md` estructurado. |
| **[codex-pr-review](../skills/codex-pr-review/)** | Revision de pull requests Drupal 11 con la metodologia Codex — mismas 18 reglas que `codex-diff-develop` pero descarga el PR via `git fetch origin pull/<N>/head` para auditar cualquier PR de GitHub. |
| **[lint-drupal-module](../skills/lint-drupal-module/)** | Lint review paralelizado de modulos Drupal 11 combinando 4 fuentes — PHPStan level 5, PHPCS Drupal/DrupalPractice, agente `drupal-qa` (estandares) y agente `drupal-security` (OWASP). Modos completo o diff. Consolida todo en un unico informe accionable con acciones P0/P1/P2. |
| **[milestone](skills/milestone/)** | Tracker de desarrollo persistente que sobrevive entre conversaciones. Cada hito es una capsula autocontenida: objetivo, subtareas con estado, decisiones, referencias a codigo y un log de contexto. Se integra con Plan mode y todas las skills de planificacion. |

## skill-guard

> **Instalas una skill. Lee tu `~/.ssh`, coge tu `$GITHUB_TOKEN` y lo envia a un servidor remoto. No te enteras.**

skill-guard previene esto. Audita skills antes de instalarlas usando 9 capas de analisis — desde patrones estaticos hasta analisis semantico con LLM que detecta prompt injection disfrazada de instrucciones normales.

### Como funciona

```
Quieres instalar una skill
        |
        v
skill-guard consulta el registro comunitario de auditorias
        |
        v
Ya auditada (mismo SHA)?  --> Muestra informe anterior
No auditada?              --> "Quieres un analisis de seguridad?"
        |
        v
Analisis de 9 capas: permisos, patrones, scripts,
flujo de datos, abuso MCP, supply chain, reputacion...
        |
        v
Puntuacion 0-100 → VERDE / AMARILLO / ROJO
        |
        v
VERDE: auto-instala | AMARILLO: tu decides | ROJO: advertencia fuerte
```

### Las 9 capas

1. **Frontmatter y permisos** (20%) — Sin `allowed-tools`? Bash sin restricciones? Secuestro de descripcion?
2. **Patrones estaticos** (15%) — URLs, IPs, rutas sensibles, comandos peligrosos, variables de entorno
3. **Analisis semantico LLM** (30%) — Prompt injection, troyanos, ingenieria social, bombas de tiempo
4. **Scripts bundled** (15%) — Lee CADA script. Imports peligrosos, ofuscacion, exfiltracion
5. **Flujo de datos** (10%) — Mapea origen → destino. Datos sensibles llegando a URLs externas = amenaza confirmada
6. **MCP y herramientas** — Uso no declarado de MCP, exfiltracion via Slack/GitHub/Monday
7. **Supply chain** (2%) — Typosquatting, versiones sin fijar, repos falsos
8. **Reputacion** (3%) — Perfil del autor, edad del repo, forks troyanos
9. **Anti-evasion** (5%) — Trucos unicode, homoglifos, auto-modificacion, fingerprinting de entorno

### Dos modos de analisis

- **Auditoria completa** — Las 9 capas, informe completo, persistencia en registro
- **Escaneo rapido** — Solo capas 1+2+3. Auto-escala a completa si encuentra hallazgos HIGH/CRITICAL

### Registro comunitario de auditorias

Cada auditoria se guarda en [`skills/skill-guard/audits/`](../skills/skill-guard/audits/), organizada por autor verificado (anthropic, obra, softaworks, etc.). Antes de analizar, skill-guard comprueba si alguien ya audito esa version. Resultados instantaneos si el SHA coincide.

**Modelo de confianza:** Solo el sistema genera y publica resultados de auditoria. Los miembros de la comunidad solicitan auditorias mediante PR a `audits/requests/` — el mantenedor ejecuta skill-guard y publica el resultado. Esto impide que auditorias manipuladas entren en el registro.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **Instalas 50 skills. Usas 5. Las otras 45 acumulan polvo.**

skill-advisor arregla esto. Se situa entre tu y Claude, analizando cada instruccion para encontrar la mejor skill de TU coleccion instalada — antes de empezar a trabajar.

### Dos modos

**Pre-accion** — Antes de que Claude empiece a trabajar, recomienda skills que mejorarian el resultado:

```
> "fix this login bug"

Evaluacion de skills:
1. /systematic-debugging — coincide con "bug, test failure, unexpected behavior"
2. /webapp-testing — verificar el arreglo despues

Procedemos con estas? O directamente sin skill?
```

**Post-accion** — Al terminar un trabajo, sugiere el siguiente paso logico:

```
> [codigo modificado]

Skills recomendadas:
1. /webapp-testing — codigo modificado, tests necesarios
2. /verification-before-completion — antes de dar por terminado
```

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

**Pre-accion** — Antes de que Claude empiece a trabajar, recomienda skills que mejorarian el resultado.

**Post-accion** — Al terminar un trabajo, sugiere el siguiente paso logico.

### Que lo hace diferente

- **Lee TUS skills** — Sin lista fija. Escanea el system-reminder dinamicamente.
- **Piensa lateralmente** — "hazlo mas bonito" encuentra skills de diseno, animacion Y auditoria de accesibilidad.
- **Sabe cuando callarse** — Tareas simples no reciben recomendaciones.
- **Recomienda pipelines** — Detecta escenarios multi-paso y sugiere el combo completo.
- **Fallback a la comunidad** — Si nada local coincide, sugiere skills instalables.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude se disculpa, promete hacerlo mejor — y comete el mismo error en la siguiente sesion.**

skill-learner rompe ese ciclo. Cuando una skill o Claude falla, captura que salio mal, por que, y que hacer en su lugar — como un archivo de correccion persistente que sobrevive entre sesiones.

### Como funciona

```
Algo salio mal
        |
        v
skill-learner detecta que skill (o comportamiento general) fallo
        |
        v
Hace preguntas enfocadas hasta entender el error
        |
        v
Guarda una correccion estructurada en ~/.claude/skill-corrections/
        |
        v
La proxima vez que esa skill se ejecute → la correccion esta disponible
        |
        v
Opcionalmente: genera una propuesta de mejora para el autor de la skill
```

### Caracteristicas clave

- **Auto-detecta la skill que fallo** del contexto de la conversacion
- **Deduplica** — consulta INDEX.md antes de crear, fusiona si el mismo problema ya existe
- **9 reglas NEVER** — previene correcciones vagas, duplicadas, scope creep y bypass de seguridad
- **Test de lectura en frio** — verifica que cada correccion es clara para un agente diferente en otra sesion
- **Propuestas de mejora** — genera propuestas con diffs, guardadas en local para que el usuario las suba
- **Bilingue** — escribe correcciones en el idioma del usuario para preservar matices

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **Tu linter dice "todo bien" — y tres semanas despues produccion peta por un hook que solo se ejecuta en update, no en insert.**

codex-diff-develop es una skill de revision de codigo Drupal 11 que audita el diff de tu rama actual contra `develop` usando la **metodologia Codex**: 18 reglas probadas en produccion con el *por que* detras de cada una. Encuentra los bugs que tu linter no ve — los que solo aparecen a las 3am despues de un deploy.

### Como funciona

```
Tu: "revision diff develop"
        |
        v
Detecta contexto: rama, subdir drupal/, tipos de archivo en el diff
        |
        v
Carga MANDATORY las references (18 reglas Codex + 14 plantillas)
        |
        v
Aplica el framework Codex de 5 preguntas
        |
        v
Decision tree elige reglas Codex segun tipo de archivo
        |
        v
Revisa SOLO el diff, sin sugerencias fuera de alcance
        |
        v
Auto-detecta IDE → escribe informe en .vscode/.cursor/.antigravity
        |
        v
Auto-verificacion contra checklist de 12 items antes de entregar
```

### Las 18 reglas Codex — cada una con cicatriz

Cada regla incluye el **por que** (el incidente de produccion que la enseno). Algunos ejemplos:

1. **Completitud `hook_entity_insert` vs `_update`** — logica solo en `_update` se salta entidades nuevas hasta que alguien las edita
2. **Agregadas (MAX/MIN/COUNT) en tablas vacias devuelven NULL, no 0** — `$max + 1` se vuelve incoherente en el primer registro
6. **APIs externas sin `connect_timeout`** — proveedor lento bloquea workers de cola y agota PHP-FPM
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permisos que nadie revisa en PRs futuros
9. **Idempotencia en operaciones retry/doble-click** — pedidos duplicados, emails duplicados, cobros duplicados
11. **Sin kill-switch** — incidentes a las 3am sin tiempo de hacer rollback
14. **Bloques/formatters custom sin `getCacheableMetadata()`** — rompe BigPipe y Dynamic Page Cache silenciosamente

Lista completa con el *por que* detallado en [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md).

### NEVER list — 15 anti-patrones especificos de Drupal

- **NUNCA** marcar un hallazgo de estilo como "Alta" — diluye la severidad
- **NUNCA** sugerir refactors fuera del diff salvo seguridad critica
- **NUNCA** aprobar `loadMultiple([])` — devuelve TODAS las entidades (fuga de memoria clasica)
- **NUNCA** aprobar Batch API sin `finished` callback que maneje fallo
- **NUNCA** aprobar `EntityFieldManagerInterface::getFieldStorageDefinitions()` sin verificar que el field existe — zombie field storage tras delete

### Framework Codex de 5 preguntas

Antes de revisar:

1. **Que tipo de cambio es?** — determina las reglas Codex aplicables
2. **Cual es el peor caso en produccion?** — fija el suelo de severidad
3. **Que asume el cambio fuera del diff?** — schema, permisos, indices
4. **Es idempotente?** — retry, doble-click, re-deploy
5. **Se puede desactivar?** — kill-switch para incidentes a las 3am

### Output

Informe `.md` estructurado con:
- Resumen ejecutivo + conteo de severidades
- Hallazgos por categoria (Seguridad, Codex logica, Estandares/DI, Performance, A11y/i18n, Tests/CI)
- Tabla de riesgos
- Lista accionable priorizada
- Seccion "Lo positivo" (porque los elogios tambien van en los PRs)
- Checklist final

Cada hallazgo sigue **Problema (Severidad)** → **Riesgo** → **Solucion** con codigo adaptado de las 14 plantillas en `references/`.

### Auto-deteccion de IDE

Lee `CLAUDE_CODE_ENTRYPOINT` primero. Solo cae a deteccion por carpeta si el env var no es concluyente. Esto evita escribir informes en una carpeta `.cursor/` legacy cuando estas en VS Code.

### Evaluacion

- **`/skill-judge`**: 120/120 (Grado A+)
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, cero red, cero MCP

### Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **Tu reviewer dice "LGTM" — y tres semanas despues produccion peta por un hook que solo se ejecuta en update.**

codex-pr-review es la skill gemela de `codex-diff-develop` para **pull requests remotos**. Misma metodologia Codex, mismas 18 reglas, mismas plantillas — pero descarga el PR via `git fetch origin pull/<N>/head` para que puedas auditar cualquier PR de GitHub por numero.

### Como funciona

```
Tu: "revision Codex PR #42 develop ← feature/alejandro"
        |
        v
Confirma numero de PR y ramas (pregunta si faltan)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Carga las references MANDATORY (mismas que codex-diff-develop)
        |
        v
Aplica framework Codex de 5 preguntas + decision tree
        |
        v
Revisa SOLO el diff del PR
        |
        v
Auto-detecta IDE → escribe informe en <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Auto-verificacion contra checklist de 13 items antes de entregar
```

### Que cambia respecto a codex-diff-develop

Las dos skills son gemelas funcionales. Las diferencias:

| Aspecto | codex-diff-develop | codex-pr-review |
|---|---|---|
| Origen del diff | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| Carpeta de salida | `Revisiones diff/` | `Revisiones PRs/` |
| Nombre archivo | `lint-review-diff-develop-<rama>.md` | `lint-review-pr<N>.md` |
| Triggers | "diff develop", "codex diff" | "revision PR", "revisar PR #N", "codex PR" |
| NEVER extra | — | "**NUNCA** referenciar otros PRs en el documento" — clasico de revisores que mezclan discusiones |
| Edge cases extra | — | Fallback GitLab (`merge-requests/<N>/head`), PR ya mergeado, sin numero de PR |
| Pre-requisito | — | Pregunta numero de PR si no se proporciona |

### Cuando usar cual

- **`codex-diff-develop`**: trabajas localmente en una rama y quieres revisar tus propios cambios antes de pushear o abrir un PR
- **`codex-pr-review`**: quieres revisar el PR de otra persona (o el tuyo despues de pushearlo) sin hacer checkout local

### Evaluacion

- **`/skill-judge`**: 120/120 (Grado A+)
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, cero red de subida, cero MCP

### Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## lint-drupal-module

> **Tu review manual encuentra 29 issues. Ejecutas PHPStan y PHPCS a mano. Le pides a un reviewer que mire estandares y seguridad. 45 minutos despues por fin tienes una vista consolidada — y se te pasaron 140 violaciones en los JS del modulo porque nadie le paso PHPCS al JavaScript.**

lint-drupal-module ejecuta **cuatro fuentes en paralelo** — PHPStan level 5 (con `phpstan-drupal`), PHPCS Drupal/DrupalPractice, un agente `drupal-qa` para estandares y un agente `drupal-security` para vectores OWASP — y consolida los hallazgos en un unico informe accionable. Lo que antes eran 12 pasos manuales y 30 minutos ahora es una sola invocacion que termina en lo que tarda la fuente mas lenta (2-5 min completo, 30s-1min diff).

### Como funciona

```
Tu: "lint review del modulo chat_soporte_tecnico_ia"
        |
        v
Identifica el modulo (por nombre, ruta o Glob)
        |
        v
Elige modo: completo (default) | diff (vs develop)
        |
        v
Detecta DDEV / composer local, instala PHPStan si falta (preguntando)
        |
        v
Carga references/prompts-agentes.md (obligatorio antes de invocar agentes)
        |
        v
Lanza las 4 fuentes en paralelo, en el mismo mensaje:
  • Agent drupal-qa        (estandares)
  • Agent drupal-security  (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Consolida las 4 salidas en un informe markdown
        |
        v
Auto-detecta IDE → <ide>/Lint reviews/lint-review-<modulo>-<modo>-<rama>.md
        |
        v
Resume top bloqueantes y pregunta:
  "arregla todo" / "solo critico" / "auto-fix PHPCS" / "dejalo asi"
```

### Dos modos

| Modo | Cuando usarlo | Velocidad |
|---|---|---|
| **Completo** (default) | Antes de release, modulos nuevos, auditorias periodicas | ~2-5 min |
| **Diff** | Reviews intermedios, validacion pre-push, solo cambios nuevos vs `develop` | ~30s-1min |

### Que detecta que una review manual no ve

Validado contra un modulo Drupal 11 real (32 archivos). Una review manual solo con agentes reporto 29 issues. Ejecutar el pipeline paralelizado completo encontro **65 issues** — incluyendo 166 violaciones PHPCS en los JavaScript del modulo (la mayoria auto-corregibles con `phpcbf`) que la review manual nunca comprobo porque el JS estaba fuera de su alcance.

Esa es la idea: una lint review vale lo que vale su capa mas debil. Combinar analisis estatico, estandares de estilo y agentes expertos en paralelo detecta cosas que ninguna fuente por separado ve.

### Estructura del informe (fija)

1. **Resumen ejecutivo** — hallazgos por fuente, top 5 bloqueantes, veredicto categorico
2. **PHPStan level 5** — errores agrupados por archivo
3. **PHPCS Drupal/DrupalPractice** — violaciones agrupadas por archivo
4. **Estandares (drupal-qa)** — hallazgos por severidad con fixes sugeridos
5. **Seguridad (drupal-security)** — vulnerabilidades clasificadas 🔴 CRITICO / 🟠 ALTO / 🟡 MEDIO / 🟢 BAJO / ℹ️ INFO
6. **Acciones priorizadas** — P0 bloqueantes, P1 recomendados, P2 mejoras
7. **Cobertura de buenas practicas** — checklist de strict_types, hooks OOP, DI, CSRF, cache metadata, etc.
8. **Comandos de verificacion** — comandos exactos para re-ejecutar en local

### NEVER rules principales

1. **NUNCA modifica archivos durante la skill.** Solo reporta. Los fixes son una fase posterior con confirmacion explicita del usuario.
2. **NUNCA ejecuta las 4 fuentes en mensajes separados.** La paralelizacion es el valor central; en serie tarda 4× mas.
3. **NUNCA lista `Unsafe usage of new static()` en Controllers como bloqueante** — falso positivo conocido de phpstan-drupal.
4. **NUNCA elimina aliases FQCN en `services.yml` sin verificar el uso por type-hint del Hook OOP** — forma conocida de romper `drush cr`.
5. **NUNCA ejecuta `phpcbf` sobre JavaScript** — el standard Drupal convierte `null`/`true`/`false` a `NULL`/`TRUE`/`FALSE` en JS, rompiendo el codigo en runtime. Usa siempre `--extensions=php,module,inc,install,profile,theme` y `--ignore='*/js/*'`.

### Relacion con skills hermanas

- **`codex-diff-develop`** → revisa logica de negocio sobre el diff (complementa esta skill)
- **`codex-pr-review`** → review arquitectonica de PR completo (un nivel por encima)
- **Workflow ideal pre-merge:** `lint-drupal-module` → fixes mecanicos → `codex-diff-develop` → fixes de logica → `codex-pr-review` → merge

### Instalar

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

---

## milestone

> **Terminaste una feature en 3 conversaciones. La 4a empieza de cero porque el contexto no sobrevive.**

milestone almacena todo lo necesario para retomar el trabajo de desarrollo en cualquier conversacion futura — objetivo, subtareas con estado, decisiones arquitectonicas, referencias a codigo y un log cronologico inverso de que se hizo y por que. Carga un hito por nombre y empieza a trabajar inmediatamente.

### Como funciona

- `/milestone` — lista todos los hitos con estado y progreso
- `/milestone <nombre>` — carga contexto completo (fuzzy match)
- `/milestone init <nombre>` — crea nuevo hito con subtareas basadas en el codebase
- `/milestone add/done/update` — gestiona subtareas, decisiones y contexto

### Decisiones de diseno clave

- **Log de contexto append-only** — nunca borrar historial, solo anadir correcciones
- **Descubrimiento de planificadores** — detecta automaticamente las skills de planificacion instaladas
- **Skill global, datos locales** — crea `.milestones/` por proyecto
- **8 reglas NEVER** — sin milestones triviales, sin duplicados, max 10 activos

### Evaluacion

- **`/skill-guard`**: 92/100 (GREEN)

### Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

---

## Estandares de Calidad

Cada skill se evalua con el framework [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensiones, 120 puntos max. **Minimo para inclusion: B (96/120).** Coleccion actual: todo A+ (120/120).

## Contribuir

1. Fork este repo
2. Anade tu skill en `skills/<nombre>/SKILL.md`
3. Ejecuta `/skill-judge` — debe puntuar B o superior
4. Abre un PR con tu puntuacion

## Licencia

[MIT](../LICENSE)
