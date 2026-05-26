# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**
> ⚠️ **v1.1.0 — atomic claim (R14) added.** This translated page may not yet reflect the latest team-mode improvements. See the [English README](README.md), [CHANGELOG.md](CHANGELOG.md) and [SKILL.md](SKILL.md) for full details on the R14 atomic claim.

> **Você terminou uma feature ao longo de 3 conversas. A 4ª começa do zero porque o contexto não sobrevive. E o seu colega trabalha com uma lista de tarefas desatualizada.**

milestone v2 é um rastreador de desenvolvimento persistente com **cache de dois níveis**: snapshots de memória compactos (~100 tokens, auto-carregados) para estado instantâneo, e ficheiros autoritativos completos para o histórico profundo. Classifica as subtarefas como `[simple]` ou `[complex]`, exigindo um plano antes de executar trabalho complexo — evitando o caro ciclo de tentativa e erro de 6+ edições iterativas no mesmo ficheiro. O **modo equipa opcional (R13)** torna o milestone uma única fonte de verdade partilhada, git-sincronizada a um ramo canónico para que toda a equipa veja sempre a mesma lista atualizada.

## Instalação

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Como funciona

```
Você: "/milestone dashboard"
        |
        v
(modo equipa) verifica primeiro se há um milestone mais recente no ramo canónico
        |
        v
Lê o snapshot de memória (zero leituras de ficheiro — já em contexto)
        |
        v
Mostra: objetivo, subtarefas pendentes, decisões, última entrada de contexto
        |
        v
Classifica subtarefas: [simple] -> executar | [complex] -> plano primeiro
        |
        v
Após o trabalho: atualiza o ficheiro milestone + regenera o snapshot
        |
        v
(modo equipa) git-sincroniza .milestones/ ao ramo canónico
        |
        v
Próxima conversa / próximo colega: contexto instantâneo e atualizado
```

## Comandos

| Fase | Comando | Descrição |
|-------|---------|-------------|
| Discovery | `/milestone` | Lista todos os milestones com estado e progresso |
| Discovery | `/milestone <name>` | Carrega contexto (fuzzy match — "dash" encontra "dashboard-propietario") |
| Planning | `/milestone init <name>` | Cria um novo milestone com propostas de subtarefas |
| Execution | `/milestone start <name>` | Abre uma nova sessão de terminal com contexto compacto pré-carregado |
| Execution | `/milestone done <name> <subtask>` | Marca subtarefa concluída com edição mínima |
| Review | `/milestone update <name>` | Atualização em bloco após uma sessão de trabalho |

## Funcionalidades-chave

- **Cache de dois níveis** — snapshot de memória (~100 tok) para leituras, ficheiro autoritativo para o histórico completo. 99% mais barato do que ler o ficheiro inteiro de cada vez.
- **Classificação por complexidade** — `[simple]` (1 ficheiro, mudança clara) vs `[complex]` (multi-ficheiro, lógica nova). As subtarefas complexas ficam **bloqueadas** até existir um plano.
- **Regras de eficiência de tokens** — 3+ mudanças ao mesmo ficheiro → um único Write (10x mais barato que Edits iterativos). Não reler ficheiros já em contexto.
- **Comando de nova sessão** — `/milestone start` abre um `claude` fresco numa nova janela de terminal com contexto compacto, eliminando o multiplicador de custo 5-10x do histórico de conversa acumulado.
- **Modo equipa (R13, opt-in)** — um único milestone partilhado, git-sincronizado a um ramo canónico (default `develop`) via um worktree isolado, para que toda a equipa leia/escreva a mesma lista viva. Desativado por padrão.
- **Fuzzy matching** — escreva nomes parciais para carregar milestones
- **Log de contexto append-only** — registo em ordem cronológica inversa do que aconteceu e porquê
- **17 regras NEVER** — cobrem prevenção de split-brain, snapshots desatualizados, anti-padrões de edição e riscos do git-sync em equipa

## Modo equipa (R13) — opt-in

Sem isto, o milestone é um ficheiro local por máquina. Numa equipa isso degenera em listas duplicadas (cada feature branch edita o mesmo ficheiro) e listas de tarefas desatualizadas. O modo equipa torna o milestone uma **única fonte de verdade partilhada num ramo canónico**, editado apenas contra esse ramo via um worktree dedicado — nunca dentro dos ramos de código.

Ative por projeto em `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # ausente ou false -> todo o R13 é um no-op silencioso
  branch: develop      # ramo canónico (default: develop)
  path: .milestones     # subdir sincronizado (default: .milestones)
```

- **Na leitura** (`/milestone <name>`, `/milestone sync`): traz o ramo canónico e, se um colega avançou o milestone, avisa e oferece adotá-lo antes de você trabalhar.
- **Na escrita** (init / update / done / fim de sessão): após refrescar o snapshot, faz commit **apenas** de `<path>/<slug>.md` e push ao ramo canónico via um worktree isolado sob `.git/` — o seu ramo de código e working tree nunca são tocados.
- **Selo de PR**: uma subtarefa cujo trabalho está num PR aberto mantém o estado `[~]` com uma anotação inline `` `⏳ PR #N` `` (não é um estado novo — `[~]` já significa "code-complete, pendente de aprovação"; o PR é o veículo dessa aprovação).
- **Degradação graciosa**: sem git / sem remoto / sem ramo canónico / bloco ausente → no-op silencioso. A promessa zero-dependency mantém-se.
- **Nunca contorna os guards**: se um push for bloqueado por um guard de segurança ou auth, o commit fica no worktree e recebe o comando exato a executar — nunca silencia a falha nem bloqueia o seu trabalho.

## Arquitetura

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT (auto-carregado, ~100 tok)
<project-root>/.milestones/<slug>.md                      ← AUTORITATIVO (histórico completo)
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← Planos para subtarefas [complex]
<project-root>/.git/milestone-sync-wt/                     ← Worktree isolado R13 (apenas modo equipa)
```

## O que o diferencia da v1

| Aspeto | v1 | v2 |
|--------|----|----|
| Custo de carga | ~8.300 tok (Read ficheiro completo + templates) | ~100 tok (snapshot de memória) |
| Custo de listagem | ~8.750 tok (Read todos os ficheiros) | ~400 tok (apenas frontmatter, limit:8) |
| Subtarefas complexas | Sem gate — tentativa e erro | Plano requerido antes de executar |
| Gestão de sessão | Mesma conversa (o contexto acumula) | `/milestone start` abre sessão fresca |
| Carga de referências | Sempre carrega templates.md | Apenas em `/milestone init` |
| Colaboração em equipa | Nenhuma — apenas ficheiro local | Milestone partilhado git-sincronizado opt-in (R13) |

## Avaliação

- **`/skill-judge`**: 120/120 (Grau A+)
- **`/skill-guard`**: 92/100 (GREEN) — sem scripts executados em operação normal, sem rede, sem MCP. R13 (opt-in, desativado por padrão) é o único caminho que realiza operações git.

## Segurança

- Por padrão, apenas lê/escreve ficheiros locais `.milestones/*.md` e snapshots de memória. Sem rede, sem scripts em operação normal.
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash é usado para `/milestone start` (auto-instala o script no primeiro uso) e, **apenas quando o modo equipa está explicitamente ativado**, para `milestone-sync.sh` — que realiza `git fetch`/`git push` limitados a `<path>/` contra o ramo canónico via um worktree isolado. Desativado por padrão; nunca faz push de código; nunca contorna os guards de segurança (push bloqueado → reportado, não silenciado).
