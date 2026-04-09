# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **你在3次对话中完成了一个功能。第4次对话从零开始，因为上下文无法保留。**

milestone 是一个持久化的开发追踪器，将完整的上下文作为 markdown 文件存储在你的项目中。每个里程碑都是一个自包含的胶囊：目标、带状态的子任务、架构决策、代码引用以及一份记录做了什么和为什么的日志。在任何对话中加载它，从上次离开的地方继续。

## 安装

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## 命令

| 命令 | 描述 |
|------|------|
| `/milestone` | 列出所有里程碑及其状态、进度和快速加载链接 |
| `/milestone <名称>` | 加载里程碑的完整上下文（模糊匹配） |
| `/milestone init <名称>` | 创建带有目标和子任务的新里程碑 |
| `/milestone add <名称> <内容>` | 添加子任务、决策、笔记或引用 |
| `/milestone done <名称> <子任务>` | 将子任务标记为已完成 |
| `/milestone update <名称>` | 工作会话后批量更新上下文 |

## 主要特性

- **跨对话持久化** — 文件存储在 `.milestones/` 中，在任何会话后都能保留
- **自包含上下文** — 每个文件包含恢复工作所需的一切
- **规划工具发现** — 自动检测已安装的规划技能并提供统一其结果
- **自动状态** — 状态根据子任务复选框自动重新计算
- **模糊匹配** — 输入 "dash" 即可加载 "dashboard-propietario"
- **仅追加的上下文日志** — 逆时间顺序记录发生了什么以及为什么
- **全局技能，本地数据** — 安装一次，创建项目特定的数据

## 安全性

- Skill-Guard 审计：**92/100 GREEN**
- 无脚本、无网络调用、无 MCP 访问
- `allowed-tools: Read Write Edit Glob Grep`
