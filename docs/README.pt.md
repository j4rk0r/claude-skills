# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Skills de nivel especialista para Claude Code. Cada skill avaliada com **A+ (120/120)** antes da publicacao.

## Instalar

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## Skills

| Skill | O que faz | Nota |
|-------|-----------|------|
| **[skill-advisor](../skills/skill-advisor/)** | Voce instalou 50 skills — usa 5. Conecta cada tarefa a sua melhor ferramenta para que nenhuma fique esquecida. | 120/120 |
| **[skill-guard](../skills/skill-guard/)** | Detecta skills maliciosas antes que toquem seus arquivos, tokens ou chaves. Analise em 9 camadas + registro de auditorias verificado. | 120/120 |
| **[skill-learner](../skills/skill-learner/)** | Captura erros e persiste correcoes para que o mesmo erro nunca se repita. Funciona para skills E comportamento geral do Claude. Opcionalmente gera propostas de melhoria para autores. | 90/100 |

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
- **7 regras NEVER** — previne correcoes vagas, duplicatas e bypass de seguranca
- **Teste de leitura a frio** — verifica que cada correcao e clara para um agente diferente
- **Propostas de melhoria** — gera propostas com diffs para o autor da skill
- **Bilingue** — escreve correcoes no idioma do usuario

### Instalar

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
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
