# Skill: Mail Triage

> CAO ロールが主担当する「メール基盤運用」を実装する skill。
> 月数千件のメールを skip_rules 3層 → 8 PB 分類 → 採点ループ で回す。

---

## これは何

**1人で**毎朝の受信トレイ200件以上を処理してる人が、
**Claude Code に CAO 役として** メールを捌かせるためのテンプレート集。

このスキルは [harness-cxo-council](https://github.com/harness-jp/harness-cxo-council) の v2 として追加された。
[roles/cao.md](../../roles/cao.md)（Chief Automation Officer）の主担当領域「メール基盤運用」を実装する。

---

## Before / After（実測ベース）

| 観点 | Before | After |
|---|---|---|
| 所要時間 | 毎朝 200件以上の目視で1時間+ | トリガー1語で10分 |
| メール総量 | 月数千件規模 | 同じ |
| 重要メール見落とし | あり | 「⚡ VIP」最上段 surface |
| 返信したつもり放置 | 検知できない | 「⏰ 未返信追跡」必須出力 |
| **そのまま送れる率（ok率）** | 計測不能 | **82%**（直近採点） |
| **skip 妥当率** | 不安定 | **100%**（5/5 正解） |
| 構造バグ | 都度発生 | 採点で検出 → 3 つを skip_rules.mjs に反映済 |

詳細は [examples/before_after.md](examples/before_after.md) 参照。

---

## 中心の3つ

| 仕組み | ファイル | 役割 |
|---|---|---|
| **skip_rules 3層** | [prompts/skip_rules.md](prompts/skip_rules.md) | 越境 / 沈黙 / 上から目線 を機械判定 |
| **採点ループ** | [examples/before_after.md](examples/before_after.md) の採点フロー | 人手 ▲△✗ → JSON蓄積 → few-shot 注入 |
| **no_autosend 強制** | [prompts/triage_classify.md](prompts/triage_classify.md) の D-021 | 重要書類・電子サイン・条件変更 は人間最終承認 |

---

## ディレクトリ構造

```
skills/mail-triage/
├── README.md                          このファイル
├── prompts/
│   ├── triage_classify.md             8 PB 分類プロンプト（汎化版）
│   └── skip_rules.md                  越境/沈黙/上から目線 3層判定
├── templates/
│   └── reply_drafts.md                PB別返信ドラフト骨格
└── examples/
    └── before_after.md                数字付き Before/After + 失敗事例
```

---

## クイックスタート

### 1. Mail MCP を準備

Microsoft 365 / Gmail / 同等の MCP が必要。
詳細手順はリポ内別 docs ではなく、各 MCP の公式 README を参照。

### 2. PB 分類プロンプトを Claude Code に配置

```bash
cp skills/mail-triage/prompts/triage_classify.md ~/.claude/commands/mail_triage.md
```

または `~/.claude/agents/mail-triage.md` に配置。

### 3. skip_rules を実装に組み込む

[prompts/skip_rules.md](prompts/skip_rules.md) のロジックを参考に、自分の言語（Python / Node / TypeScript）で実装。
LLM 判定**前**の事前フィルタとして動かす。

### 4. テンプレを自組織用にカスタマイズ

[templates/reply_drafts.md](templates/reply_drafts.md) の `{}` 置換ポイントを自組織の文脈に置換。

### 5. 採点 UI を立ち上げ

`scoring_ui.html` 相当を自分で書く（このリポでは雛形なし）。
要件: ▲ / △ / ✗ ボタンと、JSON 出力（クリップボードコピー or ファイル保存）。

### 6. 採点 JSON を few-shot に注入

PB 別 baseline JSON を集めて、次の draft 生成プロンプトに「過去の ▲ 例 N件 + ✗ 修正例」を注入する仕組みを実装。

---

## カスタマイズポイント

| 箇所 | カスタマイズ内容 |
|---|---|
| [prompts/skip_rules.md](prompts/skip_rules.md) の COLLABORATORS | 自組織の協働者リスト（外部化推奨・D-026） |
| [prompts/skip_rules.md](prompts/skip_rules.md) の沈黙閾値 | 業務スタイルに合わせて 60〜120字 |
| [prompts/triage_classify.md](prompts/triage_classify.md) の8 PB | 自組織の業務カテゴリで増減 |
| [prompts/triage_classify.md](prompts/triage_classify.md) の no_autosend 対象 | リスクの高い PB を `true` に |
| [templates/reply_drafts.md](templates/reply_drafts.md) の置換変数 | 自組織で頻出する変数を追加 |
| [templates/reply_drafts.md](templates/reply_drafts.md) の共通スタイル | 業界文化（より丁寧 / よりカジュアル）に合わせる |

---

## 既存リポ要素との接続

| 既存要素 | 接続点 |
|---|---|
| [roles/cao.md](../../roles/cao.md) | CAO の「メール基盤運用」を**実装する** skill |
| [prompts/citation_enforcement.md](../../prompts/citation_enforcement.md) | draft 生成時に**過去類似メール**を引用させる原則 |
| [memory/decisions_ledger.md](../../memory/decisions_ledger.md) | D-019/D-020/D-021/D-026 を引用元として記録 |
| [workflows/codex_review_gate.yml](../../workflows/codex_review_gate.yml) | `mail_send` 操作タイプは P-08/P-09/P-14 で必ず通す |

---

## やってないこと（あえて）

ユーザー個人の好みを**自動学習**する AI ループは入れていない。

| 入れたもの | 入れてないもの |
|---|---|
| ✅ 採点結果を JSON に蓄積 | ❌ プロンプト再注入の自動パイプライン |
| ✅ few-shot に過去の ▲ 例を注入 | ❌ ユーザー編集差分の自動学習 |
| ✅ 構造バグを skip_rules に**人手**で反映 | ❌ モデル fine-tune |

理由:
1. **「人手で削れば OK ベース」**の運用が現実解（人間が追加するより削る方が安全）
2. リポ全体の「**学習を諦めて引用を強要する**」哲学と整合（[harness-cxo-council README](../../README.md) 参照）
3. 自動学習ループは過去に試して諦めた経緯あり（記事第1弾の核ストーリー）

詳細な議論は [examples/before_after.md](examples/before_after.md) の「やってないこと」セクション参照。

---

## 関連記事

このスキルの**設計の経緯**は note 記事を参照:

- 記事: [note.com/harness8888](https://note.com/harness8888)
- このスキルが対応する記事: 「メールトリアージを CAO に任せたら〜」（執筆中・公開後リンク追記）
- 過去記事 第1弾「[メールトリアージ] Outlookメールを3分類でAI自動仕分け」(2026-04-21公開) の **発展版**

---

## ライセンス

[harness-cxo-council](../../README.md) と同じ MIT License。
