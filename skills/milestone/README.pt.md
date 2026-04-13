# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Voce terminou uma feature em 3 conversas. A 4a comeca do zero porque o contexto nao sobrevive.**

milestone v2 e um tracker de desenvolvimento persistente com **cache de dois niveis**: snapshots compactos em memoria (~100 tokens, carregados automaticamente) para estado instantaneo, e arquivos autoritativos para historico completo. Classifica subtarefas como `[simple]` ou `[complexo]`, exigindo um plano antes de executar trabalho complexo — prevenindo o ciclo caro de 6+ edits iterativos no mesmo arquivo.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Comandos

| Fase | Comando | Descricao |
|------|---------|-----------|
| Descoberta | `/milestone` | Listar todos com status e progresso |
| Descoberta | `/milestone <nome>` | Carregar contexto (correspondencia aproximada) |
| Planejamento | `/milestone init <nome>` | Criar novo com propostas de subtarefas |
| Execucao | `/milestone start <nome>` | Abrir terminal novo com contexto compacto |
| Execucao | `/milestone done <nome> <tarefa>` | Marcar subtarefa como concluida |
| Revisao | `/milestone update <nome>` | Atualizacao em massa apos sessao de trabalho |

## Caracteristicas principais

- **Cache de dois niveis** — snapshot em memoria (~100 tok) para leituras, arquivo autoritativo para historico. 99% mais barato.
- **Classificacao de complexidade** — `[simple]` vs `[complexo]`. Complexas sao **bloqueadas** ate existir um plano.
- **Regras de eficiencia de tokens** — 3+ alteracoes mesmo arquivo → um unico Write (10x mais barato).
- **Nova sessao** — `/milestone start` abre `claude` em terminal novo com contexto compacto.
- **12 regras NEVER** — prevencao de split-brain, snapshots desatualizados, anti-padroes de edicao.

## Avaliacao

- **`/skill-judge`**: 120/120 (Grau A+)
- **`/skill-guard`**: 92/100 (GREEN)
