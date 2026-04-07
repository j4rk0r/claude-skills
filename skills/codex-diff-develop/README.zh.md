# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **你的 linter 说"看起来不错" — 三周后生产环境因为一个只在 update 时运行而非 insert 时运行的 hook 而崩溃。**

codex-diff-develop 是一个 Drupal 11 代码审查技能，使用 **Codex 方法论** 审查当前分支与 `develop` 的差异：18 条经过生产验证的规则，每条都附带 *为什么*。捕获 linter 漏掉的 bug — 那些只在凌晨3点部署后才出现的 bug。

## 安装

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## 工作原理

```
你: "revision diff develop"
        |
        v
检测上下文：分支、drupal/ 子目录、diff 中的文件类型
        |
        v
强制加载 references（18 条 Codex 规则 + 14 个发现模板）
        |
        v
应用 Codex 5 问题框架
        |
        v
决策树根据文件类型选择相关的 Codex 规则
        |
        v
只审查 diff，不提供超出范围的建议
        |
        v
自动检测 IDE → 将报告写入 .vscode/.cursor/.antigravity
        |
        v
交付前根据 12 项检查清单进行自我验证
```

## 18 条 Codex 规则 — 每条都有伤疤

每条规则都包含 **为什么**（教会它的生产事故）：

1. **`hook_entity_insert` vs `_update` 完整性** — 仅在 `_update` 中的逻辑会跳过新创建的实体
2. **空表上的聚合（MAX/MIN/COUNT）返回 NULL，而不是 0**
3. **直接的 SQL 插值** — SQL 注入加上真实姓名中的撇号会破坏查询
4. **没有静态守卫的 hook 递归** — 仅由 cron 检测到的无限循环
5. **没有事务的多次写入** — 部分失败 = 状态不一致
6. **没有 `connect_timeout` 的外部 API** — 慢速提供商阻塞队列工作进程
7. **未经证明的 `accessCheck(FALSE)`** — 静默的权限绕过
8. **缓存失效不足** — 部署后经典的"本地工作正常"
9. **重试/双击操作的幂等性** — 重复订单、重复邮件、重复扣款
10. **类型一致性** 在代码、schema 和 DB 之间
11. **没有终止开关** — 凌晨3点没时间重新部署的事件
12. **没有 `#process` 的 AJAX 表单 alter** — alter 在 AJAX 重建中丢失
13. **新类中的 `\Drupal::service()`** — 阻塞单元测试和 kernel 测试
14. **没有 `getCacheableMetadata()` 的自定义块/格式化器** — 静默破坏 BigPipe
15. **过时的 config schema** — `drush cim` 在其他环境中失败
16. **没有干净 `id_map` 的迁移** — 几个月后才发现的损坏回滚
17. **非幂等的 update hook** — 部分失败后重新执行使 DB 变得更糟
18. **与 config split 冲突的 `settings.php` 覆盖** — 每次部署都静默丢失

## NEVER 列表 — 15 条 Drupal 特定反模式

- **NUNCA** 将样式发现（拼写错误、空格）标记为"Alta" — 稀释严重性
- **NUNCA** 建议 diff 范围外的重构，除非是关键安全或数据丢失问题
- **NUNCA** 用"以前就有"的理由批准新类中的 `\Drupal::service()`
- **NUNCA** 在没有内联注释的情况下接受 `accessCheck(FALSE)`
- **NUNCA** 在未验证源是 100% 系统控制的情况下批准 Twig 中的 `|raw`
- **NUNCA** 批准 `loadMultiple([])` — 返回所有实体（经典内存泄漏）
- **NUNCA** 批准没有 `finished` 回调处理失败的 Batch API
- **NUNCA** 批准 `EntityFieldManagerInterface::getFieldStorageDefinitions()` 而不验证字段是否存在
- **NUNCA** 如果有任何高严重性发现未解决，将报告标记为"OK"

## Codex 5 问题框架

在审查任何块之前：

1. **这是什么类型的更改？** Hook、重构、热修复、迁移、配置
2. **生产环境的最坏情况是什么？** 设置严重性下限
3. **更改假设了 diff 之外的什么？** Schema、索引、权限
4. **是幂等的吗？** 重试、双击、重新部署
5. **能关闭吗？** 通过 config/setting/feature flag 的终止开关

一个工作示例逐步指导如何应用于假设的 mini-diff。

## 报告结构

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

每个发现遵循 **问题（严重性）** → **风险** → **解决方案**，使用 `references/` 中 14 个模板的代码。

## IDE 自动检测

首先读取 `CLAUDE_CODE_ENTRYPOINT`（`claude-vscode`、`claude-cursor`、`claude-antigravity`）。仅当环境变量不明确时才回退到文件夹检测。

| 检测 | 输出文件夹 |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (无 / CLI) | `docs/revisiones-diff/` |

## 自我验证检查清单

交付前，技能会通过 12 项检查：第一行正确、文件在正确的文件夹中、本会话中加载了 references、每个发现都有问题/风险/解决方案、没有 Alta 只是样式问题、没有超出范围的建议等。

## Recovery — 当出现问题时该怎么办

| 症状 | 操作 |
|---|---|
| `references/*.md` 缺失 | 警告用户，不要发明 Codex 点 |
| `git fetch` 失败（网络） | 继续使用本地 `develop` + 在报告中注明 |
| `.cursor/` 无法创建 | 请用户创建文件夹 |
| Diff > 200 个文件 | 继续之前请求确认 |
| 用户在 `develop` 上 | 中止并显示明确消息 |

## 评估

- **`/skill-judge`**: 120/120（A+ 级）— 8 个维度的完美分数
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

如果你想审查远程 PR 而不是当前分支，使用 [`codex-pr-review`](../codex-pr-review/) — 相同的 Codex 方法论，相同的 references，通过 `git fetch origin pull/<N>/head` 拉取 PR。

## 许可证

MIT
