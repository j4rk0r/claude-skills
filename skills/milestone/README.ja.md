# milestone

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**
> ⚠️ **v1.1.0 — atomic claim (R14) added.** This translated page may not yet reflect the latest team-mode improvements. See the [English README](README.md), [CHANGELOG.md](CHANGELOG.md) and [SKILL.md](SKILL.md) for full details on the R14 atomic claim.

> **3 回の会話にまたがって機能を完成させた。4 回目はコンテキストが残らないためゼロから始まる。しかも同僚は古いタスクリストで作業している。**

milestone v2 は **2 層キャッシュ**を備えた永続的な開発トラッカーです。即時ステータス用のコンパクトなメモリスナップショット（約 100 トークン、自動ロード）と、深い履歴用の完全な権威ファイルを持ちます。サブタスクを `[simple]` または `[complex]` に分類し、複雑な作業を実行する前に計画を必須とすることで、同じファイルに対する 6 回以上の反復編集という高コストな試行錯誤サイクルを防ぎます。**オプションのチームモード（R13）** は、milestone を単一の共有された信頼の源とし、正準ブランチへ git 同期することで、チーム全員が常に同じ最新リストを見られるようにします。

## インストール

```bash
npx skills add j4rk0r/claude-skills@milestone --yes --global
```

## 仕組み

```
あなた: "/milestone dashboard"
        |
        v
（チームモード）まず正準ブランチに新しい milestone があるか確認
        |
        v
メモリスナップショットを読む（ファイル読み取りゼロ — すでにコンテキスト内）
        |
        v
表示: 目的、保留中のサブタスク、決定事項、最新のコンテキストエントリ
        |
        v
サブタスクを分類: [simple] -> 実行 | [complex] -> 先に計画
        |
        v
作業後: milestone ファイルを更新 + スナップショットを再生成
        |
        v
（チームモード）.milestones/ を正準ブランチへ git 同期
        |
        v
次の会話 / 次の同僚: 即座に最新のコンテキスト
```

## コマンド

| フェーズ | コマンド | 説明 |
|-------|---------|-------------|
| Discovery | `/milestone` | すべての milestone をステータスと進捗とともに一覧 |
| Discovery | `/milestone <name>` | コンテキストをロード（ファジーマッチ — "dash" が "dashboard-propietario" にヒット） |
| Planning | `/milestone init <name>` | サブタスク提案付きで新しい milestone を作成 |
| Execution | `/milestone start <name>` | コンパクトなコンテキストを事前ロードした新しいターミナルセッションを開く |
| Execution | `/milestone done <name> <subtask>` | 最小限の編集でサブタスクを完了マーク |
| Review | `/milestone update <name>` | 作業セッション後の一括更新 |

## 主な機能

- **2 層キャッシュ** — 読み取りはメモリスナップショット（約 100 トークン）、完全な履歴は権威ファイル。毎回ファイル全体を読むより 99% 安価。
- **複雑度分類** — `[simple]`（1 ファイル、明確な変更）対 `[complex]`（複数ファイル、新ロジック）。複雑なサブタスクは計画が存在するまで **ブロック** されます。
- **トークン効率ルール** — 同一ファイルへ 3 回以上の変更 → 単一の Write（反復 Edit より 10 倍安価）。すでにコンテキスト内のファイルは再読込しない。
- **新セッションコマンド** — `/milestone start` はコンパクトなコンテキストを持つ新しいターミナルウィンドウで新鮮な `claude` を開き、蓄積された会話履歴による 5〜10 倍のコスト乗数を排除します。
- **チームモード（R13, opt-in）** — 単一の共有 milestone を、隔離された worktree 経由で正準ブランチ（既定 `develop`）へ git 同期。チーム全員が同じライブリストを読み書きします。既定では無効。
- **ファジーマッチング** — 部分名を入力して milestone をロード
- **追記専用コンテキストログ** — 何が起き、なぜかを逆時系列で記録
- **17 個の NEVER ルール** — スプリットブレイン防止、古いスナップショット、編集アンチパターン、チーム git 同期の危険をカバー

## チームモード（R13）— opt-in

これがないと milestone はマシンローカルのファイルです。チームではこれが重複リスト（各フィーチャーブランチが同じファイルを編集）や古いタスクリストへと劣化します。チームモードは milestone を **正準ブランチ上の単一の共有された信頼の源** とし、専用 worktree 経由でそのブランチに対してのみ編集します — コードブランチ内では決して編集しません。

プロジェクトごとに `.milestones/config.yml` で有効化します:

```yaml
milestone_sync:
  enabled: true        # 無い、または false -> R13 全体が静かな no-op
  branch: develop      # 正準ブランチ（既定: develop）
  path: .milestones     # 同期サブディレクトリ（既定: .milestones）
```

- **読み取り時**（`/milestone <name>`, `/milestone sync`）: 正準ブランチを取得し、同僚が milestone を進めていれば警告し、作業前に取り込むよう促します。
- **書き込み時**（init / update / done / セッション終了）: スナップショット更新後、`<path>/<slug>.md` **のみ** をコミットし、`.git/` 下の隔離 worktree 経由で正準ブランチへ push します — あなたのコードブランチと作業ツリーは決して触れません。
- **PR スタンプ**: 作業がオープン PR にあるサブタスクは状態 `[~]` を保ち、インライン注記 `` `⏳ PR #N` `` を付けます（新しい状態ではありません — `[~]` はすでに「code-complete、承認待ち」を意味し、PR はその承認の手段です）。
- **優雅な縮退**: git なし / リモートなし / 正準ブランチなし / ブロック不在 → 静かな no-op。ゼロ依存の約束は維持されます。
- **ガードを決して回避しない**: push がセキュリティガードや認証でブロックされた場合、コミットは worktree に残り、実行すべき正確なコマンドが提示されます — 失敗を握りつぶさず、作業をブロックしません。

## アーキテクチャ

```
~/.claude/projects/<project>/memory/milestone_<slug>.md  ← HOT（自動ロード、約 100 トークン）
<project-root>/.milestones/<slug>.md                      ← 権威（完全な履歴）
<project-root>/.milestones/plans/<slug>-<subtask>.md      ← [complex] サブタスクの計画
<project-root>/.git/milestone-sync-wt/                     ← 隔離された R13 worktree（チームモードのみ）
```

## v1 との違い

| 観点 | v1 | v2 |
|--------|----|----|
| ロードコスト | 約 8,300 トークン（Read 全ファイル + テンプレート） | 約 100 トークン（メモリスナップショット） |
| 一覧コスト | 約 8,750 トークン（Read 全ファイル） | 約 400 トークン（frontmatter のみ、limit:8） |
| 複雑なサブタスク | ゲートなし — 試行錯誤 | 実行前に計画が必須 |
| セッション管理 | 同一会話（コンテキストが蓄積） | `/milestone start` が新鮮なセッションを開く |
| リファレンスロード | 常に templates.md をロード | `/milestone init` 時のみ |
| チーム協働 | なし — ローカルファイルのみ | opt-in の git 同期共有 milestone（R13） |

## 評価

- **`/skill-judge`**: 120/120（グレード A+）
- **`/skill-guard`**: 92/100（GREEN）— 通常運用でスクリプト実行なし、ネットワークなし、MCP なし。R13（opt-in、既定オフ）が git 操作を行う唯一の経路です。

## セキュリティ

- 既定ではローカルの `.milestones/*.md` とメモリスナップショットファイルのみ読み書き。通常運用でネットワークなし、スクリプトなし。
- `allowed-tools: Read Write Edit Glob Grep Bash`
- Bash は `/milestone start`（初回使用時にスクリプトを自動インストール）と、**チームモードが明示的に有効な場合のみ** `milestone-sync.sh` に使用 — これは隔離 worktree 経由で正準ブランチに対し `<path>/` に限定した `git fetch`/`git push` を実行します。既定では無効。コードを push しない。セキュリティガードを回避しない（ブロックされた push → 報告、握りつぶさない）。
