# AIMOP - AI Mathematical Olympiad Progress Prize 3

コンペページ: https://www.kaggle.com/competitions/ai-mathematical-olympiad-progress-prize-3  
Kaggle Notebook: https://www.kaggle.com/code/shotokishida/aimop-baseline

---

## 開発フロー

| 作業 | 場所 |
|------|------|
| EDA・戦略立案・実装 | VSCode + Claude Code |
| 重い学習・推論 | Kaggle Notebook (GPU) |
| Submit | Kaggle ブラウザ（手動） |

`main/` を編集 → `main` にマージ → GitHub Actions が自動で Kaggle にデプロイ

---

## セットアップ（初回）

### 1. リポジトリをクローン

```bash
git clone <repo-url>
cd AIMOP
```

### 2. トークンを取得

**Kaggle API Token**
1. https://www.kaggle.com/settings → **API** → **Generate New Token**
2. 表示された `KGAT_...` の文字列をコピー

**GitHub Personal Access Token**
1. https://github.com/settings/tokens/new にアクセス
2. Scopes: `repo` ✓、`read:org` ✓、`workflow` ✓ を選択して生成
3. 表示された `ghp_...` の文字列をコピー

### 3. .env を作成してトークンを設定

```bash
cp .env.example .env
# .env を開いて KAGGLE_API_TOKEN と GH_TOKEN を入力
```

> Claude Code を使っている場合は `! cp .env.example .env` でターミナルを開かずに実行できる

### 4. セットアップスクリプトを実行

```bash
bash scripts/setup.sh
```

以下が自動で実行される:
- `uv sync` — 依存関係のインストール
- `gh secret set KAGGLE_API_TOKEN` — GitHub Secrets への登録
- Kaggle CLI の動作確認

---

## デプロイ方法

### ローカルから直接プッシュ

```bash
uv run kaggle-notebook-deploy push main
```

### GitHub Actions による自動デプロイ（推奨）

`main/` 配下を変更して `main` にマージすると自動デプロイされる。

```bash
git checkout -b feature/your-branch
# main/ を編集...
git add main/
git commit -m "feat: your changes"
git push origin feature/your-branch
# PR を作成して main にマージ → 自動デプロイ
```

手動トリガー（CLI）:

```bash
export $(cat .env | xargs)
gh workflow run kaggle-push.yml -f notebook_dir=src
```

デプロイ後は https://www.kaggle.com/code/shotokishida/aimop-baseline でノートブックを開き「Submit to Competition」を実行。

---

## ディレクトリ構成

```
AIMOP/
├── main/
│   ├── aimop-solver.ipynb      # メインノートブック（Kaggle にデプロイされる）
│   ├── kernel-metadata.json    # Kaggle Notebook の設定
│   └── _init_.py               # 共通ユーティリティ
├── data/                       # ローカルデータ（git 管理外）
├── .github/workflows/
│   └── kaggle-push.yml         # 自動デプロイワークフロー
├── scripts/
│   └── setup.sh                # 初回セットアップスクリプト
├── .env                        # トークン（git 管理外）
├── .env.example                # .env のテンプレート
└── pyproject.toml              # uv による依存関係管理
```
