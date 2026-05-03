# インストール手順

このリポは「設計テンプレート集」なので、`npm install` のような単一コマンドで動くものではありません。
利用者が自組織の文脈に合わせて**順次組み込んでいく**前提です。

---

## ステップ 1: クローンと配置

```bash
git clone https://github.com/harness-jp/harness-cxo-council.git
cd harness-cxo-council
```

このリポを**そのまま使う**場合と、**自リポにマージする**場合のどちらかを選択。

### 選択肢 A: そのまま使う

特定のディレクトリ配下で運用する場合は、このディレクトリで作業を開始。

### 選択肢 B: 自リポにマージする

自分の既存リポに以下のディレクトリ・ファイルをコピー:

```bash
# 例: 自リポのルートで実行
cp -r path/to/harness-cxo-council/roles ./
cp -r path/to/harness-cxo-council/memory ./
cp -r path/to/harness-cxo-council/prompts ./
cp -r path/to/harness-cxo-council/workflows ./.github/workflows/
```

---

## ステップ 2: ロールカードのカスタマイズ

`roles/*.md` の `{}` で囲まれた箇所を自組織の文脈に置換。

主なカスタマイズ箇所:

| プレースホルダ | 意味 | 例 |
|---|---|---|
| `{KEY_KPI}` | 北極星 KPI | 月次成約数 / ARR / 解約率 |
| `{KEY_STAKEHOLDER}` | 最重要ステークホルダー | 上司 / 主要顧客 / 投資家 |
| `{NORTH_STAR_DEADLINE}` | 重要時限プロジェクトの期限 | 2026-12-31 |
| `{TIME_BOUND_REQUEST}` | 即応必須の依頼種別 | 経営会議準備 / 監査対応 |
| `{ORGANIZATION}` | 自組織名 | 自社名 / 個人事業 |

一括置換例:

```bash
sed -i '' 's/{KEY_KPI}/月次成約数/g' roles/*.md
sed -i '' 's/{KEY_STAKEHOLDER}/A 上司/g' roles/*.md
```

---

## ステップ 3: 記憶階層の初期化

`memory/` 配下の4ファイルは、**最初は雛形のまま**。
運用しながら追記していく。

### 最初に書くこと

`memory/decisions_ledger.md` の D-001 を、自組織の最初の決定で埋める。例:

```markdown
### D-001: メールトリアージを毎朝 7:00 に自動実行
- **source**: 議事録 meetings/2026-05-03.md / 議題2
- **date**: 2026-05-03
- **owner**: CAO + ユーザー（承認）
- **confidence**: high（過去 30 日の手動運用で精度確認済）
- **status**: 🟢 active
- **privacy_level**: internal
- **next_action**: cron 設定後 7 日間の精度モニタリング
```

---

## ステップ 4: 引用強要ルールの適用

`prompts/citation_enforcement.md` を読んで、ロールカード内の「引用強要ルール」セクションを自組織のパス・ファイル名に合わせて修正。

主な修正箇所:

- 引用元のパス（`meetings/` `data/` 等）を自リポ構造に合わせる
- 引用元の鮮度判定（7日 / 30日 / 90日）を業務サイクルに合わせて調整

---

## ステップ 5: (任意) Codex Review Gate の有効化

不可逆操作（メール送信・データ削除等）を扱う場合のみ。

### 5-1. workflow を配置

```bash
mkdir -p .github/workflows/
cp workflows/codex_review_gate.yml .github/workflows/
```

### 5-2. GitHub Secrets を設定

リポ Settings → Secrets and variables → Actions で以下を追加:

- `ANTHROPIC_API_KEY` — Claude API キー
- `OPENAI_API_KEY` — (任意) GPT-5 Pro 等を Phase 2 で使う場合

### 5-3. GitHub Environments を設定

Settings → Environments → New environment

- 名前: `production-gate`
- Required reviewers: 自分（または承認権限者）を追加

これで Phase 3（ユーザー承認）が必須化される。

### 5-4. 実装本体を追加

`workflows/codex_review_gate.yml` 内のコメントに従い、`scripts/gate_review.mjs` を実装（このリポでは未提供）。
Anthropic SDK / OpenAI SDK を使って各 Phase の判定ロジックを書く。

---

## ステップ 6: セッション起動時のルーチン化

Claude Code を起動したら、毎回以下の順で読み込む:

1. `memory/decisions_ledger.md`
2. `memory/recent_summary.md`
3. `memory/feedback_inbox.md`
4. `memory/field_handoff.md`
5. `prompts/citation_enforcement.md`
6. （議題に応じて）該当 CxO の `roles/*.md`

CLAUDE.md（自リポのプロジェクトルート）に上記読み込み順を明記すると、毎セッション自動化される。

---

## トラブルシューティング

### ロールカードが長すぎてトークンを圧迫する

- 各ロールカードの「§5 判断基準・原則」「§7 ユーザー確認領域」を、自組織用の最小版に縮める
- 全文 8000 トークン以内を目標にする（高橋運用での実測ベース）

### 議論が散る

- 5人全員が毎回発言する必要はない。議題に対する関連度マトリクス（CoS が判定）で High のみ発言にする
- 引用強要ルールを厳格に適用すると、的外れな発言が自然に減る

### Codex Gate が重い

- Phase 1（CxO レビュー）は並列化できる
- Phase 2（外部 reviewer）は緊急時のみ `bypass_external_reviewer=true` で省略可（事後に必ず後追い記録）
