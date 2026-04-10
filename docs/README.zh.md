# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

专家级 Claude Code 技能。每个技能发布前均获得 **A+ (120/120)** 评分。

## 全部安装

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

或单独安装：

```bash
npx skills add j4rk0r/claude-skills@skill-guard -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-advisor -y -g
```

```bash
npx skills add j4rk0r/claude-skills@skill-learner -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop -y -g
```

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review -y -g
```

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module -y -g
```

```bash
npx skills add j4rk0r/claude-skills@milestone -y -g
```

```bash
npx skills add j4rk0r/claude-skills@usage-tracker -y -g
```

## 技能列表

| 技能 | 功能 |
|------|------|
| **[skill-guard](../skills/skill-guard/)** | 在恶意技能接触你的文件、令牌或密钥之前拦截它。9层分析 + 社区验证的审计注册表。 |
| **[skill-advisor](../skills/skill-advisor/)** | 构建执行计划，将已安装技能与缺失的技能差距结合——然后提供安装。永远不要在装备不足时开始任务。 |
| **[skill-learner](../skills/skill-learner/)** | 捕获错误并持久化修正，让同样的错误不再重复。适用于技能和Claude的一般行为。可选择为技能作者生成改进建议。 |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Drupal 11 代码审查 — 使用 Codex 方法论审查当前分支与 `develop` 的差异。18条经过生产验证的规则，每条都附带 *为什么*。生成结构化 `.md` 报告。 |
| **[codex-pr-review](../skills/codex-pr-review/)** | Drupal 11 Pull Request 审查 — 使用与 `codex-diff-develop` 相同的 18 条 Codex 规则，但通过 `git fetch origin pull/<N>/head` 拉取 PR，可审查任何 GitHub PR。 |
| **[lint-drupal-module](../skills/lint-drupal-module/)** | Drupal 11 模块的并行化 lint review,结合 4 个来源 — PHPStan level 5、PHPCS Drupal/DrupalPractice、`drupal-qa` 代理(标准)和 `drupal-security` 代理(OWASP)。完整或 diff 模式。将所有内容整合到一份带 P0/P1/P2 行动的可操作报告中。 |
| **[milestone](skills/milestone/)** | 跨对话持久化的开发追踪器。每个里程碑都是一个自包含的胶囊：目标、带状态的子任务、决策、代码引用和上下文日志。与 Plan mode 和所有规划技能集成。 |
| **[usage-tracker](../skills/usage-tracker/)** | PostToolUse 钩子，将每次工具调用记录到 `~/.claude/usage.jsonl`。精确查看每个用户请求的消耗——按项目、会话、日期和工具分类。 |

## skill-guard

> **你安装了一个技能。它读取你的 `~/.ssh`，获取你的 `$GITHUB_TOKEN`，发送到远程服务器。你毫不知情。**

skill-guard 阻止这种情况。它在安装前审计技能，使用9层分析引擎——从静态模式匹配到LLM语义分析，能检测伪装成正常指令的提示注入攻击。

### 工作原理

```
你想安装一个技能
        |
        v
skill-guard 查询社区审计注册表
        |
        v
已审计（SHA匹配）？ --> 显示之前的报告
未审计？            --> "安装前进行安全分析？"
        |
        v
9层分析：权限、模式、脚本、
数据流、MCP滥用、供应链、声誉...
        |
        v
评分 0-100 → 绿色 / 黄色 / 红色
        |
        v
绿色：自动安装 | 黄色：你决定 | 红色：强烈警告
```

### 9个分析层

1. **前置元数据和权限** (20%) — 缺少 `allowed-tools`？Bash无限制？
2. **静态模式** (15%) — URL、IP、敏感路径、危险命令
3. **LLM语义分析** (30%) — 提示注入、木马、社会工程
4. **捆绑脚本** (15%) — 读取每个脚本。危险导入、混淆
5. **数据流** (10%) — 映射来源→目标。敏感数据到达外部URL = 威胁
6. **MCP和工具** — 未声明的MCP使用，通过Slack/GitHub/Monday泄露
7. **供应链** (2%) — 拼写抢注、未固定版本、虚假仓库
8. **声誉** (3%) — 作者资料、仓库年龄、木马分叉
9. **反规避** (5%) — Unicode技巧、同形字、自修改

### 两种分析模式

- **完整审计** — 9层，完整报告，注册表持久化
- **快速扫描** — 仅第1+2+3层。发现HIGH/CRITICAL时自动升级为完整审计

**信任模型：** 只有系统本身生成和发布审计结果。社区成员通过向 `audits/requests/` 提交 PR 来请求审计——维护者运行 skill-guard 并发布结果。这可以防止被篡改的审计进入注册表。

### 安装

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **你安装了 50 个技能，只用了 5 个。其余 45 个在吃灰。**

skill-advisor 解决这个问题。它位于你和 Claude 之间，分析每条指令，从你已安装的技能集合中找到最佳匹配——在工作开始之前。

### 工作原理

```
你输入一条指令
        |
        v
skill-advisor 扫描你已安装的技能
        |
        v
有匹配？ --> 推荐 1-5 个，按影响力排序
无匹配？ --> 静默继续（或建议安装一个）
```

### 两种模式

**预执行** — Claude 开始工作前，推荐能改善结果的技能。

**后执行** — 完成工作后，建议下一步逻辑操作。

### 独特之处

- **读取你的技能** — 没有硬编码列表。动态扫描 system-reminder。
- **横向思维** — "让它更好看" 能匹配设计、动画和无障碍审计技能。
- **知道何时沉默** — 简单任务不推荐。
- **推荐流水线** — 检测多步骤场景，建议完整组合。
- **社区回退** — 本地无匹配时，建议可安装的技能。

### 安装

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claude道歉，承诺改进——然后在下一个会话中犯完全相同的错误。**

skill-learner打破这个循环。当技能或Claude本身出错时，它会捕获出了什么问题、为什么以及应该怎么做——作为跨会话持久化的修正文件。

### 主要特性

- **自动检测失败的技能** — 从对话上下文中识别
- **去重** — 创建前检查INDEX.md，如果同一问题已存在则合并
- **9条NEVER规则** — 防止模糊修正、重复和安全绕过
- **冷读测试** — 验证每条修正对不同会话中的不同代理是否清晰
- **改进建议** — 生成带有diff的建议，保存在本地供用户提交
- **双语** — 用用户的语言编写修正以保留细微差别

### 安装

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

### 工作原理

```
出了问题
        |
        v
skill-learner 检测哪个技能（或一般行为）失败了
        |
        v
提出有针对性的问题直到理解错误
        |
        v
将结构化修正保存到 ~/.claude/skill-corrections/
        |
        v
下次该技能运行时 → 修正可用
        |
        v
可选：为技能作者生成改进建议
```

### 主要特性

- **自动检测失败的技能** — 从对话上下文中识别
- **去重** — 创建前检查INDEX.md，如果同一问题已存在则合并
- **9条NEVER规则** — 防止模糊修正、重复和安全绕过
- **冷读测试** — 验证每条修正对不同会话中的不同代理是否清晰
- **改进建议** — 生成带有diff的建议，保存在本地供用户提交
- **双语** — 用用户的语言编写修正以保留细微差别

### 安装

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **你的 linter 说"看起来不错" — 三周后生产环境因为一个只在 update 时运行而非 insert 时运行的 hook 而崩溃。**

codex-diff-develop 是一个 Drupal 11 代码审查技能，使用 **Codex 方法论** 审查当前分支与 `develop` 的差异：18 条经过生产验证的规则，每条都附带 *为什么*。捕获 linter 漏掉的 bug — 那些只在凌晨3点部署后才出现的 bug。

### 工作原理

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

### 18 条 Codex 规则 — 每条都有伤疤

每条规则都包含 **为什么**（教会它的生产事故）：

1. **`hook_entity_insert` vs `_update` 完整性** — 仅在 `_update` 中的逻辑会跳过新创建的实体
2. **空表上的聚合（MAX/MIN/COUNT）返回 NULL，而不是 0**
6. **没有 `connect_timeout` 的外部 API** — 慢速提供商阻塞队列工作进程
7. **未经证明的 `accessCheck(FALSE)`** — 静默的权限绕过
9. **重试/双击操作的幂等性** — 重复订单、重复邮件、重复扣款
11. **没有终止开关** — 凌晨3点没时间重新部署的事件
14. **没有 `getCacheableMetadata()` 的自定义块/格式化器** — 静默破坏 BigPipe

完整列表带 *为什么* 见 [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md)。

### NEVER 列表 — 15 条 Drupal 特定反模式

- **NUNCA** 将样式发现标记为"Alta" — 稀释严重性
- **NUNCA** 建议 diff 范围外的重构，除非是关键安全问题
- **NUNCA** 批准 `loadMultiple([])` — 返回所有实体（经典内存泄漏）
- **NUNCA** 批准没有 `finished` 回调处理失败的 Batch API

### Codex 5 问题框架

1. **这是什么类型的更改？**
2. **生产环境的最坏情况是什么？**
3. **更改假设了 diff 之外的什么？**
4. **是幂等的吗？**
5. **能关闭吗？**

### 输出

结构化 `.md` 报告：执行摘要、按类别的发现（安全、Codex 逻辑、标准/DI、性能、A11y/i18n、测试/CI）、风险表、可执行列表、"积极的方面"部分、最终检查清单。每个发现遵循 **问题（严重性）** → **风险** → **解决方案**。

### IDE 自动检测

首先读取 `CLAUDE_CODE_ENTRYPOINT`。仅当环境变量不明确时才回退到文件夹检测。

### 评估

- **`/skill-judge`**: 120/120（A+ 级）
- **`/skill-guard`**: 100/100（绿色）— 声明最少的 `allowed-tools`，零网络，零 MCP

### 安装

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **你的审查者说"LGTM" — 三周后生产环境因为一个只在 update 时运行的 hook 而崩溃。**

codex-pr-review 是 `codex-diff-develop` 用于 **远程 pull request** 的姊妹技能。相同的 Codex 方法论、相同的 18 条规则、相同的模板 — 但通过 `git fetch origin pull/<N>/head` 拉取 PR，让你可以按编号审查任何 GitHub PR。

### 与 codex-diff-develop 的差异

| 方面 | codex-diff-develop | codex-pr-review |
|---|---|---|
| diff 来源 | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| 输出文件夹 | `Revisiones diff/` | `Revisiones PRs/` |
| 文件名 | `lint-review-diff-develop-<branch>.md` | `lint-review-pr<N>.md` |
| 触发器 | "diff develop", "codex diff" | "revision PR", "revisar PR #N", "codex PR" |
| 额外 NEVER | — | "**NUNCA** 在文档中引用其他 PR" |
| 额外边缘情况 | — | GitLab 回退、PR 已合并、缺少 PR 编号 |

### 何时使用哪个

- **`codex-diff-develop`**：你在分支上本地工作，想在推送前审查自己的更改
- **`codex-pr-review`**：你想在不本地检出的情况下审查别人的 PR（或推送后的你自己的 PR）

### 评估

- **`/skill-judge`**: 120/120（A+ 级）
- **`/skill-guard`**: 100/100（绿色）

### 安装

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## lint-drupal-module

> **你的手动代码审查发现了 29 个问题。你手动运行 PHPStan 和 PHPCS。你请一位审查员查看标准和安全性。45 分钟后你终于有了一个整合的视图 — 但你漏掉了模块 JS 文件中的 140 个违规,因为没有人对 JavaScript 运行 PHPCS。**

lint-drupal-module **并行运行四个来源** — PHPStan level 5(配合 `phpstan-drupal`)、PHPCS Drupal/DrupalPractice、用于标准检查的 `drupal-qa` 代理,以及用于 OWASP 向量检查的 `drupal-security` 代理 — 并将发现整合到一份可操作的报告中。以前需要 12 个手动步骤和 30 分钟的工作,现在只需一次调用,在最慢的来源所需的时间内完成(完整模式 2-5 分钟,diff 模式 30s-1 分钟)。

### 工作原理

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
检测 DDEV / 本地 composer,如缺失则安装 PHPStan(先询问)
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
将所有 4 个输出整合到一份 markdown 报告中
        |
        v
自动检测 IDE → <ide>/Lint reviews/lint-review-<模块>-<模式>-<分支>.md
        |
        v
总结最重要的阻塞项并询问:
  "arregla todo" / "solo critico" / "auto-fix PHPCS" / "dejalo asi"
```

### 两种模式

| 模式 | 何时使用 | 速度 |
|---|---|---|
| **完整**(默认) | 发布前、新模块、定期审计 | ~2-5 分钟 |
| **Diff** | 开发中的中间审查、推送前验证、仅 vs `develop` 的新更改 | ~30s-1 分钟 |

### 它发现手动审查遗漏的内容

针对一个真实的 Drupal 11 模块(32 个文件)进行了验证。仅使用代理的手动审查标记了 29 个问题。运行完整并行管道发现了 **65 个问题** — 包括模块 JavaScript 上的 166 个 PHPCS 违规(大多数可用 `phpcbf` 自动修复),这些是手动审查员从未检查过的,因为 JS 在其范围之外。

这就是重点:lint review 的质量取决于其最薄弱的一层。并行组合静态分析、风格强制执行和专家代理,可以捕获任何单一来源都看不到的内容。

### 报告结构(固定)

1. **执行摘要** — 按来源的发现、前 5 个阻塞项、分类判定
2. **PHPStan level 5** — 按文件分组的错误
3. **PHPCS Drupal/DrupalPractice** — 按文件分组的违规
4. **标准(drupal-qa)** — 按严重程度的发现,附修复建议
5. **安全(drupal-security)** — 漏洞分类 🔴 关键 / 🟠 高 / 🟡 中 / 🟢 低 / ℹ️ 信息
6. **优先级行动** — P0 阻塞项、P1 建议、P2 改进
7. **最佳实践覆盖** — strict_types、OOP hooks、DI、CSRF、cache metadata 等的清单
8. **验证命令** — 本地重新运行的确切命令

### 主要 NEVER 规则

1. **在 skill 期间绝不修改文件。** 仅报告。修复是单独的阶段,需要明确的用户确认。
2. **绝不在分开的消息中运行 4 个来源。** 并行化是核心价值;串行执行需要 4 倍的时间。
3. **绝不将 Controllers 中的 `Unsafe usage of new static()` 列为阻塞项** — phpstan-drupal 的已知误报。
4. **绝不在不检查 Hook OOP 的 type-hint 使用情况下删除 `services.yml` 中的 FQCN 别名** — 破坏 `drush cr` 的已知方式。
5. **绝不对 JavaScript 文件运行 `phpcbf`** — Drupal 标准会将 `null`/`true`/`false` 转换为 `NULL`/`TRUE`/`FALSE` 在 JS 中,导致代码在运行时崩溃。始终使用 `--extensions=php,module,inc,install,profile,theme` 和 `--ignore='*/js/*'`。

### 与姐妹 skills 的关系

- **`codex-diff-develop`** → 在 diff 上审查业务逻辑(补充此 skill)
- **`codex-pr-review`** → 完整 PR 的架构审查(高一个级别)
- **理想的合并前工作流:** `lint-drupal-module` → 机械修复 → `codex-diff-develop` → 逻辑修复 → `codex-pr-review` → 合并

### 安装

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

---

## milestone

> **你在 3 个对话中完成了一个 feature。第 4 个对话从零开始，因为上下文没有保留下来。**

milestone 存储了在任何未来对话中恢复开发工作所需的一切 — 目标、带状态的子任务、架构决策、代码引用和一个倒序时间日志，记录做了什么以及为什么。按名称加载一个里程碑，立即开始工作。

### 工作原理

- `/milestone` — 列出所有里程碑的状态和进度
- `/milestone <名称>` — 加载完整上下文（模糊匹配）
- `/milestone init <名称>` — 基于代码库创建新里程碑和子任务
- `/milestone add/done/update` — 管理子任务、决策和上下文

### 关键设计决策

- **仅追加的上下文日志** — 永不删除历史，只添加更正
- **规划器发现** — 自动检测已安装的规划技能
- **全局技能，本地数据** — 每个项目创建 `.milestones/`
- **8 条 NEVER 规则** — 不允许琐碎的里程碑、不允许重复、最多 10 个活跃

### 评估

- **`/skill-guard`**: 92/100 (GREEN)

### 安装

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

---

## usage-tracker

> **你使用 Claude Max。无按 token 计费。但你完全不知道哪个项目、对话或请求在消耗你的上下文限制。**

usage-tracker 解决了这个问题。一个 PostToolUse 钩子捕获每次工具调用，记录其 token 数、项目和触发它的用户请求——将不透明的使用历史转化为可按请求、项目、会话、工具和日期细分的可操作数据。

### 工作原理

```
用户："审查 auth 模块"
  └─ Read auth.module           → 1,200 tok   ┐
  └─ Grep hook                  →    80 tok   │ 同一"请求"
  └─ Read AuthService.php       → 2,400 tok   │ → 合计：4,980 tok
  └─ Bash lint auth/            → 1,300 tok   ┘
```

每条记录存储：时间戳、会话、项目、工具、模型、标签、请求文本、token 数。报告脚本聚合为可操作的细分。

### 不易察觉的关键点

钩子独立捕获工具调用——但 Claude 每次请求都会发送完整的对话历史。这造成了**非线性低估**：

| 消息轮次 | 实际低估幅度 |
|---------|------------|
| 5       | ~20%       |
| 20      | ~60%       |
| 40+     | ~80–90%    |

将其用作比较项目、会话和请求类型的**相对指数**——而非绝对成本。

最大的盲点：
- **Agent 调用** — 子 agent 对话完全不可见（日志中 500 token = 实际可能超过 20,000）
- **长对话** — 上下文呈二次方累积；为独立任务开启新对话
- **活跃技能** — 每个加载的 SKILL.md 都会为每次请求增加固定开销

### 命令

```bash
/usage-tracker install        # 设置钩子 + 脚本
/usage-tracker report hoy     # 今日报告
/usage-tracker report semana  # 过去 7 天
/usage-tracker top-requests   # 消耗最多的 15 个请求
/usage-tracker status         # 验证钩子是否活跃
```

### 安装

```bash
npx skills add j4rk0r/claude-skills@usage-tracker --yes --global
```

---

## 质量标准

每个技能使用 [skill-judge](https://github.com/softaworks/agent-toolkit) 评估 — 8 个维度，满分 120。**收录最低要求：B (96/120)。**

## 贡献

1. Fork 此仓库
2. 在 `skills/<名称>/SKILL.md` 中添加技能
3. 运行 `/skill-judge` — 需达到 B 或更高
4. 提交 PR 并附上评分

## 许可证

[MIT](../LICENSE)
