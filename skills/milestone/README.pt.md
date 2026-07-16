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

## Modo equipa (R13 + R14) — opt-in

Sem isto, o milestone é um ficheiro local por máquina. Numa equipa isso degenera em listas duplicadas (cada feature branch edita o mesmo ficheiro) e listas de tarefas desatualizadas. O modo equipa torna o milestone uma **única fonte de verdade partilhada num ramo canónico**, editado apenas contra esse ramo via um worktree dedicado — nunca dentro dos ramos de código. **Descobre milestones que outros membros criaram** antes de você listar ou criar um (para nunca duplicar `foo` quando um colega o criou há um minuto), e **reserva cada subtarefa atomicamente** no momento em que alguém começa a trabalhar nela — para que duas pessoas nunca acabem a fazer o mesmo, e o sistema diz-lhe *quem* chegou primeiro.

Ative por projeto em `.milestones/config.yml`:

```yaml
milestone_sync:
  enabled: true        # ausente ou false -> todo o modo equipa é um no-op silencioso
  branch: develop      # ramo canónico (default: develop)
  path: .milestones     # subdir sincronizado (default: .milestones)
```

### R13 — fonte de verdade partilhada

- **Na leitura** (`/milestone <name>`, `/milestone sync`): traz o ramo canónico e, se um colega avançou o milestone, avisa e oferece adotá-lo antes de você trabalhar.
- **Na escrita** (init / update / done / fim de sessão): após refrescar o snapshot, faz commit **apenas** de `<path>/<slug>.md` e push ao ramo canónico via um worktree isolado sob `.git/` — o seu ramo de código e working tree nunca são tocados.
- **Selo de PR**: uma subtarefa cujo trabalho está num PR aberto mantém o estado `[~]` com uma anotação inline `` `⏳ PR #N` ``.

### R14 — reserva atómica antes de tocar no código

Quando você executa `/milestone start`, o sistema **reserva a subtarefa no ramo canónico ANTES de tocar em qualquer código**. A linha passa a `[>]` com uma anotação inline:

```
- [>] 1.4 [complex] Stripe integration — `🔒 Jane Doe (jdoe) · 2026-05-26 15:01` [Backend]
```

- **Atómica via `git push --fast-forward`**: se dois membros tentam reservar a mesma subtarefa ao mesmo tempo, apenas um push fast-forward vence. O perdedor faz fetch, revalida, vê a reserva do vencedor e aborta com `race-lost:<winner>` — diz-lhe exatamente quem a ficou. Se o outro membro já tinha publicado a reserva, recebe `already-claimed:<winner>` logo à partida. Impossível reservar em duplicado.
- **Loop de retry, não uma única tentativa**: num fast-forward perdido a reserva rebaseia e revalida até 5 vezes, por isso, com 3+ reservas simultâneas, um enganador `commit-pending-push` nunca aparece — esse estado passa a significar apenas um problema real de push (auth / ramo protegido / rede).
- **Verificação em vivo obrigatória**: `claim` faz `git fetch` e aborta com `noop:fetch-failed` se a verificação de rede falhar. Sem reservar contra dados locais desatualizados.
- **O `/milestone` (listagem) em modo equipa tem de consultar as reservas**: a lista de milestones mostra quem tem o quê reservado. Uma subtarefa reservada por outra pessoa nunca pode aparecer como "livre" para si.
- **Rasto de auditoria**: cada reserva/libertação é um commit dedicado em `<branch>` (`chore(milestone): claim <slug> <X.Y> by <Jane Doe (jdoe)>`). O histórico do ramo *é* o registo de coordenação da equipa.
- **Reservas obsoletas destacadas no start**: se tudo o que está livre está tomado mas uma reserva tem mais de 24h, `/milestone start` sugere o override consciente (`release --force` + re-reservar) em vez de apenas a listar.
- **Handover via `/milestone release <slug> <X.Y> --force`** quando necessário (férias, máquina em baixo, recusa). Adicione uma nota em `## Contexto` a justificar a libertação forçada; quem reservou originalmente vê `not-claimed` da próxima vez.

### Sincronização do índice — nunca criar um duplicado (H4)

R13/R14 sincronizam um `<slug>.md` de cada vez, mas isso por si só não consegue revelar **novos milestones que um colega criou e que você não tem localmente**. A sincronização do índice fecha essa lacuna lendo todo o catálogo de milestones publicados antes de você listar ou criar:

- **`milestone-sync.sh index <root>`** lista todos os milestones no ramo canónico como `<slug>` · `<created_by>` · `<created_at>` · `<updated_at>` (autor/data a partir do commit que *adicionou* o ficheiro).
- **No `/milestone init`**: o nome proposto é comparado com o índice (exato e "quase-colisão" ignorando `-`/`_`/maiúsculas). Se colidir → **não** cria; diz-lhe **quem o criou e quando**, e oferece carregá-lo em vez de duplicar.
- **No `/milestone` (listagem)**: milestones presentes no ramo mas não locais são mostrados como `🆕 remote · created by <handle>`, para você ver de relance o que outros começaram mesmo antes de fazer pull.

### Auto-atualização do helper (H1)

O helper instala-se em `~/.claude/milestone-sync.sh`. Para impedir que duas máquinas corram lógica de reserva diferente, é **versionado**: a skill compara a `version` instalada com a cópia de referência e volta a copiar quando diferem (ou quando falta), na primeira sincronização de cada sessão.

### Modo central & onboarding

Em modo central (v1.2.0) a config e os ficheiros autoritativos vivem no repositório partilhado de memórias, mantendo o repo do cliente limpo. `references/team-bootstrap.sh` faz o onboarding de um novo membro: clona/atualiza esse repositório, instala a skill + helper, e verifica a identidade git que assina as reservas.

### Limite — fronteira honesta

O Git é distribuído: o índice e as reservas só veem o que está **no ramo canónico**. Uma reserva que alguém mantém sem fazer push é invisível, tal como qualquer commit local. É exatamente por isso que a R14 força a reserva a ser **publicada no instante em que você começa** (antes da primeira linha de código) — "começar uma tarefa" e "todos a verem" tornam-se o mesmo ato atómico.

### Comportamento comum

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
