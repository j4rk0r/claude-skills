# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **你在3次对话中完成了一个功能。第4次对话从零开始，因为上下文无法保留。**

milestone v2 是一个持久化开发追踪器，具有**两级缓存**：紧凑的内存快照（~100 tokens，自动加载）用于即时状态查询，权威文件用于完整历史记录。它将子任务分类为 `[simple]` 或 `[complex]`，要求在执行复杂工作之前制定计划——防止在同一文件上进行6+次迭代编辑的昂贵试错循环。

## 安装

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## 命令

| 阶段 | 命令 | 描述 |
|------|------|------|
| 发现 | `/milestone` | 列出所有里程碑及其状态和进度 |
| 发现 | `/milestone <名称>` | 加载上下文（模糊匹配） |
| 规划 | `/milestone init <名称>` | 创建新里程碑并提议子任务 |
| 执行 | `/milestone start <名称>` | 打开预加载紧凑上下文的新终端 |
| 执行 | `/milestone done <名称> <任务>` | 标记子任务为已完成 |
| 审查 | `/milestone update <名称>` | 工作会话后批量更新 |

## 核心特性

- **两级缓存** — 内存快照（~100 tok）用于读取，权威文件用于历史。比每次读取完整文件便宜99%。
- **复杂度分类** — `[simple]` vs `[complex]`。复杂任务在计划存在之前**被阻止**。
- **Token效率规则** — 同一文件3+更改 → 单次Write（比迭代Edit便宜10倍）。
- **新会话** — `/milestone start` 在新终端中打开 `claude`，带有紧凑上下文。
- **12条NEVER规则** — 防止脑裂、过时快照和编辑反模式。

## 评估

- **`/skill-judge`**：120/120（A+级）
- **`/skill-guard`**：92/100（GREEN）
