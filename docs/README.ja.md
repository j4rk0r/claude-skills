# j4rk0r/claude-skills

**[English](../README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

Claude Code 向けエキスパートグレードのスキル。全スキル出荷前に **A+ (120/120)** を獲得。

## 全てインストール

```bash
npx skills add j4rk0r/claude-skills --yes --global
```

または個別にインストール：

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

## スキル一覧

| スキル | 機能 |
|--------|------|
| **[skill-guard](../skills/skill-guard/)** | 悪意あるスキルがファイル・トークン・鍵に触れる前にキャッチ。9層分析 + コミュニティ検証済み監査レジストリ。 |
| **[skill-advisor](../skills/skill-advisor/)** | インストール済みスキルと不足しているギャップを組み合わせた実行計画を構築し、インストールを提案。装備不足でタスクを始めない。 |
| **[skill-learner](../skills/skill-learner/)** | エラーを捕捉し修正を永続化して同じミスを繰り返さない。スキルとClaudeの一般的な動作の両方に対応。オプションでスキル作者への改善提案を生成。 |
| **[codex-diff-develop](../skills/codex-diff-develop/)** | Codex メソドロジーで現在のブランチと `develop` の差分を監査する Drupal 11 コードレビュースキル。本番で実証された 18 のルールと、それぞれの *なぜ* を含む。構造化された `.md` レポートを生成。 |
| **[codex-pr-review](../skills/codex-pr-review/)** | Codex メソドロジーによる Drupal 11 プルリクエストレビュー。`codex-diff-develop` と同じ 18 のルールを使用するが、`git fetch origin pull/<N>/head` で PR を取得して任意の GitHub PR を監査できる。 |

## skill-guard

> **スキルをインストール。`~/.ssh`を読み取り、`$GITHUB_TOKEN`を取得し、リモートサーバーに送信。あなたは気づかない。**

skill-guardがこれを防ぎます。9層の分析エンジンを使ってインストール前にスキルを監査 — 静的パターンからLLMセマンティック分析まで、通常の指示に偽装されたプロンプトインジェクションを検出します。

### 仕組み

```
スキルをインストールしたい
        |
        v
skill-guard がコミュニティ監査レジストリを確認
        |
        v
監査済み（同じSHA）？ --> 前回のレポートを表示
未監査？              --> 「インストール前にセキュリティ分析を実行？」
        |
        v
9層分析：権限、パターン、スクリプト、
データフロー、MCP悪用、サプライチェーン、評判...
        |
        v
スコア 0-100 → グリーン / イエロー / レッド
        |
        v
グリーン：自動インストール | イエロー：あなたが判断 | レッド：強い警告
```

### 9つの分析層

1. **フロントマターと権限** (20%) — `allowed-tools`なし？Bash無制限？
2. **静的パターン** (15%) — URL、IP、機密パス、危険なコマンド
3. **LLMセマンティック分析** (30%) — プロンプトインジェクション、トロイの木馬、ソーシャルエンジニアリング
4. **バンドルスクリプト** (15%) — すべてのスクリプトを読む。危険なインポート、難読化
5. **データフロー** (10%) — ソース→宛先をマッピング。機密データが外部URLへ = 脅威
6. **MCPとツール** — 未宣言のMCP使用、Slack/GitHub/Monday経由の流出
7. **サプライチェーン** (2%) — タイポスクワッティング、未固定バージョン、偽リポジトリ
8. **評判** (3%) — 著者プロファイル、リポジトリの年齢、トロイの木馬フォーク
9. **アンチ回避** (5%) — Unicodeトリック、ホモグリフ、自己修正

### 2つの分析モード

- **完全監査** — 9層、完全レポート、レジストリ永続化
- **クイックスキャン** — 第1+2+3層のみ。HIGH/CRITICAL発見時に自動エスカレーション

**信頼モデル：** 監査結果の生成と公開はシステムのみが行います。コミュニティメンバーは `audits/requests/` へのPRで監査をリクエストし、メンテナーがskill-guardを実行して結果を公開します。これにより、改ざんされた監査がレジストリに入ることを防ぎます。

### インストール

```bash
npx skills add j4rk0r/claude-skills@skill-guard --yes --global
```

---

## skill-advisor

> **50個のスキルをインストール。使うのは5個。残り45個はホコリをかぶっている。**

skill-advisor がこの問題を解決します。あなたと Claude の間に位置し、すべての指示を分析して、あなたのインストール済みコレクションから最適なスキルを見つけます——作業開始前に。

### 仕組み

```
指示を入力
        |
        v
skill-advisor がインストール済みスキルをスキャン
        |
        v
マッチあり？ --> インパクト順に1-5個を推奨
マッチなし？ --> サイレントに続行（またはインストール可能なものを提案）
```

### 2つのモード

**プレアクション** — Claude が作業を始める前に、結果を改善するスキルを推奨。

**ポストアクション** — 作業完了後、論理的な次のステップを提案。

### 特徴

- **あなたのスキルを読む** — ハードコードされたリストなし。system-reminderを動的にスキャン。
- **水平思考** — 「もっときれいに」でデザイン、アニメーション、アクセシビリティ監査スキルを発見。
- **沈黙すべき時を知っている** — シンプルなタスクには推奨しない。
- **パイプラインを推奨** — マルチステップシナリオを検出し、完全なコンボを提案。
- **コミュニティフォールバック** — ローカルに一致なしの場合、インストール可能なスキルを提案。

### インストール

```bash
npx skills add j4rk0r/claude-skills@skill-advisor --yes --global
```

---

## skill-learner

> **Claudeは謝罪し、改善を約束する——そして次のセッションでまったく同じミスをする。**

skill-learnerはこのサイクルを断ち切ります。スキルやClaude自体がミスした時、何が間違っていたか、なぜか、代わりに何をすべきかを捕捉し、セッション間で永続化する修正ファイルとして保存します。

### 主な機能

- **失敗したスキルを自動検出** — 会話コンテキストから識別
- **重複排除** — 作成前にINDEX.mdを確認、同じ問題が存在すればマージ
- **9つのNEVERルール** — 曖昧な修正、重複、セキュリティバイパスを防止
- **コールドリーダーテスト** — 各修正が別セッションの別エージェントに明確か検証
- **改善提案** — diffを含む提案を生成、ユーザーが提出できるようローカル保存
- **バイリンガル** — ユーザーの言語で修正を記述してニュアンスを保持

### インストール

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

### 仕組み

```
何かがうまくいかなかった
        |
        v
skill-learner がどのスキル（または一般的な動作）が失敗したか検出
        |
        v
エラーを理解するまで的確な質問を行う
        |
        v
構造化された修正を ~/.claude/skill-corrections/ に保存
        |
        v
次回そのスキルが実行される時 → 修正が利用可能
        |
        v
オプション：スキル作者への改善提案を生成
```

### 主な機能

- **失敗したスキルを自動検出** — 会話コンテキストから識別
- **重複排除** — 作成前にINDEX.mdを確認、同じ問題が存在すればマージ
- **9つのNEVERルール** — 曖昧な修正、重複、セキュリティバイパスを防止
- **コールドリーダーテスト** — 各修正が別セッションの別エージェントに明確か検証
- **改善提案** — diffを含む提案を生成、ユーザーが提出できるようローカル保存
- **バイリンガル** — ユーザーの言語で修正を記述してニュアンスを保持

### インストール

```bash
npx skills add j4rk0r/claude-skills@skill-learner --yes --global
```

---

## codex-diff-develop

> **lint ツールが「問題なし」と言う — そして 3 週間後、update のみで動き insert で動かない hook が原因で本番が落ちる。**

codex-diff-develop は、**Codex メソドロジー** を使って現在のブランチと `develop` の差分を監査する Drupal 11 コードレビュースキルです。本番で実証された 18 のルールと、それぞれの *なぜ* を含みます。lint ツールが見逃すバグ — デプロイ後の午前 3 時にしか現れないバグ — をキャッチします。

### 仕組み

```
あなた: "revision diff develop"
        |
        v
コンテキストを検出: ブランチ、drupal/ サブディレクトリ、diff 内のファイルタイプ
        |
        v
references を MANDATORY 読み込み (18 Codex ルール + 14 発見テンプレート)
        |
        v
Codex 5 質問フレームワークを適用
        |
        v
ファイルタイプごとに関連 Codex ルールを決定木で選択
        |
        v
diff のみをレビュー、スコープ外の提案なし
        |
        v
IDE を自動検出 → .vscode/.cursor/.antigravity にレポートを書き込み
        |
        v
配信前に 12 項目チェックリストで自己検証
```

### 18 の Codex ルール — それぞれに傷跡

各ルールには **なぜ**（それを教えた本番事故）が含まれています:

1. **`hook_entity_insert` vs `_update` の完全性** — `_update` のみのロジックは新規エンティティをスキップ
2. **空テーブルの集約 (MAX/MIN/COUNT) は NULL を返す、0 ではない**
6. **`connect_timeout` のない外部 API** — 遅いプロバイダーがキューワーカーをブロック
7. **正当化されない `accessCheck(FALSE)`** — 静かな権限バイパス
9. **リトライ/ダブルクリック操作の冪等性** — 重複注文、重複メール
11. **キルスイッチなし** — 再デプロイする時間のない午前 3 時のインシデント
14. **`getCacheableMetadata()` のないカスタムブロック/フォーマッター** — BigPipe を静かに壊す

完全なリストと *なぜ* は [`references/metodologia-codex-completa.md`](../skills/codex-diff-develop/references/metodologia-codex-completa.md) にあります。

### NEVER リスト — 15 の Drupal 固有アンチパターン

- **NUNCA** スタイルの発見を「Alta」とマーク — 重要度を希釈する
- **NUNCA** 重大なセキュリティ以外で diff 範囲外のリファクタリングを提案
- **NUNCA** `loadMultiple([])` を承認 — すべてのエンティティを返す（古典的なメモリリーク）
- **NUNCA** 失敗を処理する `finished` コールバックなしの Batch API を承認

### Codex 5 質問フレームワーク

1. **どんな種類の変更か？**
2. **本番での最悪のシナリオは？**
3. **変更が diff の外で前提としているものは？**
4. **冪等か？**
5. **無効化できるか？**

### 出力

構造化された `.md` レポート: エグゼクティブサマリー、カテゴリ別の発見（セキュリティ、Codex ロジック、標準/DI、パフォーマンス、A11y/i18n、テスト/CI）、リスクテーブル、アクション可能リスト、「ポジティブな点」セクション、最終チェックリスト。各発見は **問題（重要度）** → **リスク** → **解決策** に従います。

### IDE 自動検出

最初に `CLAUDE_CODE_ENTRYPOINT` を読み取ります。環境変数が決定的でない場合のみフォルダ存在検出にフォールバック。

### 評価

- **`/skill-judge`**: 120/120 (グレード A+)
- **`/skill-guard`**: 100/100 (緑) — 最小限の `allowed-tools` を宣言、ネットワークなし、MCP なし

### インストール

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

---

## codex-pr-review

> **レビュアーが「LGTM」と言う — そして 3 週間後、update のみで動く hook が原因で本番が落ちる。**

codex-pr-review は、**リモートプルリクエスト** 用の `codex-diff-develop` の姉妹スキルです。同じ Codex メソドロジー、同じ 18 のルール、同じテンプレート — しかし `git fetch origin pull/<N>/head` で PR を取得して、任意の GitHub PR を番号で監査できます。

### codex-diff-develop との違い

| 観点 | codex-diff-develop | codex-pr-review |
|---|---|---|
| diff のソース | `git diff origin/develop...HEAD` | `git fetch origin pull/<N>/head` + `git diff base...pr-<N>` |
| 出力フォルダ | `Revisiones diff/` | `Revisiones PRs/` |
| ファイル名 | `lint-review-diff-develop-<branch>.md` | `lint-review-pr<N>.md` |
| トリガー | "diff develop", "codex diff" | "revision PR", "revisar PR #N", "codex PR" |
| 追加 NEVER | — | "**NUNCA** ドキュメント内で他の PR を参照しない" |
| 追加エッジケース | — | GitLab フォールバック、PR 既マージ済み、PR 番号なし |

### どちらをいつ使うか

- **`codex-diff-develop`**: ブランチでローカル作業中で、プッシュ前に自分の変更をレビューしたい
- **`codex-pr-review`**: ローカルチェックアウトせずに他人の PR（またはプッシュ後の自分の PR）をレビューしたい

### 評価

- **`/skill-judge`**: 120/120 (グレード A+)
- **`/skill-guard`**: 100/100 (緑)

### インストール

```bash
npx skills add j4rk0r/claude-skills@codex-pr-review --yes --global
```

---

## 品質基準

全スキルは [skill-judge](https://github.com/softaworks/agent-toolkit) で評価 — 8次元、最大120点。**収録最低基準：B (96/120)。**

## コントリビュート

1. このリポジトリをフォーク
2. `skills/<名前>/SKILL.md` にスキルを追加
3. `/skill-judge` を実行 — B以上が必要
4. スコアを添えてPRを作成

## ライセンス

[MIT](../LICENSE)
