# harness-cxo-council

> **「AI が勝手に学ぶ」を試したら学ばなかったので、手で組み直したら、勝手に学習してくれた話のテンプレート集。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## これは何

業界発表「AI が自動で学ぶ」「ハーネス組めば学習が定着する」を信じて試した結果、**勝手には学んでくれませんでした**。

そこで、**手で学習ループを組み直したら、不思議なことに、勝手に学習してくれるようになりました**。設計はこうです：

- **引用を強要する**（議論で毎回3つ以上の具体的な引用を要求） → [`prompts/citation_enforcement.md`](prompts/citation_enforcement.md)
- **3層メモリで議論の蓄積を残す**（永続/状態/会話） → [`memory/`](memory/)
- **撤回履歴を保持する**(過去の決定を消さず、`🔴 retired` で残す)
- **8人いた AI 役員会を 5人に削る**（CoS / CAO / CFO / CTO / COO 固定） → [`roles/`](roles/)
- **GPT-5.5 Pro を「評価役」から「プレイヤー」に格下げ**して中に入れる
- **不可逆操作は二段階審査**（誤送信を物理的に止める） → [`workflows/codex_review_gate.yml`](workflows/codex_review_gate.yml)

この **3層メモリ + 引用強要 + 撤回履歴** の組み合わせが、結果として **勝手に学習する仕組み** になっています。

note 記事「**[「AI が勝手に学ぶ」を試したら学ばなかったので、手で組み直したら、勝手に学習してくれた話](https://note.com/harness8888)**」の実装版です。

### 中心思想3つ

| 思想 | 中身 |
|---|---|
| **「自動学習」を諦めて、手で学習ループを組み直す** | AI に「自動で学ばせる」のは諦め、引用強要 + 3層メモリ + 撤回履歴で**手動で学習ループを設計**する（→ [prompts/citation_enforcement.md](prompts/citation_enforcement.md)） |
| **人間の記憶モデルを真似る** | ワーキングメモリ / 長期記憶 / エピソード記憶 の3階層に分けてメモリ管理（→ [memory/](memory/)） |
| **5人固定 + 外部推論をプレイヤーに格下げ** | CoS/CAO/CFO/CTO/COO の5人を固定。GPT-5.5 Pro 等を評価役じゃなくプレイヤーとして中に入れる |

### 既存の AI エージェント集との違い

| 観点 | 一般的な人格カタログ | このリポ |
|---|---|---|
| 提供物 | 役職別の人格テンプレ | **役員会の運用設計**（ロール×記憶×引用×ゲート） |
| 数字裏付け | 抽象指標 | **削減時間・コスト等を実測ベースで** |
| 失敗事例 | ほぼ無し | **落とし穴を必ず添える** |
| 不可逆操作の扱い | 未対応 | **Codex Review Gate で二段階審査** |

---

## 5人の役員

| 役職 | フルネーム | 主担当 |
|---|---|---|
| **CoS** | Chief of Staff | 司会・横断視点・優先順位再調整・KPI 追跡 |
| **CAO** | Chief Automation Officer | 業務自動化・メール基盤・ダッシュボード設計 |
| **CFO** | Chief Financial Officer | 契約・経理・コンプライアンス |
| **CTO** | Chief Technology Officer | AI 推進・技術設計・**Codex Review Gate 主管** |
| **COO** | Chief Operating Officer | CRM 基盤・運用設計・移管 PM |

各ロールカードは [roles/](roles/) に配置。**自組織の文脈に合わせてカスタマイズして使う**前提のテンプレート。

---

## クイックスタート

### 1. クローン

```bash
git clone https://github.com/harness-jp/harness-cxo-council.git
cd harness-cxo-council
```

### 2. ロールカードを自組織用にカスタマイズ

`roles/*.md` の `{}` で囲まれた箇所を自組織の文脈に置換。

```bash
# 例: 自組織の KPI 名で置換
sed -i '' 's/{KEY_KPI}/月次成約数/g' roles/cos.md
```

### 3. 記憶階層を初期化

`memory/` 配下の4つの雛形を初期化:

- `decisions_ledger.md` — D-001 から決定を貯めていく永続層
- `recent_summary.md` — 直近7日のサマリ（状態層）
- `feedback_inbox.md` — 未処理フィードバック（会話層）
- `field_handoff.md` — セッション間引き継ぎ

### 4. 引用強要ルールを読む

`prompts/citation_enforcement.md` を読んで、議論で引用を要求する習慣を確立。

### 5. (任意) Codex Review Gate を有効化

`workflows/codex_review_gate.yml` を `.github/workflows/` 直下に配置。
不可逆操作（メール送信・データ削除等）を実行する前に三層審査を通す。

---

## ディレクトリ構造

```
harness-cxo-council/
├── README.md
├── LICENSE                          (MIT)
├── roles/                           5人のロールカード
│   ├── cos.md
│   ├── cao.md
│   ├── cfo.md
│   ├── cto.md
│   └── coo.md
├── memory/                          3層メモリ雛形
│   ├── decisions_ledger.md          (永続層)
│   ├── recent_summary.md            (状態層)
│   ├── feedback_inbox.md            (会話層)
│   └── field_handoff.md             (会話層・セッション間)
├── prompts/
│   └── citation_enforcement.md      引用強要ルール
├── workflows/
│   └── codex_review_gate.yml        不可逆操作の二段階ゲート
├── scripts/                         実装本体（雛形・利用者側で拡充）
└── docs/
    ├── installation.md
    └── contribution.md
```

---

## 思想の解説（note 記事との対応）

各セクションの**設計の経緯**は note 記事を参照:

| 記事 H2 | このリポの該当箇所 |
|---|---|
| 【観察】8人で議論させたら、決断できなくなった | 5人固定の根拠（→ `roles/`） |
| 【違和感】GPT-5.5 Pro に「お前は実装屋になってる」と言われた朝 | 外部 reviewer の必要性（→ `workflows/codex_review_gate.yml` Phase 2） |
| 【だから作った①】学習を諦めて、引用を強要した | `prompts/citation_enforcement.md` |
| 【だから作った②】人間の記憶みたいに AI のメモリを作った | `memory/` の3階層構造 |
| 【渾身の一撃】8人を 5人に削って、GPT-5.5 Pro をプレイヤーに混ぜた | `roles/` 5人 + Phase 2 で外部推論をプレイヤー化 |
| 【何が変わったか】4つの実証 | （実測値は記事側） |
| 【事実比較】Anthropic 公式の Agent Stack と並べてみる | （比較は記事側） |
| 【最後に】何にでも応用できるフォーマット | このリポ構造そのもの |

---

## カスタマイズポイント

| 箇所 | カスタマイズ内容 |
|---|---|
| `roles/*.md` の `{KEY_KPI}` 等 | 自組織の北極星 KPI 名・ステークホルダー・優先順位 |
| `memory/decisions_ledger.md` D-001 | 自社の最初の決定を D-001 として書き始める |
| `prompts/citation_enforcement.md` | 引用元のパス（`meetings/` `data/` 等）を自リポ構造に合わせる |
| `workflows/codex_review_gate.yml` | `operation_type` の選択肢を自業務に合わせて拡張 |

---

## 注意

### 元素材について

このリポは、N=1（運営者1人）の業務運用ハーネスを**汎化したテンプレート**です。
特定の業界・組織に依存する記述は全て削除・汎化済み。**MIT ライセンスで自由に改変可**。

### サポート方針

- **言語**: 日本語のみで対応（英語 issue/PR は基本的に対応しません）
- **応答速度**: 個人運営のため、返信が遅い場合あり（数日〜1週間）
- **想定読者**: Claude Code 本格運用者・マルチエージェント設計を試行錯誤中の方

### 責任範囲

このリポはあくまで**設計テンプレート**です。
**Codex Review Gate を含む全ての機構は、利用者の責任で動作確認・カスタマイズの上で運用してください**。
特に不可逆操作（メール送信・データ削除・本番更新）は、Gate を通したあとも**最終判断は人間**で行ってください。

---

## ライセンス

MIT License — 詳細は [LICENSE](LICENSE) 参照。

---

## 関連リンク

- **記事**: [note.com/harness8888](https://note.com/harness8888) — 設計の経緯と実証
- **X**: [@SG8E5oIXpe3OteQ](https://x.com/SG8E5oIXpe3OteQ) — 高橋祐太｜AIより「人」（運営者）

---

## 改訂履歴

| 日付 | 内容 |
|---|---|
| 2026-05-03 | 初版公開（v1: Council kernel のみ） |
