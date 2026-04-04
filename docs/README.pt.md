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
| **[skill-advisor](../skills/skill-advisor/)** | Analisa cada instrucao e recomenda a skill certa antes da execucao. Nunca mais esqueca uma skill instalada. | 120/120 |

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

## Padroes de Qualidade

Cada skill e avaliada com [skill-judge](https://github.com/softaworks/agent-toolkit) — 8 dimensoes, 120 pontos max. **Minimo: B (96/120).**

## Contribuir

1. Fork este repo
2. Adicione sua skill em `skills/<nome>/SKILL.md`
3. Execute `/skill-judge` — deve pontuar B ou superior
4. Abra um PR com sua pontuacao

## Licenca

[MIT](../LICENSE)
