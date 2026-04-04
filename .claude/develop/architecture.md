# AIMOP プロジェクト アーキテクチャ

コンペ: [AI Mathematical Olympiad Progress Prize 3](https://www.kaggle.com/competitions/ai-mathematical-olympiad-progress-prize-3)

---

## 全体フロー

```
VSCode + Claude Code          GitHub                  Kaggle
─────────────────────         ──────────              ─────────────────────
main/ を編集
    │
    └─ git push main ────────► kaggle-push.yml ──────► Kernel Push (API)
                                (GitHub Actions)            │
                                                            ▼
                                                       aimop-solve Notebook
                                                       (H100 GPU で実行)
                                                            │
                                                            ▼
                                                       Submit to Competition
                                                       （ブラウザで手動）
```

---

## ディレクトリ構成

```
AIMOP/
├── main/
│   ├── aimop-solver.ipynb       # Kaggle にデプロイされるメインノートブック
│   └── kernel-metadata.json     # Kaggle Kernel の設定（GPU・データソース等）
├── data/                        # ローカルデータ（.gitignore 対象）
│   ├── 50problems/              # 参考問題集
│   ├── reference.csv
│   ├── test.csv
│   └── sample_submission.csv
├── scripts/
│   └── setup.sh                 # 初回セットアップ（uv sync + GitHub Secret 登録）
├── .github/workflows/
│   └── kaggle-push.yml          # main/ 変更時に自動デプロイ
├── .claude/
│   ├── commands/                # Claude Code カスタムコマンド
│   │   └── kaggle-setup.md      # /kaggle-setup コマンド定義
│   └── develop/
│       ├── architecture.md      # このファイル
│       └── tips.md              # Kaggle CLI / Colab 操作 Tips
├── pyproject.toml               # uv による依存関係管理
├── uv.lock
├── .env                         # API トークン（git 管理外）
└── .env.example
```

---

## コンポーネント詳細

### Kaggle Kernel (`main/kernel-metadata.json`)

| 設定 | 値 |
|------|----|
| Kernel ID | `shotokishida/aimop-solve` |
| GPU | H100 (`NvidiaH100`) |
| Internet | 無効（コンペ規則） |
| データセット | `amanatar/50problems` |
| コンペデータ | `ai-mathematical-olympiad-progress-prize-3` |
| カーネル依存 | `andreasbis/aimo-3-utils` |
| モデル | `danielhanchen/gpt-oss-120b`（Transformers） |

### Python 環境 (ローカル)

- **パッケージマネージャ**: `uv`
- **Python バージョン**: >=3.11
- **主な依存**: `kaggle`, `kaggle-notebook-deploy`, `pandas`, `numpy`, `jupyterlab`
- コマンド実行時は `uv run <cmd>` を使う（`python` / `pip` 直打ち禁止）

### デプロイ (`kaggle-push.yml`)

- トリガー: `main` ブランチへの push（`main/**` 変更時）または手動
- 処理: `kaggle kernels push -p main`
- 認証: GitHub Secret `KAGGLE_API_TOKEN` を環境変数として渡す

---

## 開発ルール

| 作業 | 場所 |
|------|------|
| EDA・実装・デバッグ | VSCode ローカル |
| 重い推論・学習 | Kaggle Notebook (H100) |
| デプロイ | `main` マージ → GitHub Actions 自動 |
| サブミット | Kaggle ブラウザ（手動） |

- ローカルの Python 環境は `uv run` 経由で実行
- Kaggle Notebook 上のパッケージはノートブック内で `!pip install` する（ローカルとは別環境）
- `data/` はローカル専用（Kaggle 上のデータは kernel-metadata.json で管理）
