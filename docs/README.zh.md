# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

专家级 Claude Code 技能。每个技能发布前均获得 **A+ (120/120)** 评分。

## 安装

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## 技能列表

| 技能 | 功能 | 安装 |
|------|------|------|
| **[skill-guard](../skills/skill-guard/)** | 在恶意技能接触你的文件、令牌或密钥之前拦截它。9层分析 + 社区验证的审计注册表。 | `npx skills add j4rk0r/claude-skills@skill-guard -y -g` |
| **[skill-advisor](../skills/skill-advisor/)** | 构建执行计划，将已安装技能与缺失的技能差距结合——然后提供安装。永远不要在装备不足时开始任务。 | `npx skills add j4rk0r/claude-skills@skill-advisor -y -g` |
| **[skill-learner](../skills/skill-learner/)** | 捕获错误并持久化修正，让同样的错误不再重复。适用于技能和Claude的一般行为。可选择为技能作者生成改进建议。 | `npx skills add j4rk0r/claude-skills@skill-learner -y -g` |

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

## 质量标准

每个技能使用 [skill-judge](https://github.com/softaworks/agent-toolkit) 评估 — 8 个维度，满分 120。**收录最低要求：B (96/120)。**

## 贡献

1. Fork 此仓库
2. 在 `skills/<名称>/SKILL.md` 中添加技能
3. 运行 `/skill-judge` — 需达到 B 或更高
4. 提交 PR 并附上评分

## 许可证

[MIT](../LICENSE)
