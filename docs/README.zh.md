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

## 技能列表

| 技能 | 功能 |
|------|------|
| **[skill-guard](../skills/skill-guard/)** | 在恶意技能接触你的文件、令牌或密钥之前拦截它。9层分析 + 社区验证的审计注册表。 |
| **[skill-advisor](../skills/skill-advisor/)** | 构建执行计划，将已安装技能与缺失的技能差距结合——然后提供安装。永远不要在装备不足时开始任务。 |
| **[skill-learner](../skills/skill-learner/)** | 捕获错误并持久化修正，让同样的错误不再重复。适用于技能和Claude的一般行为。可选择为技能作者生成改进建议。 |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Drupal 11 代码审查 — 使用 Codex 方法论审查当前分支与 `develop` 的差异。18条经过生产验证的规则，每条都附带 *为什么*。生成结构化 `.md` 报告。 |
| **[codex-pr-review](../skills/codex-pr-review/)** | Drupal 11 Pull Request 审查 — 使用与 `codex-diff-develop` 相同的 18 条 Codex 规则，但通过 `git fetch origin pull/<N>/head` 拉取 PR，可审查任何 GitHub PR。 |

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

## 质量标准

每个技能使用 [skill-judge](https://github.com/softaworks/agent-toolkit) 评估 — 8 个维度，满分 120。**收录最低要求：B (96/120)。**

## 贡献

1. Fork 此仓库
2. 在 `skills/<名称>/SKILL.md` 中添加技能
3. 运行 `/skill-judge` — 需达到 B 或更高
4. 提交 PR 并附上评分

## 许可证

[MIT](../LICENSE)
