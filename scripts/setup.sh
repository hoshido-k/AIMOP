#!/usr/bin/env bash
# 初回セットアップスクリプト
# Usage: bash scripts/setup.sh
set -euo pipefail

echo "=== AIMOP Setup ==="

# .env チェック
if [ ! -f .env ]; then
    cp .env.example .env
    echo "[!] .env を作成しました。KAGGLE_API_TOKEN と GH_TOKEN を入力してください。"
    echo "    編集後、再度このスクリプトを実行してください。"
    exit 0
fi

# .env 読み込み
export $(grep -v '^#' .env | xargs)

# トークン未設定チェック
if [ -z "${KAGGLE_API_TOKEN:-}" ] || [ -z "${GH_TOKEN:-}" ]; then
    echo "[!] .env に KAGGLE_API_TOKEN と GH_TOKEN を設定してください。"
    exit 1
fi

# uv sync
echo "[1/3] Installing dependencies..."
uv sync

# GitHub Secret 登録
echo "[2/3] Registering KAGGLE_API_TOKEN to GitHub Secrets..."
gh secret set KAGGLE_API_TOKEN --body "$KAGGLE_API_TOKEN"

# 動作確認
echo "[3/3] Verifying Kaggle CLI..."
uv run kaggle competitions list --search "mathematical" 2>/dev/null | head -3

echo ""
echo "=== Setup complete! ==="
echo "デプロイ: uv run kaggle-notebook-deploy push src"
