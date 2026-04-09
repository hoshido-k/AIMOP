---
name: kaggle-start
description: Scaffold a new notebook experiment directory under notebooks/<name>/. Use when starting a new experiment — creates kernel-metadata.json, GitHub Actions workflow, and either a blank notebook with ENV branching or pulls an existing Kaggle notebook and converts it for Colab/local use.
argument-hint: <name>
disable-model-invocation: true
---

新しいノートブック実験ディレクトリを `notebooks/<name>/` にスキャフォールドする。
ベースとなる Kaggle Notebook URL を指定した場合は、そのノートブックを Pull して Colab/ローカル対応に変換する。
URL を省略（Enter のみ）した場合は最小ノートブックを生成する。

## 使い方

```
/kaggle-start <name>
```

例:
```
# URL なし → 最小ノートブックを生成
/kaggle-start deepseek-r1-math

# URL あり → Pull して Colab 対応に変換（Step 3 でインタラクティブに入力）
/kaggle-start answer-evolve-base
```

`<name>` はディレクトリ名かつ Kaggle カーネルのスラッグベース名になる（小文字・ハイフン区切り推奨）。

---

## 手順

以下を順番に実行すること。

---

### Step 1: 引数の確認

`$ARGUMENTS` から `NAME` を取り出す。指定がなければエラーを出して終了する。

```
DIR = notebooks/<NAME>
```

`DIR` がすでに存在する場合はユーザーに警告し、上書きするか確認してから続行する。

---

### Step 2: Kaggle ユーザー名の取得

`.env` から Kaggle ユーザー名を取得する。

```bash
export $(cat .env | xargs)
uv run kaggle config view
```

出力の `username` を `KAGGLE_USER` として記録する。取得できない場合はユーザーに直接確認する。

---

### Step 3: ベース Notebook URL の確認（インタラクティブ）

ユーザーに以下のメッセージを表示して入力を求める：

```
ベースにする Kaggle Notebook の URL を入力してください。
なければ Enter のみで空白を返してください。
例: https://www.kaggle.com/code/crazyzzz7/answer-evolve
```

- **URL が入力された場合** → `SOURCE_URL` として記録し、Step 3a へ進む
- **空白（Enter のみ）の場合** → `SOURCE_URL = ""` として Step 4 へスキップする

---

### Step 3a: ベース Notebook の Pull（URL あり時のみ）

URL からオーナーとスラッグを抽出する（例: `https://www.kaggle.com/code/crazyzzz7/answer-evolve` → `crazyzzz7/answer-evolve`）。

```bash
export $(cat .env | xargs)
uv run kaggle kernels pull <owner>/<slug> -p /tmp/kaggle-start-<NAME> --metadata
```

取得した `/tmp/kaggle-start-<NAME>/kernel-metadata.json` から以下を記録する：
- `dataset_sources`, `competition_sources`, `kernel_sources`, `model_sources`
- `machine_shape`, `enable_gpu`, `enable_internet`

これらは Step 4 の kernel-metadata.json 生成に使う（コピー元の設定を引き継ぐ）。

---

### Step 3b: ノートブックを DIR にコピー（URL あり時のみ）

```bash
mkdir -p <DIR>
cp /tmp/kaggle-start-<NAME>/<slug>.ipynb <DIR>/<NAME>.ipynb
```

コピー後、**Step 5（ノートブック生成）はスキップして Step 5b（Colab 変換）へ進む**。

---

### Step 4: kernel-metadata.json の生成

`<DIR>/kernel-metadata.json` を以下の内容で作成する。
値はこのリポジトリの標準設定（AIMO-3）をデフォルトとして使い、ユーザーへの確認は最小限にとどめる。

```json
{
  "id": "<KAGGLE_USER>/<NAME>",
  "title": "<NAME>",
  "code_file": "<NAME>.ipynb",
  "language": "python",
  "kernel_type": "notebook",
  "is_private": "true",
  "enable_gpu": "true",
  "enable_tpu": "false",
  "enable_internet": "false",
  "dataset_sources": [
    "amanatar/50problems"
  ],
  "competition_sources": [
    "ai-mathematical-olympiad-progress-prize-3"
  ],
  "kernel_sources": [
    "andreasbis/aimo-3-utils"
  ],
  "model_sources": [
    "danielhanchen/gpt-oss-120b/Transformers/default/1"
  ],
  "machine_shape": "NvidiaH100"
}
```

> URL あり（Step 3a 実行済み）の場合は、取得した metadata の値でデータソースを上書きすること。
> ユーザーが既存カーネルの URL を持っている場合（Kaggle 上で Copy & Edit 済み）、
> `id` をそのスラッグ（例: `shotokishida/answer-evolve`）に変更するよう案内する。

---

### Step 5: 最小ノートブックの生成（URL なし時のみ）

`<DIR>/<NAME>.ipynb` を以下の構成で生成する。

**セル 1（コード）: 環境セットアップ**

```python
# ===== 環境セットアップ =====
import os, subprocess

def _is_kaggle():
    return os.path.exists("/kaggle/input")

def _is_colab():
    try:
        import google.colab  # noqa: F401
        return True
    except ImportError:
        return False

ENV = "kaggle" if _is_kaggle() else "colab" if _is_colab() else "local"
print(f"[env] {ENV}")

# ---------- Colab セットアップ ----------
if ENV == "colab":
    from google.colab import userdata
    os.makedirs(os.path.expanduser("~/.kaggle"), exist_ok=True)
    with open(os.path.expanduser("~/.kaggle/kaggle.json"), "w") as f:
        f.write(userdata.get("KAGGLE_API_TOKEN"))
    os.chmod(os.path.expanduser("~/.kaggle/kaggle.json"), 0o600)
    os.system("pip install -q kaggle")
    # データダウンロード
    os.makedirs("/content/data", exist_ok=True)
    os.system("kaggle competitions download -c ai-mathematical-olympiad-progress-prize-3 -p /content/data")
    os.system("cd /content/data && unzip -q -o ai-mathematical-olympiad-progress-prize-3.zip")
    os.system("kaggle datasets download amanatar/50problems -p /content/50problems --unzip")
    os.system("kaggle kernels output andreasbis/aimo-3-utils -p /content/aimo-utils")

# ---------- ローカル セットアップ ----------
elif ENV == "local":
    def _kaggle(*args):
        r = subprocess.run(["uv", "run", "kaggle", *args], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"[warn] {r.stderr}")
        return r.returncode == 0
    if not os.path.exists("data/aimo3"):
        os.makedirs("data/aimo3", exist_ok=True)
        _kaggle("competitions", "download", "-c", "ai-mathematical-olympiad-progress-prize-3", "-p", "data/aimo3")
        subprocess.run(["unzip", "-q", "-o", "data/aimo3/ai-mathematical-olympiad-progress-prize-3.zip", "-d", "data/aimo3"])
    if not os.path.exists("data/50problems"):
        _kaggle("datasets", "download", "amanatar/50problems", "-p", "data/50problems", "--unzip")
    if not os.path.exists("data/aimo-utils"):
        _kaggle("kernels", "output", "andreasbis/aimo-3-utils", "-p", "data/aimo-utils")
    print("[local] data ready")
```

**セル 2（コード）: パス定義**

```python
# ===== パス定義 =====
if ENV == "kaggle":
    DATA_DIR   = "/kaggle/input/ai-mathematical-olympiad-progress-prize-3"
    PROB_DIR   = "/kaggle/input/amanatar/50problems"
    UTILS_DIR  = "/kaggle/input/andreasbis/aimo-3-utils/aimo-3-utils"
    MODEL_DIR  = "/kaggle/input/danielhanchen/gpt-oss-120b/Transformers/default/1"
    OUTPUT_DIR = "/kaggle/working"
elif ENV == "colab":
    DATA_DIR   = "/content/data"
    PROB_DIR   = "/content/50problems"
    UTILS_DIR  = "/content/aimo-utils"
    MODEL_DIR  = None  # 大型モデルは Colab 非対応（Drive マウントか小型代替モデルを使うこと）
    OUTPUT_DIR = "/content/output"
else:  # local
    DATA_DIR   = "data/aimo3"
    PROB_DIR   = "data/50problems"
    UTILS_DIR  = "data/aimo-utils"
    MODEL_DIR  = None  # ローカルでは大型モデルを使わない
    OUTPUT_DIR = "output"

os.makedirs(OUTPUT_DIR, exist_ok=True)
print(f"DATA_DIR={DATA_DIR}")
```

**セル 3（コード）: データ読み込み確認**

```python
# ===== データ読み込み =====
import pandas as pd

test_df = pd.read_csv(f"{DATA_DIR}/test.csv")
print(f"test shape: {test_df.shape}")
print(test_df.head(2))
```

**セル 4（コード）: 提出ファイル雛形**

```python
# ===== 提出ファイル =====
import pandas as pd

submission = pd.DataFrame({
    "id": test_df["id"],
    "answer": 0
})
submission.to_csv(f"{OUTPUT_DIR}/submission.csv", index=False)
print("submission.csv saved")
```

---

### Step 5b: Pull したノートブックを Colab/ローカル対応に変換（URL あり時のみ）

`<DIR>/<NAME>.ipynb` に対して `colab-adapt` と同等の変換を行う。

**処理内容:**

1. **ノートブック全セルを読んで調査する**
   - `/kaggle/input/...` パスをすべて洗い出す
   - `UserSecretsClient` の利用箇所を確認する
   - pip インストール省略箇所を確認する

2. **セットアップセルをノートブック先頭に挿入する**

   Step 4 の `kernel-metadata.json` に記載されたデータソースをもとに、具体的なダウンロードコマンドを生成して埋め込む。
   テンプレートは以下（空コメントは残さず実際のスラッグを埋めること）：

   ```python
   # ===== 環境セットアップ =====
   import os, subprocess

   def _is_kaggle():
       return os.path.exists("/kaggle/input")

   def _is_colab():
       try:
           import google.colab  # noqa: F401
           return True
       except ImportError:
           return False

   ENV = "kaggle" if _is_kaggle() else "colab" if _is_colab() else "local"
   print(f"[env] {ENV}")

   if ENV == "colab":
       from google.colab import userdata
       os.makedirs(os.path.expanduser("~/.kaggle"), exist_ok=True)
       with open(os.path.expanduser("~/.kaggle/kaggle.json"), "w") as f:
           f.write(userdata.get("KAGGLE_API_TOKEN"))
       os.chmod(os.path.expanduser("~/.kaggle/kaggle.json"), 0o600)
       os.system("pip install -q kaggle")
       # <competition_sources をループしてダウンロードコマンドを生成>
       # <dataset_sources をループしてダウンロードコマンドを生成>
       # <kernel_sources をループしてダウンロードコマンドを生成>

   elif ENV == "local":
       def _kaggle(*args):
           r = subprocess.run(["uv", "run", "kaggle", *args], capture_output=True, text=True)
           if r.returncode != 0:
               print(f"[warn] {r.stderr}")
           return r.returncode == 0
       # <competition_sources をループして存在チェック+ダウンロードコマンドを生成>
       # <dataset_sources をループして存在チェック+ダウンロードコマンドを生成>
       # <kernel_sources をループして存在チェック+ダウンロードコマンドを生成>
       print("[local] data ready")
   ```

3. **パス定義セルを挿入する**（Step 5 の「パス定義セル」と同じ構造で、実際のパスを埋める）

4. **`/kaggle/input/...` パスをすべて ENV 分岐に変換する**

   ```python
   # 変換前
   path = "/kaggle/input/<slug>/file.csv"

   # 変換後
   if ENV == "kaggle":
       _BASE = "/kaggle/input/<slug>"
   elif ENV == "colab":
       _BASE = "/content/<local-name>"
   else:
       _BASE = "data/<local-name>"
   path = f"{_BASE}/file.csv"
   ```

5. **`UserSecretsClient` を ENV 分岐に変換する**（該当する場合）

6. **変換サマリーをユーザーに報告する**

---

### Step 6: GitHub Actions ワークフローの生成

`.github/workflows/kaggle-push-<NAME>.yml` を作成する。

```yaml
name: Push <NAME> Notebook to Kaggle

on:
  push:
    branches:
      - main
    paths:
      - "notebooks/<NAME>/**"
  workflow_dispatch:

jobs:
  push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install Kaggle CLI
        run: pip install kaggle

      - name: Push notebook to Kaggle
        env:
          KAGGLE_API_TOKEN: ${{ secrets.KAGGLE_API_TOKEN }}
        run: |
          export KAGGLE_TOKEN=$KAGGLE_API_TOKEN
          kaggle kernels push -p notebooks/<NAME>
```

---

### Step 7: ローカルデータの確認・ダウンロード

`data/` にデータが揃っているか確認し、不足分を取得する。
（kernel-metadata.json の competition_sources / dataset_sources / kernel_sources に基づいて実行）

```bash
export $(cat .env | xargs)

# コンペデータ
if [ ! -d "data/aimo3" ]; then
  mkdir -p data/aimo3
  uv run kaggle competitions download -c ai-mathematical-olympiad-progress-prize-3 -p data/aimo3
  unzip -q -o data/aimo3/ai-mathematical-olympiad-progress-prize-3.zip -d data/aimo3
fi

# 50problems データセット
if [ ! -d "data/50problems" ]; then
  uv run kaggle datasets download amanatar/50problems -p data/50problems --unzip
fi

# aimo-3-utils カーネル出力
if [ ! -d "data/aimo-utils" ]; then
  uv run kaggle kernels output andreasbis/aimo-3-utils -p data/aimo-utils
fi
```

モデル（gpt-oss-120b）は大型のためローカルにはダウンロードしない。Kaggle 上でのみ利用する。

---

### Step 8: KAGGLE_API_TOKEN の GitHub Secret 確認

```bash
export $(cat .env | xargs)
gh secret list
```

`KAGGLE_API_TOKEN` が表示されない場合のみ登録する：

```bash
gh secret set KAGGLE_API_TOKEN --body "$KAGGLE_API_TOKEN"
```

---

### Step 9: 作成内容のサマリーをユーザーに報告

以下の形式で報告する（URL あり/なしで内容を出し分ける）：

```
## kaggle-start 完了: <NAME>

**モード:** URL あり（<SOURCE_URL> から Pull・Colab 変換） / URL なし（最小ノートブック生成）

**作成・変換したファイル:**
- notebooks/<NAME>/kernel-metadata.json
- notebooks/<NAME>/<NAME>.ipynb
  - URL なし: ENV 分岐・データ読み込み・提出雛形の4セル構成
  - URL あり: コピー元をベースに ENV 分岐セル挿入・/kaggle/input/ パス変換・UserSecretsClient 変換済み
- .github/workflows/kaggle-push-<NAME>.yml

**ローカルデータ:**
- data/<source>/  → 各データソース（あり / 新規取得） ← kernel-metadata.json の内容に応じて列挙

**次のステップ:**
1. notebooks/<NAME>/<NAME>.ipynb を開いてメイン実装を確認・追記
2. Kaggle 上で Copy & Edit 済みの場合は kernel-metadata.json の id を実際のスラッグに更新
3. git push → GitHub Actions で自動デプロイ → Kaggle で Run All
```

---

### チェックリスト

- [ ] `notebooks/<NAME>/kernel-metadata.json` が生成されている
- [ ] `notebooks/<NAME>/<NAME>.ipynb` が生成されている（ENV 分岐セル付き）
- [ ] `.github/workflows/kaggle-push-<NAME>.yml` が生成されている
- [ ] （URL あり）`/kaggle/input/...` パスがすべて ENV 分岐に変換されている
- [ ] （URL あり）ノートブック先頭にセットアップセルが挿入されている
- [ ] ローカルデータ（competition / dataset / kernel_sources）が `data/` に揃っている
- [ ] `KAGGLE_API_TOKEN` が GitHub Secret に登録されている
