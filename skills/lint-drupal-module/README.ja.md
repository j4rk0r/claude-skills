# lint-drupal-module

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **手動のコードレビューで29件の問題が見つかります。PHPStanとPHPCSを手動で実行します。レビュアーに標準とセキュリティを見てもらいます。45分後にようやく統合された全体像が得られます — そしてモジュールのJSファイルの140件の違反を見逃しています。誰もJavaScriptに対してPHPCSを実行しなかったからです。**

`lint-drupal-module` は Drupal 11 の lint review skill で、**4つのソースを並列に実行**します — PHPStan level 5(`phpstan-drupal` と共に)、PHPCS(Drupal/DrupalPractice)、標準チェック用の `drupal-qa` エージェント、OWASP ベクトルチェック用の `drupal-security` エージェント — そして発見事項を1つのアクション可能なレポートに統合します。以前は12の手動ステップと30分かかっていたものが、今では1回の呼び出しで、最も遅いソースにかかる時間(完全モードで2-5分、diffモードで30秒-1分)で完了します。

## インストール

```bash
npx skills add j4rk0r/claude-skills@lint-drupal-module --yes --global
```

## 仕組み

```
あなた:「lint review del módulo chat_soporte_tecnico_ia」
        |
        v
モジュールを識別(名前、パス、または Glob で)
        |
        v
モードを選択:完全(デフォルト)| diff(vs develop)
        |
        v
環境を検出(ddev exec を使う DDEV、またはローカル composer)
        |
        v
PHPStan + phpstan-drupal が無ければインストール(最初に確認)
        |
        v
references/prompts-agentes.md をロード(エージェント呼び出し前に必須)
        |
        v
同じメッセージで4つのソースを並列起動:
  • Agent drupal-qa         (標準)
  • Agent drupal-security   (OWASP)
  • PHPStan level 5
  • PHPCS Drupal/DrupalPractice
        |
        v
references/plantilla-informe.md をロード(書く前に必須)
        |
        v
4つの出力を1つの markdown レポートに統合
        |
        v
IDEを自動検出(Antigravity / Cursor / VS Code)
        |
        v
<ide>/Lint reviews/lint-review-<モジュール>-<モード>-<ブランチ>.md に書き込む
        |
        v
チャットで上位のブロッカーを要約し、尋ねる:
  「arregla todo」/「solo crítico」/「auto-fix PHPCS」/「déjalo así」
```

## 2つのモード

**完全(デフォルト)** — モジュール内のすべてのファイルを分析します。より徹底的、より遅い(~2-5分)。リリース前、新しく作成されたモジュール、または定期的な監査で使用します。

**Diff** — 現在のブランチで `origin/develop` に対して変更されたファイルのみを分析します。より速い(~30秒-1分)。開発中の中間レビュー、プッシュ前の検証、または新しいものだけが気になる場合に使用します。

```bash
cd drupal && git fetch origin develop --quiet
git diff --name-only origin/develop...HEAD \
  | grep "^web/modules/custom/<name>/" \
  | grep -E '\.(php|module|inc|install|profile|theme|yml|twig)$'
```

## 手動レビューが見逃すものを検出する

このskillは実際のDrupal 11モジュール(32ファイル)に対して検証されました。エージェントのみの手動レビューでは29件の問題が報告されました。skillの完全な並列化パイプラインを実行すると**65件の問題**が浮上しました — その中にはモジュールのJavaScriptに対する166件のPHPCS違反(ほとんどが`phpcbf`で自動修正可能)が含まれており、手動レビュアーはJSがスコープ外だったため一度もチェックしていませんでした。

これがポイントです:lint reviewはその最も弱いレイヤーと同じ価値しかありません。静的解析(PHPStan)、スタイル強制(PHPCS)、専門エージェントを並列に組み合わせることで、どの単一のソースも見ないものを捕捉できます。

## レポート構造

すべてのレポートは同じ固定テンプレートに従います(チームが再学習することなく異なるモジュールのレポートを読めるようにするため):

1. **エグゼクティブサマリー** — ソース別の発見事項の表、上位5つのブロッカー、カテゴリ別の判定(`適合`、`軽微な修正が必要な適合`、`重大な修正が必要な適合`、`不適合`)
2. **PHPStan level 5** — ファイル別にグループ化されたエラー
3. **PHPCS Drupal/DrupalPractice** — ファイル別にグループ化された違反
4. **標準(drupal-qa)** — 修正提案付きの重大度別発見事項
5. **セキュリティ(drupal-security)** — 脆弱性の分類 🔴 クリティカル / 🟠 高 / 🟡 中 / 🟢 低 / ℹ️ 情報
6. **優先順位付けされたアクション** — P0(ブロッカー)、P1(推奨)、P2(改善)
7. **ベストプラクティスのカバレッジ** — strict_types、OOP hooks、DI、routing の CSRF、cache metadata、config schema、permissions、translation、behaviors、tests のチェックリスト
8. **検証コマンド** — ローカルで再実行するための正確なコマンド

## NEVER(痛い目にあって学んだ教訓)

- **skill中にファイルを絶対に変更しない。** レポートのみ。修正は、明示的なユーザー確認を伴う別のフェーズです。
- **4つのソースを別々のメッセージで絶対に実行しない。** 並列化がコアバリューであり、順次実行は4倍の時間がかかります。
- **未解決のHIGH/CRITICAL発見事項があるとき、判定を「適合」と絶対にマークしない。**
- **Controllersの `Unsafe usage of new static()` を絶対にブロッカーとしてリストしない** — DrupalのStandardパターンに対するphpstan-drupalの既知の誤検知です。
- **Hook OOPがtype-hint経由で使用しているかどうかを確認せずに、`services.yml` のFQCNエイリアスを絶対に削除しない。** `drush cr` を壊す既知の方法です。
- **PHPUnitが失敗しないからといって、機能テストがパスしていると絶対に仮定しない。** PHPStanが `tests/` ディレクトリで存在しないメソッド(`getClient()`、`post()`)を報告する場合、テストはCIで黙って失敗している可能性があります。
- **レポートを英語で絶対に書かない。** コード、コマンド、クラス名は英語で、説明はスペイン語で。

## 姉妹skillとの関係

- **`codex-diff-develop`** — Codex 18ルールの方法論を使用してdiff上のビジネスロジックをレビューします。このskill(静的解析と標準を行う)を補完し、ロジックのバグを捕捉します。
- **`codex-pr-review`** — 完全なPRのアーキテクチャレビュー。このskillの1レベル上。
- **理想的なマージ前ワークフロー:**
  1. `lint-drupal-module` → メカニカルな修正(型、標準、セキュリティベクトル)
  2. `codex-diff-develop` → ビジネスロジックの修正
  3. `codex-pr-review` → マージ前の最終アーキテクチャレビュー

## 要件

- Drupal 11 プロジェクト(`Glob "**/web/modules/custom/*/*.info.yml"` でモジュールを検出)
- DDEV 推奨(skillは `ddev exec` 経由でコンテナ内でツールを実行します)
- `drupal-qa` と `drupal-security` のサブエージェントが利用可能(欠けている場合はPHPStan + PHPCSのみに優雅にデグレード)
- 並列tool useを持つAnthropic Claude(順次実行は動作しますが4倍遅い)

## ライセンス

MIT。リポジトリのLICENSEを参照してください。
