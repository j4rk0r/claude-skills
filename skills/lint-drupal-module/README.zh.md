# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **你的手动代码审查发现了 29 个问题。你手动运行 PHPStan 和 PHPCS。你请一位审查员查看标准和安全性。45 分钟后你终于有了一个整合的视图 — 但你漏掉了模块 JS 文件中的 140 个违规,因为没有人对 JavaScript 运行 PHPCS。**

`lint-drupal-module` 是一个 Drupal 11 的 lint review skill,它**并行运行四个来源** — PHPStan level 5(配合 `phpstan-drupal`)、PHPCS(Drupal/DrupalPractice)、一个 `drupal-qa` 代理用于标准检查,以及一个 `drupal-security` 代理用于 OWASP 向量检查 — 并将发现整合到一份可操作的报告中。以前需要 12 个手动步骤和 30 分钟的工作,现在只需一次调用,在最慢的来源所需的时间内完成(完整模式 2-5 分钟,diff 模式 30s-1 分钟)。

## 安装

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## 工作原理

```
你:"lint review del módulo chat_soporte_tecnico_ia"
        |
        v
识别模块(通过名称、路径或 Glob)
        |
        v
选择模式:完整(默认)| diff(vs develop)
        |
        v
检测环境(DDEV 使用 ddev exec,或本地 composer)
        |
        v
如缺失则安装 PHPStan + phpstan-drupal(先询问)
        |
        v
加载 references/prompts-agentes.md(调用代理前必须)
        |
        v
在同一条消息中并行启动 4 个来源:
  • Agent drupal-qa         (标准)
  • Agent drupal-security   (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
加载 references/plantilla-informe.md(编写前必须)
        |
        v
将所有 4 个输出整合到一份 markdown 报告中
        |
        v
自动检测 IDE(Antigravity / Cursor / VS Code)
        |
        v
写入 <ide>/Lint reviews/lint-review-<模块>-<模式>-<分支>.md
        |
        v
在聊天中总结最重要的阻塞项并询问:
  "arregla todo" / "solo crítico" / "auto-fix PHPCS" / "déjalo así"
```

## 两种模式

**完整(默认)** — 分析模块中的每个文件。更彻底,更慢(~2-5 分钟)。在发布前、新创建的模块上或定期审计时使用。

**Diff** — 仅分析当前分支相对于 `origin/develop` 已更改的文件。更快(~30s-1 分钟)。在开发过程中的中间审查、推送前验证,或只关心新增内容时使用。

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<name>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## 它发现手动审查遗漏的内容

该 skill 针对一个真实的 Drupal 11 模块(32 个文件)进行了验证。仅使用代理的手动审查标记了 29 个问题。运行 skill 的完整并行管道发现了 **65 个问题** — 包括模块 JavaScript 上的 166 个 PHPCS 违规(大多数可用 `phpcbf` 自动修复),这些是手动审查员从未检查过的,因为 JS 在其范围之外。

这就是重点:lint review 的质量取决于其最薄弱的一层。并行组合静态分析(PHPStan)、风格强制执行(PHPCS)和专家代理,可以捕获任何单一来源都看不到的内容。

## 报告结构

每份报告都遵循相同的固定模板(这样团队可以在不重新学习的情况下阅读不同模块的报告):

1. **执行摘要** — 按来源的发现表、前 5 个阻塞项、分类判定(`适用`、`适用(有小修正)`、`适用(有关键修正)`、`不适用`)
2. **PHPStan level 5** — 按文件分组的错误
3. **PHPCS Drupal/DrupalPractice** — 按文件分组的违规
4. **标准(drupal-qa)** — 按严重程度的发现,附修复建议
5. **安全(drupal-security)** — 漏洞分类 🔴 关键 / 🟠 高 / 🟡 中 / 🟢 低 / ℹ️ 信息
6. **优先级行动** — P0(阻塞项)、P1(建议)、P2(改进)
7. **最佳实践覆盖** — strict_types、OOP hooks、DI、routing 中的 CSRF、cache metadata、config schema、permissions、translation、behaviors、tests 的清单
8. **验证命令** — 本地重新运行的确切命令

## NEVER(吃过苦头学到的教训)

- **在 skill 期间绝不修改文件。** 仅报告。修复是一个单独的阶段,需要明确的用户确认。
- **绝不在分开的消息中运行 4 个来源。** 并行化是核心价值;串行执行需要 4 倍的时间。
- **绝不在有未解决的 HIGH/CRITICAL 发现时将判定标记为"适用"。**
- **绝不将 Controllers 中的 `Unsafe usage of new static()` 列为阻塞项** — 这是 phpstan-drupal 对 Drupal 标准模式的已知误报。
- **绝不在不检查 Hook OOP 是否通过 type-hint 使用它们的情况下删除 `services.yml` 中的 FQCN 别名。** 这是破坏 `drush cr` 的已知方式。
- **绝不假设功能测试通过只是因为 PHPUnit 没有失败。** 如果 PHPStan 在 `tests/` 目录中报告不存在的方法(`getClient()`、`post()`),测试可能在 CI 中静默失败。
- **绝不用英语编写报告。** 代码、命令和类名用英语;解释用西班牙语。

## 与姐妹 skills 的关系

- **`codex-diff-develop`** — 使用 Codex 18 规则方法论对 diff 上的业务逻辑进行审查。通过捕获逻辑 bug 来补充此 skill(后者进行静态分析和标准检查)。
- **`codex-pr-review`** — 完整 PR 的架构审查。比此 skill 高一个级别。
- **理想的合并前工作流:**
  1. `lint-drupal-module` → 机械修复(类型、标准、安全向量)
  2. `codex-diff-develop` → 业务逻辑修复
  3. `codex-pr-review` → 合并前的最终架构审查

## 要求

- Drupal 11 项目(通过 `Glob "**/web/modules/custom/*/*.info.yml"` 检测模块)
- 推荐 DDEV(skill 通过 `ddev exec` 在容器内运行工具)
- `drupal-qa` 和 `drupal-security` 子代理可用(如缺失,优雅降级为仅 PHPStan + PHPCS)
- 带并行 tool use 的 Anthropic Claude(串行执行有效但慢 4 倍)

## 许可证

MIT。参见仓库的 LICENSE。
