# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**
> ⚠️ **v1.1.0 — atomic claim (R14) added.** This translated page may not yet reflect the latest team-mode improvements. See the [English README](README.md), [CHANGELOG.md](CHANGELOG.md) and [SKILL.md](SKILL.md) for full details on the R14 atomic claim.

> **你跨 3 次对话完成了一个功能。第 4 次从零开始，因为上下文无法存活。而且你的同事还在用一份过时的待办清单。**

milestone v2 是一个具备**双层缓存**的持久化开发追踪器：用于即时状态的紧凑内存快照（约 100 tokens，自动加载），以及用于深度历史的完整权威文件。它将子任务分类为 `[simple]` 或 `[complex]`，在执行复杂工作前要求先有计划——避免对同一文件进行 6 次以上迭代编辑的高成本试错循环。**可选的团队模式（R13）** 让 milestone 成为单一共享的事实来源，通过 git 同步到一个规范分支，使整个团队始终看到同一份最新清单。

## 安装

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## 工作原理

```
你: "/milestone dashboard"
        |
        v
（团队模式）先检查规范分支上是否有更新的 milestone
        |
        v
读取内存快照（零文件读取——已在上下文中）
        |
        v
显示：目标、待办子任务、决策、最近一条上下文记录
        |
        v
子任务分类：[simple] -> 执行 | [complex] -> 先做计划
        |
        v
工作后：更新 milestone 文件 + 重新生成快照
        |
        v
（团队模式）将 .milestones/ git 同步到规范分支
        |
        v
下一次对话 / 下一位同事：即时、最新的上下文
```

## 命令

| 阶段 | 命令 | 说明 |
|-------|---------|-------------|
| Discovery | `/milestone` | 列出所有 milestone 及其状态与进度 |
| Discovery | `/milestone <name>` | 加载上下文（模糊匹配——"dash" 命中 "dashboard-propietario"） |
| Planning | `/milestone init <name>` | 创建带子任务建议的新 milestone |
| Execution | `/milestone start <name>` | 打开预加载紧凑上下文的全新终端会话 |
| Execution | `/milestone done <name> <subtask>` | 以最小编辑标记子任务完成 |
| Review | `/milestone update <name>` | 工作会话后的批量更新 |

## 核心特性

- **双层缓存** — 读取用内存快照（约 100 tok），完整历史用权威文件。比每次读取整个文件便宜 99%。
- **复杂度分类** — `[simple]`（1 个文件，明确改动）对 `[complex]`（多文件，新逻辑）。复杂子任务在计划存在前被**阻止**。
- **Token 效率规则** — 同一文件 3+ 处改动 → 单次 Write（比迭代 Edit 便宜 10 倍）。不重复读取已在上下文中的文件。
- **新会话命令** — `/milestone start` 在新终端窗口打开带紧凑上下文的全新 `claude`，消除累积对话历史带来的 5-10 倍成本乘数。
- **团队模式（R13，opt-in）** — 单一共享 milestone，经隔离 worktree 同步到规范分支（默认 `develop`），使整个团队读写同一份实时清单。默认关闭。
- **模糊匹配** — 输入部分名称即可加载 milestone
- **仅追加的上下文日志** — 以逆时间顺序记录发生了什么及原因
- **17 条 NEVER 规则** — 涵盖脑裂预防、过期快照、编辑反模式以及团队 git 同步风险

## 团队模式（R13）— opt-in

没有它，milestone 是每台机器本地的文件。在团队中这会退化为重复清单（每个功能分支都编辑同一文件）和过时的待办清单。团队模式让 milestone 成为**规范分支上单一共享的事实来源**，只针对该分支通过专用 worktree 编辑——绝不在代码分支内编辑。

按项目在 `.milestones/config.yml` 中启用：

```yaml
milestone_sync:
  enabled: true        # 缺失或 false -> 整个 R13 为静默 no-op
  branch: develop      # 规范分支（默认：develop）
  path: .milestones     # 同步的子目录（默认：.milestones）
```

- **读取时**（`/milestone <name>`、`/milestone sync`）：拉取规范分支，若同事推进了 milestone，会在你开始工作前提示并提供采纳。
- **写入时**（init / update / done / 会话结束）：刷新快照后，**仅**提交 `<path>/<slug>.md` 并经 `.git/` 下隔离 worktree 推送到规范分支——绝不触碰你的代码分支与工作树。
- **PR 标记**：工作处于已开 PR 的子任务保持 `[~]` 状态，并加上内联标注 `` `⏳ PR #N` ``（不是新状态——`[~]` 已表示「代码完成，待批准」，PR 即该批准的载体）。
- **优雅降级**：无 git / 无远程 / 无规范分支 / 配置块缺失 → 静默 no-op。零依赖承诺依然成立。
- **绝不绕过守卫**：若推送被安全守卫或鉴权阻止，提交保留在 worktree 中并给出确切的执行命令——绝不掩盖失败，也不阻塞你的工作。

## 架构

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT（自动加载，约 100 tok）
<project-root>/.milestones/<slug>.md                      ← 权威（完整历史）
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← [complex] 子任务的计划
<project-root>/.git/milestone-sync-wt/                     ← 隔离的 R13 worktree（仅团队模式）
```

## 与 v1 的区别

| 方面 | v1 | v2 |
|--------|----|----|
| 加载成本 | 约 8,300 tok（Read 完整文件 + 模板） | 约 100 tok（内存快照） |
| 列表成本 | 约 8,750 tok（Read 所有文件） | 约 400 tok（仅 frontmatter，limit:8） |
| 复杂子任务 | 无门槛——试错 | 执行前需有计划 |
| 会话管理 | 同一对话（上下文累积） | `/milestone start` 打开全新会话 |
| 引用加载 | 总是加载 templates.md | 仅在 `/milestone init` 时 |
| 团队协作 | 无——仅本地文件 | opt-in 的 git 同步共享 milestone（R13） |

## 评估

- **`/skill-judge`**：120/120（评级 A+）
- **`/skill-guard`**：92/100（GREEN）——正常运行不执行脚本、无网络、无 MCP。R13（opt-in，默认关闭）是唯一执行 git 操作的路径。

## 安全

- 默认仅读写本地 `.milestones/*.md` 与内存快照文件。正常运行无网络、无脚本。
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash 用于 `/milestone start`（首次使用时自动安装脚本），以及**仅当团队模式被显式启用时**用于 `milestone-sync.sh`——它经隔离 worktree 针对规范分支执行仅限 `<path>/` 的 `git fetch`/`git push`。默认关闭；绝不推送代码；绝不绕过安全守卫（被阻止的推送 → 报告而非掩盖）。
