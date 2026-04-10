# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de nivel especialista para Claude Code. Cada skill avaliada com **A+ (120/120)** antes da publicacao.

## Instalar tudo

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

Ou instalar individualmente:

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

```bash
npx skills add j4rk0r/claude-skills@usage-tracker -y -g
```

## Skills

| Skill | O que faz |
|-------|-----------|
| **[skill-guard](../skills/skill-guard/)** | Detecta skills maliciosas antes que toquem seus arquivos, tokens ou chaves. Analise em 9 camadas + registro de auditorias verificado. |
| **[skill-advisor](../skills/skill-advisor/)** | Constroi planos de execucao combinando skills instaladas com gaps que faltam — e oferece instala-los. Nunca comece uma tarefa sem as ferramentas certas. |
| **[skill-learner](../skills/skill-learner/)** | Captura erros e persiste correcoes para que o mesmo erro nunca se repita. Funciona para skills E comportamento geral do Claude. Opcionalmente gera propostas de melhoria para autores. |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Revisao de codigo Drupal 11 da branch atual contra `develop` seguindo a metodologia Codex — 18 regras testadas em producao com o *porque* atras de cada uma. Gera um relatorio `.md` estruturado. |
| **[codex-pr-review](../skills/codex-pr-review/)** | Revisao de pull requests Drupal 11 com a metodologia Codex — mesmas 18 regras que `codex-diff-develop` mas baixa o PR via `git fetch origin pull/<N>/head` para auditar qualquer PR do GitHub. |
| **[lint-drupal-module](../skills/lint-drupal-module/)** | Lint review paralelizado de modulos Drupal 11 combinando 4 fontes — PHPStan level 5, PHPCS Drupal/DrupalPractice, agente `drupal-qa` (padroes) e agente `drupal-security` (OWASP). Modos completo ou diff. Consolida tudo num unico relatorio acionavel com acoes P0/P1/P2. |
| **[milestone](skills/milestone/)** | Tracker de desenvolvimento persistente que sobrevive entre conversas. Cada marco e uma capsula autocontida: objetivo, subtarefas com status, decisoes, referencias de codigo e log de contexto. Integra-se com Plan mode e todas as skills de planejamento. |
| **[usage-tracker](../skills/usage-tracker/)** | Hook PostToolUse que registra cada chamada de ferramenta em `~/.claude/usage.jsonl`. Veja exatamente quanto custa cada solicitação do usuário — por projeto, sessão, dia e ferramenta. |

## skill-guard

> **Voce instala uma skill. Ela le seu `~/.ssh`, pega seu `$GITHUB_TOKEN` e envia para um servidor remoto. Voce nao percebe.**

skill-guard previne isso. Audita skills antes da instalacao usando 9 camadas de analise — de padroes estaticos a analise semantica com LLM que detecta injecao de prompt disfarçada de instrucoes normais.

### Como funciona

```
Voce quer instalar uma skill
        |
        v
skill-guard consulta o registro comunitario de auditorias
        |
        v
Ja auditada (mesmo SHA)?  --> Mostra relatorio anterior
Nao auditada?              --> "Analise de seguranca antes de instalar?"
        |
        v
Analise de 9 camadas: permissoes, padroes, scripts,
fluxo de dados, abuso MCP, supply chain, reputacao...
        |
        v
Score 0-100 → VERDE / AMARELO / VERMELHO
        |
        v
VERDE: auto-instala | AMARELO: voce decide | VERMELHO: aviso forte
```

### As 9 camadas

1. **Frontmatter e permissoes** (20%) — Sem `allowed-tools`? Bash sem restricoes?
2. **Padroes estaticos** (15%) — URLs, IPs, caminhos sensiveis, comandos perigosos
3. **Analise semantica LLM** (30%) — Injecao de prompt, trojans, engenharia social
4. **Scripts bundled** (15%) — Le CADA script. Imports perigosos, ofuscacao
5. **Fluxo de dados** (10%) — Mapeia origem → destino. Dados sensiveis em URLs externas = ameaca
6. **MCP e ferramentas** — Uso MCP nao declarado, exfiltracao via Slack/GitHub/Monday
7. **Supply chain** (2%) — Typosquatting, versoes nao fixadas, repos falsos
8. **Reputacao** (3%) — Perfil do autor, idade do repo, forks trojans
9. **Anti-evasao** (5%) — Truques unicode, homoglifos, auto-modificacao

### Dois modos de analise

- **Auditoria completa** — 9 camadas, relatorio completo, persistencia no registro
- **Scan rapido** — Apenas camadas 1+2+3. Auto-escalada se encontrar HIGH/CRITICAL

**Modelo de confiança:** Apenas o sistema gera e publica resultados de auditoria. Membros da comunidade solicitam auditorias via PR em `audits/requests/` — o mantenedor executa o skill-guard e publica o resultado. Isso impede que auditorias adulteradas entrem no registro.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **Voce instala 50 skills. Usa 5. As outras 45 juntam poeira.**

skill-advisor resolve isso. Fica entre voce e o Claude, analisando cada instrucao para encontrar a melhor skill da SUA colecao instalada — antes de qualquer trabalho comecar.

### Como funciona

```
Voce digita uma instrucao
        |
        v
skill-advisor escaneia suas skills instaladas
        |
        v
Match?     --> Recomenda 1-5, ordenadas por impacto
Sem match? --> Continua silenciosamente (ou sugere uma para instalar)
```

### Dois modos

**Pre-acao** — Antes do Claude comecar, recomenda skills que melhorariam o resultado.

**Pos-acao** — Apos completar o trabalho, sugere o proximo passo logico.

### O que o torna diferente

- **Le SUAS skills** — Sem lista fixa. Escaneia o system-reminder dinamicamente.
- **Pensa lateralmente** — "deixa mais bonito" encontra skills de design, animacao E auditoria de acessibilidade.
- **Sabe quando ficar quieto** — Tarefas simples nao recebem recomendacoes.
- **Recomenda pipelines** — Detecta cenarios multi-etapa e sugere o combo completo.
- **Fallback para comunidade** — Se nada local corresponder, sugere skills instalaveis.

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude pede desculpa, promete melhorar — e comete exatamente o mesmo erro na proxima sessao.**

skill-learner quebra esse ciclo. Quando uma skill ou o Claude erra, captura o que deu errado, por que, e o que fazer diferente — como um arquivo de correcao persistente que sobrevive entre sessoes.

### Caracteristicas principais

- **Detecta automaticamente a skill com falha** a partir do contexto da conversa
- **Deduplica** — verifica INDEX.md antes de criar, mescla se o mesmo problema ja existe
- **9 regras NEVER** — previne correcoes vagas, duplicatas e bypass de seguranca
- **Teste de leitura a frio** — verifica que cada correcao e clara para um agente diferente
- **Propostas de melhoria** — gera propostas com diffs para o autor da skill
- **Bilingue** — escreve correcoes no idioma do usuario

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

### Como funciona

```
Algo deu errado
        |
        v
skill-learner detecta qual skill (ou comportamento geral) falhou
        |
        v
Faz perguntas focadas ate entender o erro
        |
        v
Salva uma correcao estruturada em ~/.claude/skill-corrections/
        |
        v
Proxima execucao da skill → correcao disponivel
        |
        v
Opcionalmente: gera uma proposta de melhoria para o autor da skill
```

### Caracteristicas principais

- **Detecta automaticamente a skill com falha** a partir do contexto da conversa
- **Deduplica** — verifica INDEX.md antes de criar, mescla se o mesmo problema ja existe
- **9 regras NEVER** — previne correcoes vagas, duplicatas e bypass de seguranca
- **Teste de leitura a frio** — verifica que cada correcao e clara para um agente diferente
- **Propostas de melhoria** — gera propostas com diffs para o autor da skill
- **Bilingue** — escreve correcoes no idioma do usuario

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **Seu linter diz "esta tudo bem" — e tres semanas depois a producao quebra por causa de um hook que so roda em update, nao em insert.**

codex-diff-develop e uma skill de revisao de codigo Drupal 11 que audita o diff da sua branch atual contra `develop` usando a **metodologia Codex**: 18 regras testadas em producao com o *porque* atras de cada uma. Encontra os bugs que seu linter nao ve — os que so aparecem as 3 da manha depois de um deploy.

### Como funciona

```
Voce: "revisao diff develop"
        |
        v
Detecta contexto: branch, subdir drupal/, tipos de arquivo no diff
        |
        v
Carrega MANDATORY as references (18 regras Codex + 14 templates)
        |
        v
Aplica o framework Codex de 5 perguntas
        |
        v
Decision tree escolhe regras Codex por tipo de arquivo
        |
        v
Revisa SO o diff, sem sugestoes fora de escopo
        |
        v
Auto-detecta IDE → escreve relatorio em .vscode/.cursor/.antigravity
        |
        v
Auto-verificacao contra checklist de 12 itens antes de entregar
```

### As 18 regras Codex — cada uma com cicatriz

Cada regra inclui o **porque** (o incidente de producao que ensinou):

1. **Completude `hook_entity_insert` vs `_update`** — logica so em `_update` pula entidades novas
2. **Agregadas (MAX/MIN/COUNT) em tabelas vazias retornam NULL, nao 0**
6. **APIs externas sem `connect_timeout`** — provedor lento bloqueia workers de fila
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permissoes
9. **Idempotencia em retry/duplo-clique** — pedidos duplicados, emails duplicados
11. **Sem kill-switch** — incidentes as 3 da manha sem tempo de redeploy
14. **Blocos/formatters custom sem `getCacheableMetadata()`** — quebra BigPipe silenciosamente

Lista completa com o *porque* em [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md).

### NEVER list — 15 anti-padroes especificos de Drupal

- **NUNCA** marcar um achado de estilo como "Alta" — dilui a severidade
- **NUNCA** sugerir refactors fora do diff exceto seguranca critica
- **NUNCA** aprovar `loadMultiple([])` — retorna TODAS as entidades (vazamento de memoria classico)
- **NUNCA** aprovar Batch API sem callback `finished` que trate falha

### Framework Codex de 5 perguntas

1. **Que tipo de mudanca e essa?**
2. **Qual o pior cenario em producao?**
3. **O que a mudanca assume fora do diff?**
4. **E idempotente?**
5. **Pode ser desativada?**

### Output

Relatorio `.md` estruturado: resumo executivo, achados por categoria (Seguranca, Codex, Standards/DI, Performance, A11y/i18n, Tests/CI), tabela de riscos, lista acionavel, secao "O positivo", checklist final. Cada achado segue **Problema (Severidade)** → **Risco** → **Solucao**.

### Auto-deteccao de IDE

Le `CLAUDE_CODE_ENTRYPOINT` primeiro. So cai para deteccao por pasta se a env var nao for conclusiva.

### Avaliacao

- **`/skill-judge`**: 120/120 (Grau A+)
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, zero rede, zero MCP

### Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **Seu reviewer diz "LGTM" — e tres semanas depois a producao quebra por causa de um hook que so roda em update.**

codex-pr-review e a skill irma de `codex-diff-develop` para **pull requests remotos**. Mesma metodologia Codex, mesmas 18 regras, mesmos templates — mas baixa o PR via `git fetch origin pull/<N>/head` para que voce possa auditar qualquer PR do GitHub por numero.

### Diferencas com codex-diff-develop

| Aspecto | codex-diff-develop | codex-pr-review |
|---|---|---|
| Origem do diff | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| Pasta de saida | `Revisiones diff/` | `Revisiones PRs/` |
| Nome do arquivo | `lint-review-diff-develop-<branch>.md` | `lint-review-pr<N>.md` |
| Triggers | "diff develop", "codex diff" | "revisao PR", "revisar PR #N", "codex PR" |
| NEVER extra | — | "**NUNCA** referenciar outros PRs no documento" |
| Edge cases extra | — | Fallback GitLab, PR ja merged, sem numero de PR |

### Quando usar qual

- **`codex-diff-develop`**: voce trabalha localmente em uma branch e quer revisar suas proprias mudancas antes de pushar
- **`codex-pr-review`**: voce quer revisar o PR de outra pessoa (ou o seu depois de pushar) sem fazer checkout local

### Avaliacao

- **`/skill-judge`**: 120/120 (Grau A+)
- **`/skill-guard`**: 100/100 (VERDE)

### Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## lint-drupal-module

> **Tua revisao manual de codigo encontra 29 issues. Rodas PHPStan e PHPCS a mao. Pedes a um reviewer para olhar padroes e seguranca. 45 minutos depois finalmente tens uma visao consolidada — e perdeste 140 violacoes nos ficheiros JS do modulo porque ninguem correu PHPCS contra o JavaScript.**

lint-drupal-module executa **quatro fontes em paralelo** — PHPStan level 5 (com `phpstan-drupal`), PHPCS Drupal/DrupalPractice, um agente `drupal-qa` para padroes e um agente `drupal-security` para vetores OWASP — e consolida os achados num unico relatorio acionavel. O que antes eram 12 passos manuais e 30 minutos agora e uma unica invocacao que termina no tempo que demora a fonte mais lenta (2-5 min completo, 30s-1min diff).

### Como funciona

```
Tu: "lint review do modulo chat_soporte_tecnico_ia"
        |
        v
Identifica o modulo (por nome, caminho ou Glob)
        |
        v
Escolhe o modo: completo (padrao) | diff (vs develop)
        |
        v
Deteta DDEV / composer local, instala PHPStan se faltar (perguntando)
        |
        v
Carrega references/prompts-agentes.md (obrigatorio antes de invocar agentes)
        |
        v
Lanca 4 fontes em paralelo, na mesma mensagem:
  • Agent drupal-qa         (padroes)
  • Agent drupal-security   (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Consolida as 4 saidas num relatorio markdown
        |
        v
Auto-deteta o IDE → <ide>/Lint reviews/lint-review-<modulo>-<modo>-<branch>.md
        |
        v
Resume os top bloqueadores e pergunta:
  "arregla todo" / "solo critico" / "auto-fix PHPCS" / "dejalo asi"
```

### Dois modos

| Modo | Quando usar | Velocidade |
|---|---|---|
| **Completo** (padrao) | Antes de release, modulos novos, auditorias periodicas | ~2-5 min |
| **Diff** | Revisoes intermedias, validacao pre-push, so alteracoes vs `develop` | ~30s-1min |

### O que deteta que uma revisao manual nao ve

Validado contra um modulo Drupal 11 real (32 ficheiros). Uma revisao manual apenas com agentes sinalizou 29 issues. A skill a correr o seu pipeline paralelizado completo trouxe a superficie **65 issues** — incluindo 166 violacoes PHPCS no JavaScript do modulo (a maioria auto-corrigiveis com `phpcbf`) que o reviewer manual nunca verificou porque JS estava fora do seu ambito.

E esse o ponto: uma lint review so vale o que vale a sua camada mais fraca. Combinar analise estatica, aplicacao de estilo e agentes experts em paralelo captura coisas que nenhuma fonte isolada ve.

### Estrutura do relatorio (fixa)

1. **Resumo executivo** — achados por fonte, top 5 bloqueadores, veredicto categorico
2. **PHPStan level 5** — erros agrupados por ficheiro
3. **PHPCS Drupal/DrupalPractice** — violacoes agrupadas por ficheiro
4. **Padroes (drupal-qa)** — achados por severidade com sugestoes de correcao
5. **Seguranca (drupal-security)** — vulnerabilidades classificadas 🔴 CRITICO / 🟠 ALTO / 🟡 MEDIO / 🟢 BAIXO / ℹ️ INFO
6. **Acoes priorizadas** — P0 bloqueadores, P1 recomendados, P2 melhorias
7. **Cobertura de boas praticas** — checklist de strict_types, hooks OOP, DI, CSRF, cache metadata, etc.
8. **Comandos de verificacao** — comandos exatos para re-executar localmente

### Regras NEVER principais

1. **NUNCA modifica ficheiros durante a skill.** Apenas relata. As correcoes sao uma fase separada com confirmacao explicita do utilizador.
2. **NUNCA executa as 4 fontes em mensagens separadas.** A paralelizacao e o valor central; em serie demora 4× mais.
3. **NUNCA lista `Unsafe usage of new static()` em Controllers como bloqueador** — falso positivo conhecido de phpstan-drupal.
4. **NUNCA remove aliases FQCN em `services.yml` sem verificar o uso por type-hint do Hook OOP** — forma conhecida de partir `drush cr`.
5. **NUNCA executa `phpcbf` sobre JavaScript** — o standard Drupal converte `null`/`true`/`false` para `NULL`/`TRUE`/`FALSE` em JS, partindo o codigo em runtime. Usa sempre `--extensions=php,module,inc,install,profile,theme` e `--ignore='*/js/*'`.

### Relacao com skills irmas

- **`codex-diff-develop`** → reve logica de negocio sobre o diff (complementa esta skill)
- **`codex-pr-review`** → review arquitetural de um PR completo (um nivel acima)
- **Workflow ideal pre-merge:** `lint-drupal-module` → correcoes mecanicas → `codex-diff-develop` → correcoes de logica → `codex-pr-review` → merge

### Instalar

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

---

## milestone

> **Terminou uma feature em 3 conversas. A 4a comeca do zero porque o contexto nao sobrevive.**

milestone armazena tudo o necessario para retomar o trabalho de desenvolvimento em qualquer conversa futura — objetivo, subtarefas com status, decisoes arquitetonicas, referencias de codigo e um log cronologico inverso do que foi feito e por que. Carrega um marco por nome e comeca a trabalhar imediatamente.

### Como funciona

- `/milestone` — lista todos os marcos com status e progresso
- `/milestone <nome>` — carrega contexto completo (fuzzy match)
- `/milestone init <nome>` — cria novo marco com subtarefas baseadas no codebase
- `/milestone add/done/update` — gere subtarefas, decisoes e contexto

### Decisoes de design chave

- **Log de contexto append-only** — nunca apagar historico, apenas adicionar correcoes
- **Descoberta de planificadores** — deteta automaticamente as skills de planeamento instaladas
- **Skill global, dados locais** — cria `.milestones/` por projeto
- **8 regras NEVER** — sem milestones triviais, sem duplicados, max 10 ativos

### Avaliacao

- **`/skill-guard`**: 92/100 (GREEN)

### Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

---

## usage-tracker

> **Você usa Claude Max. Sem cobrança por token. Mas não tem ideia de qual projeto, conversa ou solicitação está consumindo seus limites de contexto.**

usage-tracker resolve isso. Um hook PostToolUse captura cada chamada de ferramenta com seus tokens, projeto e a solicitação do usuário que a desencadeou — transformando um histórico de uso opaco num breakdown acionável por solicitação, projeto, sessão, ferramenta e dia.

### Como funciona

```
Usuário: "revisar o módulo auth"
  └─ Read auth.module           → 1.200 tok   ┐
  └─ Grep hook                  →    80 tok   │ mesma "solicitação"
  └─ Read AuthService.php       → 2.400 tok   │ → total: 4.980 tok
  └─ Bash lint auth/            → 1.300 tok   ┘
```

Cada entrada armazena: timestamp, sessão, projeto, ferramenta, modelo, rótulo, texto da solicitação, tokens. O script de relatório agrega em breakdowns sobre os quais você pode agir.

### A parte não óbvia

O hook captura chamadas de ferramentas isoladamente — mas Claude envia todo o histórico da conversa com cada solicitação. Isso cria uma **subestimação não linear**:

| Mensagem | Subestimação real |
|----------|------------------|
| 5        | ~20%             |
| 20       | ~60%             |
| 40+      | ~80–90%          |

Use como **índice relativo** para comparar projetos, sessões e tipos de solicitação — não como custo absoluto.

Principais pontos cegos:
- **Chamadas de agentes** — conversas de subagentes são completamente invisíveis (500 tokens no log = potencialmente 20.000+ reais)
- **Conversas longas** — o contexto acumula quadraticamente; inicie novas conversas para tarefas independentes
- **Skills ativas** — cada SKILL.md carregada adiciona overhead fixo por solicitação

### Comandos

```bash
/usage-tracker install        # Configurar hook + scripts
/usage-tracker report hoy     # Relatório de hoje
/usage-tracker report semana  # Últimos 7 dias
/usage-tracker top-requests   # As 15 solicitações mais caras
/usage-tracker status         # Verificar que o hook está ativo
```

### Instalar

```bash
npx skills add j4rk0r/claude-skills@usage-tracker --yes --global
```

---

## Padroes de Qualidade

Cada skill e avaliada com [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensoes, 120 pontos max. **Minimo: B (96/120).**

## Contribuir

1. Fork este repo
2. Adicione sua skill em `skills/<nome>/SKILL.md`
3. Execute `/skill-judge` — deve pontuar B ou superior
4. Abra um PR com sua pontuacao

## Licenca

[MIT](../LICENSE)
