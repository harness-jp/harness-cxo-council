# Triage Classify — 採配（PB）分類プロンプト

> 受信メールを「業務パターン（PB = Pattern Bucket）」に分類するプロンプト。
> 各 PB ごとに skip 判定 / draft テンプレ / 検証フロー が紐づく。

---

## 設計の起源

メールは100種類あるように見えて、現場では8〜20種類のパターンに収束する。
「**新規問合せ**」「**日程調整**」「**重要書類送付**」のように。
パターンごとに**スキップ判定もドラフト型も違う**ので、最初に分類するのが効率的。

LLM に毎回ゼロから判定させると揺れる。
**件名・送信者ベースのルール駆動**を主軸に、ルールで決まらないものだけ LLM フォールバック。

---

## 8 PB（最小実用版）

汎化版。自組織で必要な PB を追加・削除する。

| ID | 名前 | 概要 |
|---|---|---|
| **P-01** | 新規問合せ・初動対応 | 外部からの初コンタクト・問合せフォーム経由・名刺交換後の連絡 |
| **P-03** | 担当者変更・引継ぎ | 人事異動・後任引き継ぎ・退職挨拶 |
| **P-04** | 現場確認・引渡し | 立会・検収・現地調査・物品受渡し |
| **P-05** | 日程調整 | MTG設定・候補日提示・リスケ依頼 |
| **P-08** | 重要書類送付 | 契約書・覚書・見積書・提案書のドラフト送付 |
| **P-09** | 電子サイン・記録 | 押印依頼・電子契約・議事録共有 |
| **P-13** | 契約終了に伴う作業 | 解約・退去・引き継ぎ清掃・原状回復 |
| **P-14** | 条件変更通知 | 単価変更・面積/規模変更・契約条件変更 |

> **欠番（P-02, P-06, P-07, P-10〜P-12, P-15〜P-20）**: 必要に応じて自組織で追加。
> 8 PB MVP として運用開始 → 半年で見えるパターンを追加していく順序を推奨。

---

## 分類ロジック

### Step 1: 件名パターンで一次判定（速い）

```python
subject_rules = {
    "P-01": [r"問合せ", r"お問い合わせ", r"初めまして", r"先日は名刺"],
    "P-03": [r"担当変更", r"後任", r"異動", r"退職"],
    "P-04": [r"立会", r"検収", r"現地", r"内覧"],
    "P-05": [r"日程", r"候補日", r"スケジュール", r"リスケ"],
    "P-08": [r"契約書", r"覚書", r"見積", r"提案書"],
    "P-09": [r"押印", r"電子サイン", r"議事録"],
    "P-13": [r"解約", r"退去", r"原状回復", r"清掃"],
    "P-14": [r"単価変更", r"面積変更", r"条件変更"],
}

for pb, patterns in subject_rules.items():
    if any(re.search(p, email.subject) for p in patterns):
        return pb
```

### Step 2: 送信者パターンで補強

```python
sender_rules = {
    "P-01": ["@form.example.com", "noreply@inquiry"],  # 問合せフォーム経由
    "P-09": ["@docusign", "@cloudsign"],                # 電子契約サービス
    # ... 自組織で定義
}
```

### Step 3: ルールで決まらない場合 LLM フォールバック

```
受信メールの件名・本文・送信者を提示。
以下のうちどの PB に該当するか判定してください。
複数該当する場合は、最も関連の強いもの1つを選んでください。

PB 一覧:
{ここに上の8 PB の概要を貼る}

該当なしの場合は "P-00" (未分類) を返してください。
```

LLM は Sonnet で十分（速度重視）。
信頼度が低い場合（confidence < 0.7）は Opus に再判定。

---

## 各 PB に紐づく処理

各 PB に以下を定義しておくと、分類後の処理が自動化できる。

```yaml
# 例: P-01 の定義
P-01:
  name: 新規問合せ・初動対応
  skip_rules:
    - L1_overreach: true       # 越境チェックする
    - L2_silence: true         # 沈黙チェックする
    - L3_condescension: true   # 上から目線チェックする
  draft_template: templates/reply_drafts.md#P-01
  validation:
    - check_signature: true
    - check_industry_terms: true
  no_autosend: false           # ドラフト止まり or 自動送信可
```

```yaml
# 例: P-08 の定義（重要書類）
P-08:
  name: 重要書類送付
  skip_rules:
    - L1_overreach: true
    - L2_silence: false        # 既決着でも要確認
    - L3_condescension: true
  draft_template: templates/reply_drafts.md#P-08
  validation:
    - check_attachment: true
    - check_amount_disclosure: true
  no_autosend: true            # ⚠️ D-021 強制ドラフト止まり
```

`no_autosend: true` の PB は、Codex Review Gate（[workflows/codex_review_gate.yml](../../../workflows/codex_review_gate.yml)）の `mail_send` 操作タイプを必ず通す。

---

## D-021 反映: no_autosend 強制 PB

以下の PB は**絶対に自動送信しない**。ドラフト止まり + 人間最終承認が必須:

- P-08: 重要書類送付（誤送信1件で重大リスク）
- P-09: 電子サイン・記録（証跡が残る・後戻り不可）
- P-14: 条件変更通知（金額・契約条件含む）

これは [workflows/codex_review_gate.yml](../../../workflows/codex_review_gate.yml) で強制される設計。

---

## PRECEDENCE（複数該当時の優先順位）

1通のメールが複数の PB に該当する場合（例: 「契約書を交わしたいので5/20か5/22で」= P-08 + P-05）、
**リスクの高い方を優先**する。AI の判断ブレを抑え、no_autosend が必要なメールが取りこぼされない。

```
P-08 (重要書類送付)
  > P-09 (電子サイン・記録)
  > P-14 (条件変更通知)
  > P-04 (現場確認・引渡し)
  > P-05 (日程調整)
  > P-13 (契約終了に伴う作業)
  > P-03 (担当者変更・引継ぎ)
  > P-01 (新規問合せ・初動対応)
```

### 適用ルール

1. ルール駆動分類（subject_rules / sender_rules）で**最も上位の PB が一致した時点で確定**
2. 複数該当時、`PRECEDENCE` 配列の**早い方**を採用
3. LLM フォールバック時も、プロンプトに PRECEDENCE を明示して同じ順で判定させる

### なぜこの順か

| 並び | 理由 |
|---|---|
| P-08 / P-09 / P-14 が最上位 | 全て **no_autosend 強制**（D-021）。誤分類による自動送信事故を防ぐ最優先 |
| P-04 (現場) | 物理的な期日を含むケースが多い（取り違えると当日トラブル） |
| P-05 (日程) | 期日があるが、誤分類しても再調整可能 |
| P-13 / P-03 / P-01 | 比較的後戻り可能なやり取り |

### 例

```
受信: 「来週の打ち合わせで契約書を交わしたいので、5/20か5/22のどちらでご都合いかがでしょうか」
```

このメールは:
- 件名キーワード「契約書」 → **P-08 候補**
- 本文キーワード「5/20か5/22」「ご都合」 → **P-05 候補**

PRECEDENCE で **P-08 > P-05** なので **P-08 と判定**。
→ no_autosend が強制され、Codex Gate を通過した上で人間最終承認に回る。
→ P-05 と誤分類されて自動送信される事故を防ぐ。

### LLM フォールバックプロンプトへの組込み

```
受信メールが複数の PB に該当する場合、以下の優先順位で1つを選んでください:
P-08 > P-09 > P-14 > P-04 > P-05 > P-13 > P-03 > P-01

理由: P-08/P-09/P-14 は誤送信リスクが高いため、最優先で識別する。
```

---

## 出力フォーマット

```json
{
  "pb": "P-05",
  "confidence": 0.92,
  "method": "subject_rule",
  "matched_pattern": "日程",
  "next_action": {
    "skip_rules": ["L1", "L2", "L3"],
    "draft_template": "templates/reply_drafts.md#P-05",
    "no_autosend": false
  }
}
```

`method` は `subject_rule` / `sender_rule` / `llm_fallback` のいずれか。
`llm_fallback` で confidence < 0.7 のものは人間判断キューへ。

---

## カスタマイズポイント

| 箇所 | 何を書き換えるか |
|---|---|
| 8 PB の name / 概要 | 自組織の業務語彙に置換（例: 「立会」→「現地視察」） |
| subject_rules / sender_rules | 自組織でよく見る件名・送信者のパターンを追加 |
| no_autosend 対象 PB | リスクの高い業務カテゴリを `true` に |
| LLM フォールバックのモデル | コスト要件で Sonnet/Haiku/Opus を選択 |

---

## 引用強要との関係

このプロンプト自体は分類なので引用は不要。
ただし**分類結果を使う後段（draft生成・skip判定）では `prompts/citation_enforcement.md` のルールが適用される**。
- 「過去の P-05 メールではこう返してた」を引用する
- 「D-021 で no_autosend が強制された」を引用する

---

## 引用元

- `lib/pb_classifier.mjs` の8PB ルール定義（実装は本番運用中）
- D-021（no_autosend 強制・契約系）が設計根拠
- このスキルは [roles/cao.md](../../../roles/cao.md) の「メール基盤運用」を実装
