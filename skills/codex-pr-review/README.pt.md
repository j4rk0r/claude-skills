# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Seu reviewer diz "LGTM" — e tres semanas depois a producao quebra por causa de um hook que so roda em update, nao em insert.**

codex-pr-review e uma skill de revisao de pull requests Drupal 11 que baixa o PR do GitHub e o audita usando a **metodologia Codex**: 18 regras testadas em producao com o *porque* atras de cada uma. Encontra os bugs que seu linter nao ve — os que so aparecem as 3 da manha depois de um deploy.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## Como funciona

```
Voce: "revisao Codex PR #42 develop ← feature/alejandro"
        |
        v
Confirma numero do PR e branches (pergunta se faltarem)
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
Carrega MANDATORY as references (mesmas que codex-diff-develop)
        |
        v
Aplica framework Codex de 5 perguntas + decision tree
        |
        v
Revisa SO o diff do PR
        |
        v
Auto-detecta IDE → escreve relatorio em <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
Auto-verificacao contra checklist de 13 itens antes de entregar
```

## A metodologia Codex — 18 regras com cicatrizes

Cada regra inclui o **porque**:

1. **Completude `hook_entity_insert` vs `_update`** — logica so em `_update` pula entidades novas
2. **Agregadas (MAX/MIN/COUNT) em tabelas vazias retornam NULL, nao 0**
3. **Interpolacao direta em SQL** — SQL injection mais apostrofos quebram queries
4. **Recursao em hooks sem guarda estatica** — loops infinitos so detectados pelo cron
5. **Multiplas escritas sem transacao** — falhas parciais = estado inconsistente
6. **APIs externas sem `connect_timeout`** — provedor lento bloqueia workers de fila
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permissoes
8. **Invalidacao de cache insuficiente** — classico "funciona local"
9. **Idempotencia em retry/duplo-clique** — pedidos duplicados, emails duplicados
10. **Coerencia de tipos** entre codigo, schema e BD
11. **Sem kill-switch** — incidentes as 3 da manha sem tempo de redeploy
12. **Form alters AJAX sem `#process`** — alter perdido no rebuild AJAX
13. **`\Drupal::service()` em classes novas** — bloqueia unit e kernel tests
14. **Blocos/formatters custom sem `getCacheableMetadata()`** — quebra BigPipe
15. **Schema de config desatualizado** — `drush cim` falha em outros ambientes
16. **Migracoes sem `id_map` limpo** — rollbacks corrompidos
17. **Update hooks nao idempotentes** — re-execucao apos falha parcial piora a BD
18. **Overrides de `settings.php` colidindo com config split** — perdidos em cada deploy

## NEVER list — 15 anti-padroes especificos de Drupal

Especificos de revisao de PR:

- **NUNCA** marcar um achado de estilo (typo, espaco) como "Alta" — dilui a severidade
- **NUNCA** sugerir refactors fora do PR exceto seguranca critica ou data loss
- **NUNCA** referenciar ou nomear outros PRs no documento — o reviewer perde o foco e mistura discussoes (unico de revisao de PR, ausente de diff-develop)
- **NUNCA** aprovar `\Drupal::service()` em classes novas
- **NUNCA** dar por bom `accessCheck(FALSE)` sem comentario inline justificativo
- **NUNCA** aprovar `|raw` em Twig sem verificar que a origem e controlada pelo sistema
- **NUNCA** aprovar `loadMultiple([])` sem guarda de array vazio
- **NUNCA** aprovar Batch API sem callback `finished` que trate falha
- **NUNCA** marcar o relatorio "OK" se houver algum achado High sem resolver

## Framework Codex de 5 perguntas

Antes de revisar qualquer bloco:

1. **Que tipo de mudanca e essa?** Hook, refactor, hotfix, migracao, config
2. **Qual o pior cenario em producao?** Define o piso de severidade
3. **O que a mudanca assume fora do diff?** Schema, indices, permissoes
4. **E idempotente?** Retry, duplo-clique, re-deploy
5. **Pode ser desativada?** Kill-switch via config/setting/feature flag

Um exemplo trabalhado guia passo a passo a aplicacao a um mini-PR hipotetico.

## Estrutura do relatorio

```markdown
Español confirmado.

# Revisión de código — PR #<N> (<base> ← <head>)

## Resumen ejecutivo
## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI
## Riesgos (tabla)
## Sugerencias accionables
## Checklist final
```

Cada achado segue **Problema (Severidade)** → **Risco** → **Solucao** com codigo adaptado de 14 templates em `references/`.

## Auto-deteccao de IDE

Le `CLAUDE_CODE_ENTRYPOINT` primeiro. So cai para deteccao por pasta se a env var nao for conclusiva.

| Deteccao | Pasta de saida |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (nenhum / CLI) | `docs/revisiones-prs/` |

## Checklist de auto-verificacao

Antes de entregar, percorre 13 verificacoes: primeira linha correta, arquivo na pasta certa, references carregadas nesta sessao, cada achado com Problema/Risco/Solucao, nenhuma Alta e so estilo, **sem referencias a outros PRs**, etc.

## Recovery — o que fazer quando algo falha

| Sintoma | Acao |
|---|---|
| `references/*.md` ausente | Avisar o usuario, nao inventar pontos Codex |
| `git fetch origin pull/<N>/head` falha | Verificar numero do PR, repo, ou fallback GitLab `merge-requests/<N>/head` |
| Branch base nao existe localmente | `git fetch origin <base>:<base>` |
| `.cursor/` nao pode ser criada | Pedir ao usuario para criar a pasta |
| PR > 200 arquivos | Pedir confirmacao antes de continuar |
| PR ja merged | Avisar e confirmar revisao do historico |
| O usuario nao fornece numero do PR | Perguntar, nao assumir |

## Avaliacao

- **`/skill-judge`**: 120/120 (Grau A+)
- **`/skill-guard`**: 100/100 (VERDE) — declara `allowed-tools` minimos, zero rede, zero MCP

| Dimensao | Score |
|----------|-------|
| Knowledge Delta | 20/20 |
| Mindset + Procedures | 15/15 |
| Anti-Pattern Quality | 15/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 15/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## Skill irma

Se quiser revisar o diff da sua *branch atual* contra `develop` (nao um PR remoto), use [`codex-diff-develop`](../codex-diff-develop/) — mesma metodologia Codex, mesmas references, origem do diff diferente.

## Licenca

MIT
