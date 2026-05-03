# 決定事項 生きた台帳 (Decisions Ledger)

> CxO 役員会議の全決定事項を ID 付きで管理。撤回履歴も保持。
> 起動時に必ず全文読込される（永続 SoT）。
>
> **メタデータ標準（全 D-XXX 必須）:**
> source / date / owner / confidence / status / privacy_level / next_action

---

## このファイルの使い方

- 各決定に `D-001` 〜 連番で ID を振る
- メタデータ7項目を必須とする（欠けた決定は議事録に差し戻し）
- 「アクティブな決定」と「撤回・終了した決定」をセクション分割
- 撤回時は **元の決定を消さず**、撤回理由を追記して移動

---

## アクティブな決定

<!--
ここに以下のフォーマットで決定を追記:

### D-001: 決定のタイトル（一行）
- **source**: 議事録ファイルパス（例: meetings/2026-05-03_0900.md / 議題X）
- **date**: 2026-05-03
- **owner**: CTO + CAO + ユーザー（承認）
- **confidence**: high（実証データあり） / medium（仮説） / low（未検証）
- **status**: 🟢 active
- **privacy_level**: internal / public / restricted
- **next_action**: 次のアクション（誰が・いつまでに・何を）
- 内容:
  - 決定の要約3-5行
- 進捗: （任意・週次更新）

-->

### D-001: （ここに最初の決定を書く）
- **source**: （議事録パス）
- **date**: YYYY-MM-DD
- **owner**: （担当CxO + 承認者）
- **confidence**: （high/medium/low + 理由）
- **status**: 🟢 active
- **privacy_level**: internal
- **next_action**: （次のアクション）
- 内容: （決定の要約）

---

## 撤回・終了した決定

<!--
撤回時は status を 🔴 retired に変更し、撤回理由を追記:

### D-XXX (撤回): 元のタイトル
- **status**: 🔴 retired
- **retired_at**: YYYY-MM-DD
- **retired_reason**: 撤回理由（次の決定 D-YYY で代替された等）
- ... (元のメタデータは保持)
-->

（撤回された決定をここに移動）

---

## 凡例

| status | 意味 |
|---|---|
| 🟢 active | 現在有効 |
| 🟡 pending | 保留中（追加情報待ち） |
| 🔴 retired | 撤回済み |
| ⚪ done | 完了 |

| confidence | 意味 |
|---|---|
| high | 実証データ・実装稼働中 |
| medium | 仮説段階・部分検証 |
| low | 未検証・推論ベース |

| privacy_level | 意味 |
|---|---|
| public | 外部公開可 |
| internal | 組織内限定 |
| restricted | 役員のみ |
