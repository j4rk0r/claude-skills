# codex-pr-review

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **你的审查者说"LGTM" — 三周后生产环境因为一个只在 update 时运行而非 insert 时运行的 hook 而崩溃。**

codex-pr-review 是一个 Drupal 11 pull request 审查技能，从 GitHub 拉取 PR 并使用 **Codex 方法论** 进行审计：18 条经过生产验证的规则，每条都附带 *为什么*。捕获 linter 漏掉的 bug — 那些只在凌晨3点部署后才出现的 bug。

## 安装

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

## 工作原理

```
你: "revision Codex PR #42 develop ← feature/alejandro"
        |
        v
确认 PR 编号和分支（缺失时询问）
        |
        v
git fetch origin pull/42/head:pr-42
git diff origin/develop...pr-42
        |
        v
强制加载 references（与 codex-diff-develop 相同）
        |
        v
应用 Codex 5 问题框架 + 决策树
        |
        v
只审查 PR 的 diff
        |
        v
自动检测 IDE → 将报告写入 <ide>/Revisiones PRs/lint-review-prNN.md
        |
        v
交付前根据 13 项检查清单进行自我验证
```

## 18 条 Codex 规则 — 每条都有伤疤

每条规则都包含 **为什么**：

1. **`hook_entity_insert` vs `_update` 完整性** — 仅在 `_update` 中的逻辑会跳过新创建的实体
2. **空表上的聚合（MAX/MIN/COUNT）返回 NULL，而不是 0**
3. **直接的 SQL 插值** — SQL 注入加上撇号会破坏查询
4. **没有静态守卫的 hook 递归** — 仅由 cron 检测到的无限循环
5. **没有事务的多次写入** — 部分失败 = 状态不一致
6. **没有 `connect_timeout` 的外部 API** — 慢速提供商阻塞队列工作进程
7. **未经证明的 `accessCheck(FALSE)`** — 静默的权限绕过
8. **缓存失效不足** — 部署后经典的"本地工作正常"
9. **重试/双击操作的幂等性** — 重复订单、重复邮件
10. **类型一致性** 在代码、schema 和 DB 之间
11. **没有终止开关** — 凌晨3点没时间重新部署
12. **没有 `#process` 的 AJAX 表单 alter** — alter 在 AJAX 重建中丢失
13. **新类中的 `\Drupal::service()`** — 阻塞单元和 kernel 测试
14. **没有 `getCacheableMetadata()` 的自定义块/格式化器** — 破坏 BigPipe
15. **过时的 config schema** — `drush cim` 在其他环境中失败
16. **没有干净 `id_map` 的迁移** — 损坏的回滚
17. **非幂等的 update hook** — 部分失败后重新执行使 DB 变得更糟
18. **与 config split 冲突的 `settings.php` 覆盖** — 每次部署都丢失

## NEVER 列表 — 15 条 Drupal 特定反模式

PR 审查特定：

- **NUNCA** 将样式发现（拼写错误、空格）标记为"Alta" — 稀释严重性
- **NUNCA** 建议 PR 范围外的重构，除非是关键安全或数据丢失问题
- **NUNCA** 在文档中引用或命名其他 PR — 审查者失去焦点并混淆讨论（PR 审查独有，diff-develop 中没有）
- **NUNCA** 批准新类中的 `\Drupal::service()`
- **NUNCA** 在没有内联注释的情况下接受 `accessCheck(FALSE)`
- **NUNCA** 在未验证源是系统控制的情况下批准 Twig 中的 `|raw`
- **NUNCA** 批准没有空数组守卫的 `loadMultiple([])`
- **NUNCA** 批准没有 `finished` 回调处理失败的 Batch API
- **NUNCA** 如果有任何高严重性发现未解决，将报告标记为"OK"

## Codex 5 问题框架

在审查任何块之前：

1. **这是什么类型的更改？** Hook、重构、热修复、迁移、配置
2. **生产环境的最坏情况是什么？** 设置严重性下限
3. **更改假设了 diff 之外的什么？** Schema、索引、权限
4. **是幂等的吗？** 重试、双击、重新部署
5. **能关闭吗？** 通过 config/setting/feature flag 的终止开关

一个工作示例逐步指导如何应用于假设的 mini-PR。

## 报告结构

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

每个发现遵循 **问题（严重性）** → **风险** → **解决方案**，使用 `references/` 中 14 个模板的代码。

## IDE 自动检测

首先读取 `CLAUDE_CODE_ENTRYPOINT`。仅当环境变量不明确时才回退到文件夹检测。

| 检测 | 输出文件夹 |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones PRs/` |
| `claude-cursor` | `.cursor/Revisiones PRs/` |
| `claude-vscode` | `.vscode/Revisiones PRs/` |
| (无 / CLI) | `docs/revisiones-prs/` |

## 自我验证检查清单

交付前通过 13 项检查：第一行正确、文件在正确的文件夹中、本会话中加载了 references、每个发现都有问题/风险/解决方案、没有 Alta 只是样式问题、**没有引用其他 PR** 等。

## Recovery — 当出现问题时该怎么办

| 症状 | 操作 |
|---|---|
| `references/*.md` 缺失 | 警告用户，不要发明 Codex 点 |
| `git fetch origin pull/<N>/head` 失败 | 验证 PR 编号、仓库，或回退到 GitLab `merge-requests/<N>/head` |
| 本地不存在基础分支 | `git fetch origin <base>:<base>` |
| `.cursor/` 无法创建 | 请用户创建文件夹 |
| PR > 200 个文件 | 继续之前请求确认 |
| PR 已合并 | 警告并确认审查历史 |
| 用户未提供 PR 编号 | 询问，不要假设 |

## 评估

- **`/skill-judge`**: 120/120（A+ 级）
- **`/skill-guard`**: 100/100（绿色）— 声明最少的 `allowed-tools`，零网络，零 MCP

| 维度 | 得分 |
|------|-----|
| Knowledge Delta | 20/20 |
| Mindset + Procedures | 15/15 |
| Anti-Pattern Quality | 15/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 15/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## 姊妹技能

如果你想审查 *当前分支* 与 `develop` 的差异（不是远程 PR），使用 [`codex-diff-develop`](../codex-diff-develop/) — 相同的 Codex 方法论，相同的 references，不同的 diff 来源。

## 许可证

MIT
