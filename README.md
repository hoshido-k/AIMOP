# AIMOP - AI Mathematical Olympiad Progress Prize 3

コンペページ: https://www.kaggle.com/competitions/ai-mathematical-olympiad-progress-prize-3

---

## ノートブック一覧

| ノートブック | モデル | Kaggle URL | 自動デプロイ |
|-------------|--------|------------|-------------|
| `notebooks/gpt-oss-t0.5/` | GPT-OSS 120B (temperature 0.5) | https://www.kaggle.com/code/shotokishida/gpt-oss-120b-t0-5-structured-entropy | `notebooks/gpt-oss-t0.5/**` 変更時 |
| `notebooks/gpt-oss-t0.65/` | GPT-OSS 120B (temperature 0.65) | — | `notebooks/gpt-oss-t0.65/**` 変更時 |
| `notebooks/deepseek-r1-32b/` | DeepSeek-R1-Distill-Qwen-32B | https://www.kaggle.com/code/shotokishida/deepseek-r1-32b | `notebooks/deepseek-r1-32b/**` 変更時 |

---

## 推論戦略（deepseek-r1-32b）

2段階ゲート方式：

1. **Phase 1（高速スクリーニング）**: ANSWER_ONLY_PROMPT × 2、temperature=0.0
   - 2回一致 → 確定（Phase 2 スキップ）
   - 割れた → Phase 2 へ
2. **Phase 2（深掘り）**: 役割分担プロンプト × temperature 多様化（6 attempts 並列）
   - TIR_PROMPT (×2)、PURE_MATH_PROMPT (×2)、WORKING_BACKWARDS_PROMPT (×2)
   - 過半数一致で Early Stopping

答えの形式: **0〜99999 の整数**（100000 以上は mod 100000）

---

## 開発フロー

```
VSCode + Claude Code で実装
    ↓
git push origin main
    ↓
GitHub Actions が自動で kaggle kernels push
    ↓
Kaggle で Save Version → Submit to Competition
```

---

## セットアップ（初回）

### 1. リポジトリをクローン

```bash
git clone https://github.com/hoshido-k/AIMOP.git
cd AIMOP
```

### 2. Kaggle API Token を取得

1. https://www.kaggle.com/settings → **API** → **Create New Token**
2. `kaggle.json` を `~/.kaggle/kaggle.json` に配置（chmod 600）

### 3. GitHub Secrets に登録

```
https://github.com/hoshido-k/AIMOP/settings/secrets/actions
```

`KAGGLE_API_TOKEN` に `kaggle.json` の内容（JSON 文字列）を登録。

> **注意**: Kaggle API Token をコード内にハードコードしないこと。

---

## デプロイ方法

### 自動デプロイ（推奨）

各ノートブックディレクトリ配下を変更して `main` にプッシュすると自動デプロイされる。

```bash
git add notebooks/deepseek-r1-32b/
git commit -m "feat: your changes"
git push origin main
# → GitHub Actions が kaggle kernels push を実行
```

### 手動デプロイ

GitHub Actions タブ → 対象ワークフロー → **Run workflow**

または uv でローカル実行:

```bash
uv tool run kaggle kernels push -p notebooks/deepseek-r1-32b
```

---

## ディレクトリ構成

```
AIMOP/
├── notebooks/
│   ├── gpt-oss-t0.5/
│   │   ├── kernel-metadata.json
│   │   └── gpt-oss-120b-t0.5-structured-entropy.ipynb
│   ├── gpt-oss-t0.65/
│   │   ├── kernel-metadata.json
│   │   └── gpt-oss-120b-t0.65.ipynb
│   ├── deepseek-r1-32b/
│   │   ├── kernel-metadata.json
│   │   └── deepseek-r1-32b.ipynb
│   └── optuna/               # ハイパーパラメータ探索
├── utils/                    # 共通ユーティリティ
├── eval_output/              # 50problems 評価結果（git 管理外）
├── .github/workflows/
│   ├── kaggle-push-t0.5.yml
│   ├── kaggle-push-t0.65.yml
│   └── kaggle-push-deepseek-r1-32b.yml
└── pyproject.toml
```
