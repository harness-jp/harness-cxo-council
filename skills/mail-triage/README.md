# Skill: Mail Triage

> A Claude Code skill for handling hundreds of corporate emails per day, where projects run in parallel and CC volume overwhelms manual processing.
>
> **大手企業の管理職向け**：1 日数百通のメール（案件並列・CC 大量）を、Claude Code で「案件単位の文脈」と「人物の関係性」から読ませて捌くスキル集。

[harness-cxo-council](https://github.com/harness-jp/harness-cxo-council) v2 として追加。[roles/cao.md](../../roles/cao.md)（Chief Automation Officer）の主担当「メール基盤運用」を実装する基礎ピース集。

---

## What's different（他のメールトリアージとの 6 つの違い）

メールを **1 通ずつ AI に投げる** のではなく、**案件のスレッドごとにまとめて読ませる** 設計。一般的な AI メール自動返信とのアプローチの違いは以下：

| # | Niche | 英語名 | 内容 |
|---|---|---|---|
| 1 | **案件単位の文脈遡り** | Account-context retrieval | 1 通単位じゃなく、案件スレッド全体を時系列で AI に渡す |
| 2 | **7 軸の人物把握** | 7-axis people graph | CC 関係者を Outbound / Inbound / Co-occurrence / Tag / Time / Thread / Account の 7 軸で集計 |
| 3 | **HTML 1 枚出力** | HTML one-pager | 全案件の状況と返信ドラフトを 1 ページに集約、ブックマーク 1 個で開く |
| 4 | **手動の学習ループ** | Manual learning loop | 自動学習を諦めて、構造バグは人手で skip ルールに反映 |
| 5 | **毎朝ローカルダンプ** | Morning local dump | 1 日 1 回 Mail API を叩いてローカルに全メール落とす（API コスト定額化） |
| 6 | **エンタープライズ規模前提** | Enterprise-scale | 1 日 100 件超の CC、案件並列 5 本以上が前提 |

→ 設計の経緯は **[note 記事「大手企業向け『AI でメール自動返信』が動かなかったので、毎朝ローカルに落として、案件ごとに読ませたら動いた話」](https://note.com/harness8888/n/n5bf73dc4426e)** を参照。

---

## What's in this repo（基礎ピース）

このリポは **基礎ピース** です。上記 6 つの組み合わせは、各環境で構築する前提。基礎ピースは以下：

| 仕組み | ファイル | 役割 |
|---|---|---|
| **skip_rules（3 層）** | [prompts/skip_rules.md](prompts/skip_rules.md) | 越境 / 沈黙 / 上から目線 を機械判定 |
| **8 PB 分類** | [prompts/triage_classify.md](prompts/triage_classify.md) | 8 つのメールパターン分類 |
| **採点ループ** | [examples/before_after.md](examples/before_after.md) | ▲△✗ 採点 → JSON 蓄積 → few-shot 注入 |
| **no_autosend 強制** | [prompts/triage_classify.md](prompts/triage_classify.md) | 重要書類は人間最終承認 |
| **PB 別返信ドラフト骨格** | [templates/reply_drafts.md](templates/reply_drafts.md) | 各 PB 用のドラフトテンプレ |

---

## Before / After（実測ベース）

| 観点 | Before | After |
|---|---|---|
| 所要時間 | 毎朝 200 件以上で 1 時間+ | トリガー 1 語で 10 分 |
| 重要メール見落とし | あり | 「⚡ VIP」最上段 surface |
| 返信したつもり放置 | 検知できない | 「⏰ 未返信追跡」必須出力 |
| **そのまま送れる率（ok 率）** | 計測不能 | **82%**（直近採点） |
| **skip 妥当率** | 不安定 | **100%**（5/5） |
| 構造バグ | 都度発生 | 採点で 3 つ検出 → skip_rules に人手反映済 |

詳細は [examples/before_after.md](examples/before_after.md) 参照。

---

## ディレクトリ構造

```
skills/mail-triage/
├── README.md                          このファイル
├── prompts/
│   ├── triage_classify.md             8 PB 分類プロンプト（汎化版・PRECEDENCE 含む）
│   └── skip_rules.md                  越境/沈黙/上から目線 3層判定（PRECEDENCE 含む）
├── templates/
│   └── reply_drafts.md                PB別返信ドラフト骨格
└── examples/
    ├── before_after.md                数字付き Before/After + 失敗事例
    └── corpus/                        匿名メールサンプル集（8 PB × 2件 = 16件）
        ├── README.md
        ├── P-01_new_inquiry_01.md / _02.md
        ├── P-03_handover_01.md / _02.md
        ├── P-04_site_visit_01.md / _02.md
        ├── P-05_scheduling_01.md / _02.md
        ├── P-08_important_doc_01.md / _02.md     (⚠️ no_autosend)
        ├── P-09_signature_01.md / _02.md         (⚠️ no_autosend)
        ├── P-13_termination_01.md / _02.md
        └── P-14_condition_change_01.md / _02.md  (⚠️ no_autosend)
```

各サンプルは「受信メール / 期待される処理（PB・信頼度・skip判定・PRECEDENCE）/ 期待される返信ドラフト / カスタマイズメモ」の4ブロック構成。**動作確認・採点ベースライン・カスタマイズの起点**として使う。

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

- **本スキルの記事（公開済）**: [大手企業向け『AI でメール自動返信』が動かなかったので、毎朝ローカルに落として、案件ごとに読ませたら動いた話](https://note.com/harness8888/n/n5bf73dc4426e)
- **設計の前提となる記事**: [「AI が勝手に学ぶ」を試したら学ばなかった。手動で組み直し→勝手に学習してくれた](https://note.com/harness8888/n/nb49931c893d3)
- 過去記事 第 1 弾: [メールトリアージ] Outlookメールを3分類でAI自動仕分け（2026-04-21 公開）の **発展版**
- すべての記事: [note.com/harness8888](https://note.com/harness8888)

---

## ライセンス

[harness-cxo-council](../../README.md) と同じ MIT License。
