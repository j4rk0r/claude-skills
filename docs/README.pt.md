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

## Skills

| Skill | O que faz |
|-------|-----------|
| **[skill-guard](../skills/skill-guard/)** | Detecta skills maliciosas antes que toquem seus arquivos, tokens ou chaves. Analise em 9 camadas + registro de auditorias verificado. |
| **[skill-advisor](../skills/skill-advisor/)** | Constroi planos de execucao combinando skills instaladas com gaps que faltam — e oferece instala-los. Nunca comece uma tarefa sem as ferramentas certas. |
| **[skill-learner](../skills/skill-learner/)** | Captura erros e persiste correcoes para que o mesmo erro nunca se repita. Funciona para skills E comportamento geral do Claude. Opcionalmente gera propostas de melhoria para autores. |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Revisao de codigo Drupal 11 da branch atual contra `develop` seguindo a metodologia Codex — 18 regras testadas em producao com o *porque* atras de cada uma. Gera um relatorio `.md` estruturado. |
| **[codex-pr-review](../skills/codex-pr-review/)** | Revisao de pull requests Drupal 11 com a metodologia Codex — mesmas 18 regras que `codex-diff-develop` mas baixa o PR via `git fetch origin pull/<N>/head` para auditar qualquer PR do GitHub. |

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

## Padroes de Qualidade

Cada skill e avaliada com [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensoes, 120 pontos max. **Minimo: B (96/120).**

## Contribuir

1. Fork este repo
2. Adicione sua skill em `skills/<nome>/SKILL.md`
3. Execute `/skill-judge` — deve pontuar B ou superior
4. Abra um PR com sua pontuacao

## Licenca

[MIT](../LICENSE)
