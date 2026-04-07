# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Seu linter diz "esta tudo bem" — e tres semanas depois a producao quebra por causa de um hook que so roda em update, nao em insert.**

codex-diff-develop e uma skill de revisao de codigo Drupal 11 que audita o diff da sua branch atual contra `develop` usando a **metodologia Codex**: 18 regras testadas em producao com o *porque* atras de cada uma. Encontra os bugs que seu linter nao ve — os que so aparecem as 3 da manha depois de um deploy.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## Como funciona

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

## A metodologia Codex — 18 regras com cicatrizes

Cada regra inclui o **porque** (o incidente de producao que ensinou):

1. **Completude `hook_entity_insert` vs `_update`** — logica so em `_update` pula entidades novas
2. **Agregadas (MAX/MIN/COUNT) em tabelas vazias retornam NULL, nao 0**
3. **Interpolacao direta em SQL** — SQL injection mais apostrofos em nomes reais quebram a query
4. **Recursao em hooks sem guarda estatica** — loops infinitos so detectados pelo cron
5. **Multiplas escritas sem transacao** — falhas parciais = estado inconsistente
6. **APIs externas sem `connect_timeout`** — provedor lento bloqueia workers de fila
7. **`accessCheck(FALSE)` injustificado** — bypass silencioso de permissoes
8. **Invalidacao de cache insuficiente** — classico "funciona local" depois do deploy
9. **Idempotencia em retry/duplo-clique** — pedidos duplicados, emails duplicados
10. **Coerencia de tipos** entre codigo, schema e BD
11. **Sem kill-switch** — incidentes as 3 da manha sem tempo de redeploy
12. **Form alters AJAX sem `#process`** — alter perdido no rebuild AJAX
13. **`\Drupal::service()` em classes novas** — bloqueia unit tests e kernel tests
14. **Blocos/formatters custom sem `getCacheableMetadata()`** — quebra BigPipe silenciosamente
15. **Schema de config desatualizado** — `drush cim` falha em outros ambientes
16. **Migracoes sem `id_map` limpo** — rollbacks corrompidos meses depois
17. **Update hooks nao idempotentes** — re-execucao apos falha parcial piora a BD
18. **Overrides de `settings.php` colidindo com config split** — silenciosamente perdidos a cada deploy

## NEVER list — 15 anti-padroes especificos de Drupal

- **NUNCA** marcar um achado de estilo (typo, espaco) como "Alta" — dilui a severidade
- **NUNCA** sugerir refactors fora do diff exceto seguranca critica ou data loss
- **NUNCA** aprovar `\Drupal::service()` em classes novas com argumento "ja existia"
- **NUNCA** dar por bom `accessCheck(FALSE)` sem comentario inline justificativo
- **NUNCA** aprovar `|raw` em Twig sem verificar que a origem e 100% controlada pelo sistema
- **NUNCA** aprovar `loadMultiple([])` — retorna TODAS as entidades (vazamento de memoria classico)
- **NUNCA** aprovar Batch API sem callback `finished` que trate falha
- **NUNCA** aprovar `EntityFieldManagerInterface::getFieldStorageDefinitions()` sem verificar que o field existe
- **NUNCA** marcar o relatorio "OK" se houver algum achado High sem resolver

## Framework Codex de 5 perguntas

Antes de revisar qualquer bloco:

1. **Que tipo de mudanca e essa?** Hook, refactor, hotfix, migracao, config
2. **Qual o pior cenario em producao?** Define o piso de severidade
3. **O que a mudanca assume fora do diff?** Schema, indices, permissoes
4. **E idempotente?** Retry, duplo-clique, re-deploy
5. **Pode ser desativada?** Kill-switch via config/setting/feature flag

Um exemplo trabalhado guia passo a passo a aplicacao a um mini-diff hipotetico.

## Estrutura do relatorio

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branch>)

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
## Lo positivo
## Checklist final
```

Cada achado segue **Problema (Severidade)** → **Risco** → **Solucao** com codigo adaptado de 14 templates em `references/`.

## Auto-deteccao de IDE

Le `CLAUDE_CODE_ENTRYPOINT` primeiro (`claude-vscode`, `claude-cursor`, `claude-antigravity`). So cai para deteccao por pasta se a env var nao for conclusiva.

| Deteccao | Pasta de saida |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (nenhum / CLI) | `docs/revisiones-diff/` |

## Checklist de auto-verificacao

Antes de entregar, a skill percorre 12 verificacoes: primeira linha correta, arquivo na pasta certa, references carregadas nesta sessao, cada achado com Problema/Risco/Solucao, nenhuma Alta e so estilo, sem sugestoes fora de escopo, etc.

## Recovery — o que fazer quando algo falha

| Sintoma | Acao |
|---|---|
| `references/*.md` ausente | Avisar o usuario, nao inventar pontos Codex |
| `git fetch` falha (rede) | Continuar com `develop` local + nota no relatorio |
| `.cursor/` nao pode ser criada | Pedir ao usuario para criar a pasta |
| Diff > 200 arquivos | Pedir confirmacao antes de continuar |
| O usuario esta em `develop` | Abortar com mensagem clara |

## Avaliacao

- **`/skill-judge`**: 120/120 (Grau A+) — pontuacao perfeita nas 8 dimensoes
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

Se quiser revisar um PR remoto em vez da sua branch atual, use [`codex-pr-review`](../codex-pr-review/) — mesma metodologia Codex, mesmas references, baixa o PR via `git fetch origin pull/<N>/head`.

## Licenca

MIT
