# codex-diff-develop

**[English](README.md)** | **[Español](README.es.md)** | **[Français](README.fr.md)** | **[Deutsch](README.de.md)** | **[Português](README.pt.md)** | **[中文](README.zh.md)** | **[日本語](README.ja.md)**

> **lint ツールが「問題なし」と言う — そして 3 週間後、update のみで動き insert で動かない hook が原因で本番が落ちる。**

codex-diff-develop は、**Codex メソドロジー** を使って現在のブランチと `develop` の差分を監査する Drupal 11 コードレビュースキルです。本番で実証された 18 のルールと、それぞれの *なぜ* を含みます。lint ツールが見逃すバグ — デプロイ後の午前 3 時にしか現れないバグ — をキャッチします。

## インストール

```bash
npx skills add j4rk0r/claude-skills@codex-diff-develop --yes --global
```

## 仕組み

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

## 18 の Codex ルール — それぞれに傷跡

各ルールには **なぜ**（それを教えた本番事故）が含まれています:

1. **`hook_entity_insert` vs `_update` の完全性** — `_update` のみのロジックは新規エンティティをスキップ
2. **空テーブルの集約 (MAX/MIN/COUNT) は NULL を返す、0 ではない**
3. **直接的な SQL 補間** — SQL インジェクション + 実際の名前のアポストロフィがクエリを壊す
4. **静的ガードのない hook の再帰** — cron でしか検出されない無限ループ
5. **トランザクションなしの複数書き込み** — 部分的な失敗 = 不整合な状態
6. **`connect_timeout` のない外部 API** — 遅いプロバイダーがキューワーカーをブロック
7. **正当化されない `accessCheck(FALSE)`** — 静かな権限バイパス
8. **不十分なキャッシュ無効化** — デプロイ後の古典的な「ローカルでは動く」
9. **リトライ/ダブルクリック操作の冪等性** — 重複注文、重複メール
10. **コード、スキーマ、DB 間の型の一貫性**
11. **キルスイッチなし** — 再デプロイする時間のない午前 3 時のインシデント
12. **`#process` のない AJAX フォーム alter** — alter は AJAX リビルドで失われる
13. **新しいクラスでの `\Drupal::service()`** — ユニットテストとカーネルテストをブロック
14. **`getCacheableMetadata()` のないカスタムブロック/フォーマッター** — BigPipe を静かに壊す
15. **古い設定スキーマ** — `drush cim` が他の環境で失敗
16. **クリーンな `id_map` のないマイグレーション** — 数ヶ月後に検出される破損したロールバック
17. **冪等でない update hook** — 部分的な失敗後の再実行で DB が悪化
18. **config split と衝突する `settings.php` のオーバーライド** — デプロイのたびに静かに失われる

## NEVER リスト — 15 の Drupal 固有アンチパターン

- **NUNCA** スタイルの発見（タイポ、空白）を「Alta」とマーク — 重要度を希釈する
- **NUNCA** 重大なセキュリティまたはデータ損失以外で diff 範囲外のリファクタリングを提案
- **NUNCA** 「以前からあった」という理由で新しいクラスの `\Drupal::service()` を承認
- **NUNCA** 次の行のインラインコメントなしで `accessCheck(FALSE)` を承認
- **NUNCA** ソースが 100% システム制御されていることを確認せずに Twig の `|raw` を承認
- **NUNCA** `loadMultiple([])` を承認 — すべてのエンティティを返す（古典的なメモリリーク）
- **NUNCA** 失敗を処理する `finished` コールバックなしの Batch API を承認
- **NUNCA** フィールドが存在することを確認せずに `EntityFieldManagerInterface::getFieldStorageDefinitions()` を承認
- **NUNCA** 高重要度の発見が未解決のままレポートを「OK」とマーク

## Codex 5 質問フレームワーク

各ブロックをレビューする前に:

1. **どんな種類の変更か？** Hook、リファクタリング、ホットフィックス、マイグレーション、設定
2. **本番での最悪のシナリオは？** 重要度の下限を設定
3. **変更が diff の外で前提としているものは？** スキーマ、インデックス、権限
4. **冪等か？** リトライ、ダブルクリック、再デプロイ
5. **無効化できるか？** config/setting/feature flag によるキルスイッチ

仮想的なミニ diff への適用方法をステップごとに示すワーキング例があります。

## レポート構造

```markdown
Español confirmado.

# Revisión de código — Diff develop (rama actual: <branch>)

## Resumen ejecutivo
## Hallazgos por categoría
### Seguridad
### Lógica de negocio / Codex
### Estándares / DI
### Performance / Cache
### Accesibilidad / i18n
### Tests / CI
## Riesgos (tabla)
## Sugerencias accionables
## Lo positivo
## Checklist final
```

各発見は **問題（重要度）** → **リスク** → **解決策** に従い、`references/` 内の 14 のテンプレートからのコードを使用します。

## IDE 自動検出

最初に `CLAUDE_CODE_ENTRYPOINT` を読み取ります（`claude-vscode`、`claude-cursor`、`claude-antigravity`）。環境変数が決定的でない場合のみフォルダ存在検出にフォールバック。

| 検出 | 出力フォルダ |
|---|---|
| `claude-antigravity` | `.antigravity/Revisiones diff/` |
| `claude-cursor` | `.cursor/Revisiones diff/` |
| `claude-vscode` | `.vscode/Revisiones diff/` |
| (なし / CLI) | `docs/revisiones-diff/` |

## 自己検証チェックリスト

配信前にスキルは 12 個のチェックを行います: 最初の行が正しい、ファイルが正しいフォルダにある、references がこのセッションで読み込まれている、各発見に問題/リスク/解決策がある、Alta はスタイルだけではない、スコープ外の提案がない、など。

## Recovery — 失敗したときに何をするか

| 症状 | アクション |
|---|---|
| `references/*.md` が見つからない | ユーザーに警告、Codex ポイントを発明しない |
| `git fetch` が失敗（ネットワーク） | ローカル `develop` で続行 + レポートにメモ |
| `.cursor/` が作成できない | フォルダを作成するようユーザーに依頼 |
| Diff > 200 ファイル | 続行する前に確認を求める |
| ユーザーが `develop` にいる | 明確なメッセージで中止 |

## 評価

- **`/skill-judge`**: 120/120 (グレード A+) — 8 つの次元すべてで完璧なスコア
- **`/skill-guard`**: 100/100 (緑) — 最小限の `allowed-tools` を宣言、ネットワークなし、MCP なし

| 次元 | スコア |
|-----|-------|
| Knowledge Delta | 20/20 |
| Mindset + Procedures | 15/15 |
| Anti-Pattern Quality | 15/15 |
| Specification Compliance | 15/15 |
| Progressive Disclosure | 15/15 |
| Freedom Calibration | 15/15 |
| Pattern Recognition | 10/10 |
| Practical Usability | 15/15 |

## 姉妹スキル

現在のブランチではなくリモート PR をレビューしたい場合は、[`codex-pr-review`](../codex-pr-review/) を使用してください — 同じ Codex メソドロジー、同じ references、`git fetch origin pull/<N>/head` で PR を取得します。

## ライセンス

MIT
