---
name: colab-adapt
description: Add Kaggle/Colab/local environment branching to a notebook copied from Kaggle. Use when you have a Kaggle notebook that needs to run on Colab or locally — inserts ENV detection cell, converts /kaggle/input/ paths, adds data download commands.
argument-hint: <notebook-path>
disable-model-invocation: true
---

Kaggle からコピーしてきたノートブックに、Kaggle / Colab / ローカル 環境を自動判定する分岐コードを追加する。
パス変換・セットアップセル挿入・パッケージインストールまで一括対応。

## 使い方

```
/colab-adapt <notebook-path>
```

例:
```
/colab-adapt notebooks/my-solver/my-solver.ipynb
/colab-adapt main/aimop-solver.ipynb
```

`<notebook-path>` は `.ipynb` ファイルへのリポジトリルートからの相対パス。

---

## 手順

以下を順番に実行すること。

---

### Step 1: ノートブックと kernel-metadata.json の読み込み

```bash
# ノートブックを確認
cat <notebook-path>

# 同ディレクトリの kernel-metadata.json を確認（存在する場合）
cat <notebook-path のディレクトリ>/kernel-metadata.json
```

`kernel-metadata.json` から以下を記録する（存在しない場合は空リスト扱い）：
- `competition_sources`: コンペスラッグのリスト
- `dataset_sources`: データセットスラッグのリスト
- `kernel_sources`: カーネル依存のリスト
- `model_sources`: モデルスラッグのリスト

---

### Step 2: ノートブック内のパス・環境依存箇所の調査

ノートブックの全セルを確認し、以下を洗い出す：

1. **`/kaggle/input/...` パス** — 環境判定コードへの置き換え対象
2. **`/kaggle/working/` パス** — 出力パスの置き換え対象
3. **`import google.colab`** — すでに分岐実装済みかの確認
4. **pip/conda インストールセル** — Kaggle 側で省略されているインストールの確認
5. **Kaggle Secrets 利用** (`UserSecretsClient`) — Colab Secrets への変換対象

調査結果をユーザーに報告してから次のステップに進む。

---

### Step 3: セットアップセル（先頭）の挿入

ノートブックの **最初のセル**（またはENV設定セルの直後）に以下のセルを挿入する。
`kernel-metadata.json` の内容をもとに、実際のスラッグ・パッケージ名を埋めること。

```python
# ===== 環境セットアップ（Kaggle では自動スキップ） =====
import os, sys

def _is_kaggle():
    return os.path.exists("/kaggle/input")

def _is_colab():
    try:
        import google.colab  # noqa: F401
        return True
    except ImportError:
        return False

ENV = "kaggle" if _is_kaggle() else "colab" if _is_colab() else "local"
print(f"[env] running on: {ENV}")

if ENV == "colab":
    # ---------- Kaggle API 認証 ----------
    from google.colab import userdata
    os.makedirs(os.path.expanduser("~/.kaggle"), exist_ok=True)
    import json
    kaggle_token = userdata.get("KAGGLE_API_TOKEN")  # Colab Secrets に登録しておく
    # KAGGLE_API_TOKEN の形式: {"username":"xxx","key":"yyy"}
    with open(os.path.expanduser("~/.kaggle/kaggle.json"), "w") as f:
        f.write(kaggle_token)
    os.chmod(os.path.expanduser("~/.kaggle/kaggle.json"), 0o600)

    # ---------- パッケージインストール ----------
    # （Kaggle 側で事前インストール済みのものを補完）
    os.system("pip install -q kaggle")
    # 必要に応じて追加: vllm, transformers, etc.

    # ---------- データダウンロード ----------
    # competition_sources
    # <competition_sources をループして kaggle competitions download を実行>

    # dataset_sources
    # <dataset_sources をループして kaggle datasets download を実行>

    # kernel_sources（ユーティリティカーネルの出力）
    # <kernel_sources をループして kaggle kernels output を実行>

    # model_sources（大型モデルは Drive マウント推奨）
    # <model_sources があれば Drive マウントまたは HuggingFace への切り替えをコメントで案内>

elif ENV == "local":
    # ---------- ローカル（VSCode）用データの準備 ----------
    # data/ ディレクトリにデータが揃っているか確認し、なければダウンロードする
    import subprocess

    def _kaggle(*args):
        """uv run kaggle <args> を実行し、stdout を返す"""
        result = subprocess.run(["uv", "run", "kaggle", *args], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"[warn] kaggle {' '.join(args)} failed:\n{result.stderr}")
        return result.returncode == 0

    # competition_sources
    # <competition_sources をループして以下を生成>
    # if not os.path.exists("data/<competition-slug>"):
    #     os.makedirs("data/<competition-slug>", exist_ok=True)
    #     _kaggle("competitions", "download", "-c", "<competition-slug>", "-p", "data/<competition-slug>")
    #     subprocess.run(["unzip", "-q", "-o",
    #                     "data/<competition-slug>/<competition-slug>.zip",
    #                     "-d", "data/<competition-slug>"])

    # dataset_sources
    # <dataset_sources をループして以下を生成>
    # if not os.path.exists("data/<dataset-name>"):
    #     _kaggle("datasets", "download", "<owner>/<slug>", "-p", "data/<dataset-name>", "--unzip")

    # kernel_sources（ユーティリティカーネルの出力）
    # <kernel_sources をループして以下を生成>
    # if not os.path.exists("data/<kernel-name>"):
    #     _kaggle("kernels", "output", "<owner>/<slug>", "-p", "data/<kernel-name>")

    # model_sources はサイズが大きいため原則スキップ
    # 必要な場合は HuggingFace から小型代替モデルを使うか、手動で配置すること
    print("[local] data check complete")
```

**実際のダウンロードコマンドは `kernel-metadata.json` の内容で埋める。** 空のコメントは残さず、具体的なコマンドを生成すること。

> **ローカル実行の前提**: `.env` に `KAGGLE_API_TOKEN` が設定されていること。
> ノートブックをローカルで起動する前に `export $(cat .env | xargs)` を実行するか、
> `.env` を自動読み込みする設定（`python-dotenv` 等）をセットアップしておく。

---

### Step 4: パス変換

ノートブック内の `/kaggle/input/...` および `/kaggle/working/` を含む**すべての文字列リテラル**を、環境判定ブロックに置き換える。

**変換テンプレート:**

```python
# 変換前（Kaggle 固有）
path = "/kaggle/input/<competition-or-dataset-slug>/some/file.csv"

# 変換後（環境分岐）
if ENV == "kaggle":
    _BASE = "/kaggle/input/<competition-or-dataset-slug>"
elif ENV == "colab":
    _BASE = "/content/<local-name>"   # Step 3 でダウンロードしたパス
else:
    _BASE = "./data/<local-name>"     # ローカルパス
path = f"{_BASE}/some/file.csv"
```

- `/kaggle/working/` → Colab では `/content/output/`、ローカルでは `./output/`
- モデルパス `/kaggle/input/<model-slug>/` → Colab では Drive か HuggingFace model ID をコメントで案内
- ローカルの `./data/<name>` は Step 3 のセットアップセルで自動ダウンロードされるパスと一致させること

---

### Step 5: Kaggle Secrets の変換（該当する場合）

`UserSecretsClient` を使っているセルがある場合：

```python
# 変換前（Kaggle Secrets）
from kaggle_secrets import UserSecretsClient
secret = UserSecretsClient().get_secret("MY_KEY")

# 変換後（環境分岐）
if ENV == "kaggle":
    from kaggle_secrets import UserSecretsClient
    secret = UserSecretsClient().get_secret("MY_KEY")
elif ENV == "colab":
    from google.colab import userdata
    secret = userdata.get("MY_KEY")  # Colab Secrets に同名で登録
else:
    secret = os.environ.get("MY_KEY", "")  # .env から読み込み
```

---

### Step 6: 変更サマリーをユーザーに報告

以下の形式で変更内容を報告する：

```
## colab-adapt 変更サマリー

**挿入したセル:**
- セル 0（先頭）: 環境セットアップ（ENV 判定 + Colab/ローカル データダウンロード）

**変換したパス:**
- セル X: `/kaggle/input/ai-mathematical-olympiad-progress-prize-3/test.csv` → ENV 分岐
- セル Y: `/kaggle/working/submission.csv` → ENV 分岐

**Colab Secrets に登録が必要なキー:**
- `KAGGLE_API_TOKEN`: {"username":"...","key":"..."} 形式の JSON 文字列

**注意事項:**
- <model_sources に大型モデルがある場合の警告>
- <インターネット制限の変化等>
```

---

### チェックリスト

- [ ] セットアップセルが先頭に挿入されている
- [ ] `/kaggle/input/` パスがすべて ENV 分岐に変換されている
- [ ] Colab でのダウンロードコマンドが具体的に記述されている（空コメント不可）
- [ ] ローカルの `ENV == "local"` ブロックに `uv run kaggle` によるダウンロードコマンドが記述されている（`pass` のみは不可）
- [ ] ローカルのパス（`./data/<name>`）とダウンロード先が一致している
- [ ] `.env` に `KAGGLE_API_TOKEN` が必要な旨がユーザーに伝えられている
- [ ] Colab Secrets に登録すべきキーがユーザーに伝えられている
- [ ] 大型モデルがある場合、Colab での代替手段（Drive / HuggingFace / 小型モデルへの変更）を案内している
- [ ] `ENV == "kaggle"` の場合は元の動作が変わっていない
