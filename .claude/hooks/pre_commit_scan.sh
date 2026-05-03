#!/bin/bash
# harness-businesses 公開リポ用 機密情報スキャン
#
# 公開リポは特に厳密にチェックする。
# claude-strategy 由来の固有名詞・業界詳細が紛れ込んでいないか検出。
#
# 使い方:
#   bash .claude/hooks/pre_commit_scan.sh           # ステージ済みファイルをスキャン
#   bash .claude/hooks/pre_commit_scan.sh --all     # 全ファイルをスキャン

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

MODE="${1:-staged}"

echo "🔍 機密情報スキャン開始 (mode: $MODE)..."

if [ "$MODE" = "--all" ]; then
    target_files=$(find . -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -not -path "./.git/*" -not -path "./node_modules/*")
else
    target_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(md|txt|json|yaml|yml)$' || true)
fi

if [ -z "$target_files" ]; then
    echo "${GREEN}✓ 対象テキストファイルがありません${NC}"
    exit 0
fi

found_issues=0

# 公開リポ専用の禁止キーワード（claude-strategy 由来の固有名詞）
declare -a forbidden_keywords=(
    "iSpark"
    "ipark"
    "iPark"
    "化学合成系"
    "バイオ発酵系"
    "細胞再生医療系"
    "素材デバイス系"
    "食品農業バイオ系"
    "製薬支援系"
    "定借"
    "施設利用契約"
    "episodes/ipark"
    "ipark_omoshiro"
    "takahashi-1110"
)

# 一般的な機密パターン
declare -a patterns=(
    "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    "0[0-9]{1,4}-[0-9]{1,4}-[0-9]{4}"
    "0[0-9]{9,10}"
    "[0-9]+万円"
    "[0-9]+億円"
    "月額[0-9]"
    "年収[0-9]"
    "契約金額"
    "見積金額"
    "報酬額"
    "売上高"
    "[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}"
    "sk-[a-zA-Z0-9]{20,}"
    "AIza[a-zA-Z0-9_-]{30,}"
    "ghp_[a-zA-Z0-9]{30,}"
)

# 法人格
declare -a jp_keywords=(
    "株式会社"
    "有限会社"
    "合同会社"
)

# 許可リスト
allowlist="noreply|no-reply|@example\.|@users\.noreply\.github\.com|@anthropic\.com|note\.com/work8888"

# 1. 禁止キーワードチェック（最重要）
for file in $target_files; do
    for keyword in "${forbidden_keywords[@]}"; do
        matches=$(grep -nF "$keyword" "$file" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            if [ $found_issues -eq 0 ]; then
                echo ""
                echo "${RED}🚨 公開禁止キーワードを検出:${NC}"
                echo ""
            fi
            echo "${RED}[$file]${NC} 禁止: $keyword"
            echo "$matches" | head -3 | sed 's/^/    /'
            echo ""
            found_issues=$((found_issues + 1))
        fi
    done
done

# 2. 一般機密パターン
for file in $target_files; do
    for pattern in "${patterns[@]}"; do
        matches=$(grep -nE "$pattern" "$file" 2>/dev/null | grep -vE "$allowlist" || true)
        if [ -n "$matches" ]; then
            if [ $found_issues -eq 0 ]; then
                echo ""
                echo "${YELLOW}⚠️  機密情報パターンを検出:${NC}"
                echo ""
            fi
            echo "${YELLOW}[$file]${NC} パターン: $pattern"
            echo "$matches" | head -3 | sed 's/^/    /'
            echo ""
            found_issues=$((found_issues + 1))
        fi
    done
done

# 3. 法人格
for file in $target_files; do
    for keyword in "${jp_keywords[@]}"; do
        matches=$(grep -nF "$keyword" "$file" 2>/dev/null | head -3 || true)
        if [ -n "$matches" ]; then
            if [ $found_issues -eq 0 ]; then
                echo ""
                echo "${YELLOW}⚠️  法人格を検出（匿名化確認推奨）:${NC}"
                echo ""
            fi
            echo "${YELLOW}[$file]${NC} 法人格: $keyword"
            echo "$matches" | sed 's/^/    /'
            echo ""
            found_issues=$((found_issues + 1))
        fi
    done
done

if [ $found_issues -gt 0 ]; then
    echo ""
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${RED}検出: $found_issues 件 — 必ず修正してから commit してください${NC}"
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
else
    echo "${GREEN}✓ 機密情報は検出されませんでした${NC}"
    exit 0
fi
