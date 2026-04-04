# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

专家级 Claude Code 技能。每个技能发布前均获得 **A+ (120/120)** 评分。

## 安装

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

## 技能列表

| 技能 | 功能 | 评分 |
|------|------|------|
| **[skill-advisor](../skills/skill-advisor/)** | 分析每条指令，在执行前推荐最佳技能。再也不会遗忘已安装的技能。 | 120/120 |

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
- **知道何时沉默** — 简单任务不推荐。问自己："用户会感谢还是被打扰？"
- **推荐流水线** — 检测多步骤场景，建议完整组合。
- **社区回退** — 本地无匹配时，建议可安装的技能。

## 质量标准

每个技能使用 [skill-judge](https://github.com/softaworks/agent-toolkit) 评估 — 8 个维度，满分 120。**收录最低要求：B (96/120)。**

## 贡献

1. Fork 此仓库
2. 在 `skills/<名称>/SKILL.md` 中添加技能
3. 运行 `/skill-judge` — 需达到 B 或更高
4. 提交 PR 并附上评分

## 许可证

[MIT](../LICENSE)
