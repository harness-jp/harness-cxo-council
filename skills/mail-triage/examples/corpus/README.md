# Corpus — メールサンプル集

8 PB それぞれの**実物メールがどう見えるか**のサンプル集。
全て匿名化済（個人名・社名・金額・日付は架空のもの）。

---

## 何のために使うか

| 目的 | 使い方 |
|---|---|
| **理解** | 「P-01 ってどんなメール？」を実例で把握 |
| **動作確認** | 自前のスキル実装の入力テストデータとして使用 |
| **採点ベースライン** | これらに対して自分の skill が正しく分類するかを確認 |
| **カスタマイズ** | 自組織用にコピー → 業務固有の文面に書き換え |

---

## ファイル一覧（16件 = 8 PB × 2 例）

| PB | ファイル | 概要 |
|---|---|---|
| P-01 新規問合せ・初動対応 | [P-01_new_inquiry_01.md](P-01_new_inquiry_01.md) | 初コンタクト |
|  | [P-01_new_inquiry_02.md](P-01_new_inquiry_02.md) | 名刺交換後フォロー |
| P-03 担当者変更・引継ぎ | [P-03_handover_01.md](P-03_handover_01.md) | 異動引継ぎ |
|  | [P-03_handover_02.md](P-03_handover_02.md) | 退職挨拶 |
| P-04 現場確認・引渡し | [P-04_site_visit_01.md](P-04_site_visit_01.md) | 立会日程確定 |
|  | [P-04_site_visit_02.md](P-04_site_visit_02.md) | 検収依頼 |
| P-05 日程調整 | [P-05_scheduling_01.md](P-05_scheduling_01.md) | 候補日提示要請 |
|  | [P-05_scheduling_02.md](P-05_scheduling_02.md) | リスケ依頼 |
| P-08 重要書類送付 ⚠️ | [P-08_important_doc_01.md](P-08_important_doc_01.md) | 契約書ドラフト送付 |
|  | [P-08_important_doc_02.md](P-08_important_doc_02.md) | 見積書送付 |
| P-09 電子サイン・記録 ⚠️ | [P-09_signature_01.md](P-09_signature_01.md) | 押印依頼 |
|  | [P-09_signature_02.md](P-09_signature_02.md) | 議事録共有 |
| P-13 契約終了に伴う作業 | [P-13_termination_01.md](P-13_termination_01.md) | 解約通知 |
|  | [P-13_termination_02.md](P-13_termination_02.md) | 引き継ぎ清掃 |
| P-14 条件変更通知 ⚠️ | [P-14_condition_change_01.md](P-14_condition_change_01.md) | 単価変更 |
|  | [P-14_condition_change_02.md](P-14_condition_change_02.md) | 契約条件変更 |

⚠️ = no_autosend 強制（D-021）

---

## ファイル形式

各サンプルは以下の構造:

```markdown
# P-XX: タイトル — 例N

## 受信メール
件名 / From / 日時 / 本文

## 期待される処理
- PB: P-XX
- 信頼度: 0.XX
- 判定根拠
- skip判定: L1 / L2 / L3 の評価結果
- no_autosend: true/false

## 期待される返信ドラフト
（人間が削れば送れる素朴版）
```

---

## 匿名化ルール

| 項目 | 例 |
|---|---|
| 個人名 | 田中・佐藤・鈴木・山田 等の一般姓 + 一般名 |
| 社名 | ABC商事 / ○○ホールディングス / Acme Inc. 等の架空社名 |
| メールアドレス | name@example.com / @example.org / @example.net |
| 電話番号 | 03-XXXX-XXXX |
| 金額 | ¥XXX,XXX（具体額は出さない） |
| 住所 | 東京都○○区 等 |
| 日付 | 5/20 等の現年度内の架空日付 |

実在の組織・人物との一致は偶然です。
