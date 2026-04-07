# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Tua revisão manual de código encontra 29 issues. Rodas PHPStan e PHPCS à mão. Pedes a um reviewer para olhar padrões e segurança. 45 minutos depois finalmente tens uma visão consolidada — e perdeste 140 violações nos ficheiros JS do módulo porque ninguém correu PHPCS contra o JavaScript.**

`lint-drupal-module` é uma skill de lint review para Drupal 11 que executa **quatro fontes em paralelo** — PHPStan nível 5 (com `phpstan-drupal`), PHPCS (Drupal/DrupalPractice), um agente `drupal-qa` para padrões, e um agente `drupal-security` para vetores OWASP — e consolida os achados num único relatório acionável. O que antes eram 12 passos manuais e 30 minutos agora é uma única invocação que termina no tempo que demora a fonte mais lenta (2-5 min em modo completo, 30s-1min em modo diff).

## Instalação

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## Como funciona

```
Tu: "lint review do módulo chat_soporte_tecnico_ia"
        |
        v
Identifica o módulo (por nome, caminho ou Glob)
        |
        v
Escolhe o modo: completo (padrão) | diff (vs develop)
        |
        v
Deteta o ambiente (DDEV com ddev exec, ou composer local)
        |
        v
Instala PHPStan + phpstan-drupal se faltarem (perguntando primeiro)
        |
        v
Carrega references/prompts-agentes.md (obrigatório antes de invocar agentes)
        |
        v
Lança 4 fontes em paralelo, na mesma mensagem:
  • Agent drupal-qa         (padrões)
  • Agent drupal-security   (OWASP)
  • PHPStan nível 5
  • PHPCS Drupal/DrupalPractice
        |
        v
Carrega references/plantilla-informe.md (obrigatório antes de escrever)
        |
        v
Consolida as 4 saídas num relatório markdown
        |
        v
Auto-deteta o IDE (Antigravity / Cursor / VS Code)
        |
        v
Escreve em <ide>/Lint reviews/lint-review-<modulo>-<modo>-<branch>.md
        |
        v
Resume os top bloqueadores no chat e pergunta:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## Dois modos

**Completo (padrão)** — analisa todos os ficheiros do módulo. Mais exaustivo, mais lento (~2-5 min). Usa-o antes de um release, em módulos recém-criados ou para auditorias periódicas.

**Diff** — analisa apenas os ficheiros alterados na branch atual face a `origin/develop`. Mais rápido (~30s-1min). Usa-o em revisões intermédias durante desenvolvimento, validação pre-push, ou quando só te importa o que é novo.

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<nome>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## O que deteta que uma review manual não vê

A skill foi validada contra um módulo Drupal 11 real (32 ficheiros). Uma review manual apenas com agentes sinalizou 29 issues. A skill a correr o seu pipeline paralelizado completo trouxe à superfície **65 issues** — incluindo 166 violações PHPCS no JavaScript do módulo (a maioria auto-corrigíveis com `phpcbf`) que o reviewer manual nunca verificou porque JS estava fora do seu âmbito.

É esse o ponto: uma lint review só vale o que vale a sua camada mais fraca. Combinar análise estática (PHPStan), aplicação de estilo (PHPCS) e agentes experts em paralelo captura coisas que nenhuma fonte isolada vê.

## Estrutura do relatório

Cada relatório segue a mesma plantilla fixa (para que a equipa possa ler relatórios de módulos diferentes sem reaprender):

1. **Resumo executivo** — tabela de achados por fonte, top 5 bloqueadores, veredicto categórico (`APTO`, `APTO com correções menores`, `APTO com correções críticas`, `NÃO APTO`)
2. **PHPStan nível 5** — erros agrupados por ficheiro
3. **PHPCS Drupal/DrupalPractice** — violações agrupadas por ficheiro
4. **Padrões (drupal-qa)** — achados por severidade com sugestões de correção
5. **Segurança (drupal-security)** — vulnerabilidades classificadas 🔴 CRÍTICO / 🟠 ALTO / 🟡 MÉDIO / 🟢 BAIXO / ℹ️ INFO
6. **Ações priorizadas** — P0 (bloqueadores), P1 (recomendados), P2 (melhorias)
7. **Cobertura de boas práticas** — checklist de strict_types, hooks OOP, DI, CSRF em routing, cache metadata, config schema, permissions, translation, behaviors, tests
8. **Comandos de verificação** — comandos exatos para re-executar localmente

## NEVER (lições aprendidas à força)

- **Nunca modifica ficheiros durante a skill.** Apenas relata. As correções são uma fase separada com confirmação explícita do utilizador.
- **Nunca executa as 4 fontes em mensagens separadas.** A paralelização é o valor central; a execução em série demora 4× mais.
- **Nunca marca o veredicto como "APTO" com achados ALTO/CRÍTICO por resolver.**
- **Nunca lista `Unsafe usage of new static()` em Controllers como bloqueador** — falso positivo conhecido de phpstan-drupal com o pattern padrão do Drupal.
- **Nunca remove aliases FQCN em `services.yml` sem verificar se o Hook OOP os usa via type-hint.** Forma conhecida de partir `drush cr`.
- **Nunca assume que os testes funcionais passam só porque o PHPUnit não falha.** Se o PHPStan reporta métodos inexistentes (`getClient()`, `post()`) no diretório `tests/`, o teste provavelmente está a falhar silenciosamente no CI.
- **Nunca escreve o relatório em inglês.** Código, comandos e nomes de classe em inglês; explicações em espanhol.

## Relação com skills irmãs

- **`codex-diff-develop`** — revê lógica de negócio sobre o diff usando a metodologia Codex de 18 regras. Complementa esta skill (que faz análise estática e padrões) detetando bugs de lógica.
- **`codex-pr-review`** — review arquitetural de um PR completo. Um nível acima desta skill.
- **Workflow ideal pré-merge:**
  1. `lint-drupal-module` → correções mecânicas (tipos, padrões, vetores de segurança)
  2. `codex-diff-develop` → correções de lógica de negócio
  3. `codex-pr-review` → review arquitetural final antes do merge

## Requisitos

- Projeto Drupal 11 (deteta o módulo via `Glob "**/web/modules/custom/*/*.info.yml"`)
- DDEV recomendado (a skill executa ferramentas dentro do contentor via `ddev exec`)
- Subagentes `drupal-qa` e `drupal-security` disponíveis (degrada graciosamente para apenas PHPStan + PHPCS se faltarem)
- Claude da Anthropic com tool use paralelo (execução sequencial funciona mas é 4× mais lenta)

## Licença

MIT. Ver LICENSE do repo.
