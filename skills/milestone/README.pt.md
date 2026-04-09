# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **Voce terminou uma feature em 3 conversas. A 4a comeca do zero porque o contexto nao sobrevive.**

milestone e um tracker de desenvolvimento persistente que armazena o contexto completo como arquivos markdown no seu projeto. Cada marco e uma capsula autocontida: objetivo, subtarefas com status, decisoes arquiteturais, referencias de codigo e um log do que foi feito e por que. Carregue-o em qualquer conversa e retome exatamente de onde parou.

## Instalar

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## Comandos

| Comando | Descricao |
|---------|-----------|
| `/milestone` | Lista todos os marcos com status, progresso e links de carregamento rapido |
| `/milestone <nome>` | Carrega o contexto completo de um marco (correspondencia fuzzy) |
| `/milestone init <nome>` | Cria um novo marco com objetivo e subtarefas |
| `/milestone add <nome> <conteudo>` | Adiciona subtarefa, decisao, nota ou referencia |
| `/milestone done <nome> <subtarefa>` | Marca uma subtarefa como concluida |
| `/milestone update <nome>` | Atualiza contexto em lote apos uma sessao de trabalho |

## Caracteristicas principais

- **Persistente entre conversas** — os arquivos ficam em `.milestones/` e sobrevivem qualquer sessao
- **Contexto autocontido** — cada arquivo tem tudo necessario para retomar o trabalho
- **Descoberta de planejadores** — detecta automaticamente skills de planejamento instaladas e oferece unificar seus resultados
- **Auto-status** — o status se recalcula a partir dos checkboxes das subtarefas
- **Correspondencia fuzzy** — digite "dash" para carregar "dashboard-propietario"
- **Log de contexto append-only** — registro cronologico reverso do que aconteceu e por que
- **Skill global, dados locais** — instalada uma vez, cria dados especificos por projeto

## Seguranca

- Auditado com Skill-Guard: **92/100 GREEN**
- Sem scripts, sem chamadas de rede, sem acesso MCP
- `allowed-tools: Read Write Edit Glob Grep`
