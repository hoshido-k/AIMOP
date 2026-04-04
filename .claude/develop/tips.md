# 操作 Tips

---

## Kaggle API CLI

### 前提

```bash
# 環境変数を .env から読み込む
export $(cat .env | xargs)

# すべての kaggle コマンドは uv run 経由で実行
uv run kaggle <subcommand>
```

---

### ノートブックのデプロイ（実行開始）

```bash
# main/ ディレクトリをプッシュ → Kaggle 上で実行開始
uv run kaggle kernels push -p main
```

> GitHub Actions 経由（`main` ブランチに push）でも自動実行される。

---

### 実行状態の確認

```bash
# ステータス確認（queued / running / complete / error）
uv run kaggle kernels status shotokishida/aimop-solve

# 完了まで繰り返し確認する場合
watch -n 30 'export $(cat .env | xargs) && uv run kaggle kernels status shotokishida/aimop-solve'
```

---

### 実行ログ・エラー内容の確認

```bash
# ノートブックの出力（stdout / stderr）を取得
uv run kaggle kernels output shotokishida/aimop-solve -p /tmp/kernel-output

# ログファイルを確認
ls /tmp/kernel-output/
cat /tmp/kernel-output/*.log 2>/dev/null || cat /tmp/kernel-output/*.txt
```

> 実行完了後でないと出力が取得できない。実行中はブラウザで確認するのが確実。

---

### ノートブックのダウンロード（pull）

```bash
# 最新版をローカルに取得（--metadata でメタデータも取得）
uv run kaggle kernels pull shotokishida/aimop-solve -p /tmp/pulled --metadata

# 取得したノートブックを main/ に反映する場合
cp /tmp/pulled/aimop-solve.ipynb main/aimop-solver.ipynb
```

---

### データ・コンペ関連

```bash
# コンペデータのダウンロード
uv run kaggle competitions download -c ai-mathematical-olympiad-progress-prize-3 -p data/

# データセットのダウンロード
uv run kaggle datasets download amanatar/50problems -p data/50problems --unzip

# カーネル出力のダウンロード（他ユーザーのカーネル出力を利用する場合）
uv run kaggle kernels output andreasbis/aimo-3-utils -p data/aimo-utils
```

---

### 他ユーザーのコードを探索

```bash
# キーワード検索
uv run kaggle kernels list --search "mathematical olympiad"

# 特定コンペのカーネル一覧
uv run kaggle kernels list --competition ai-mathematical-olympiad-progress-prize-3

# 投票数順・スコア順でソート（上位解法調査に有効）
uv run kaggle kernels list --search "aimo" --sort-by voteCount
uv run kaggle kernels list --competition ai-mathematical-olympiad-progress-prize-3 --sort-by bestPublicScore

# 特定ユーザーのカーネル一覧
uv run kaggle kernels list --user crazyzzz7

# 他ユーザーのノートブックをダウンロード（公開のみ）
uv run kaggle kernels pull crazyzzz7/answer-evolve -p /tmp/answer-evolve --metadata

# 他ユーザーのカーネル出力（CSV・モデル等）を取得
uv run kaggle kernels output crazyzzz7/answer-evolve -p /tmp/output
```

> 非公開カーネル・実行中の出力は取得不可。

---

### よく使うコマンド一覧

| 操作 | コマンド |
|------|---------|
| プッシュ（実行開始） | `uv run kaggle kernels push -p main` |
| 状態確認 | `uv run kaggle kernels status shotokishida/aimop-solve` |
| ログ取得 | `uv run kaggle kernels output shotokishida/aimop-solve -p /tmp/out` |
| ノートブック取得 | `uv run kaggle kernels pull shotokishida/aimop-solve -p /tmp/pulled` |
| コンペデータ取得 | `uv run kaggle competitions download -c <slug> -p data/` |
| サブミット一覧 | `uv run kaggle competitions submissions -c <slug>` |
| 他ユーザーのコード検索 | `uv run kaggle kernels list --search <keyword> --sort-by voteCount` |
| 他ユーザーのコード取得 | `uv run kaggle kernels pull <user>/<slug> -p /tmp/<slug> --metadata` |

---

## Google Colab × VSCode

### 環境の違い（重要）

```
VSCode（ローカル / uv 管理）  ≠  Google Colab（クラウド VM）
```

- **ローカルでインストールしたパッケージは Colab に反映されない**
- Colab セッションは揮発性：セッション切れでパッケージが消える

### Colab でのパッケージインストール

```python
# Colab のセルで毎回実行する
!pip install -q some-package another-package
```

### データのマウント・転送

```python
# Google Drive をマウント（Colab から）
from google.colab import drive
drive.mount('/content/drive')

# ローカル → Colab にアップロード
from google.colab import files
files.upload()
```

### Kaggle データを Colab で使う

```python
# Colab 上で Kaggle API を設定してデータ取得
!pip install -q kaggle
from google.colab import files
files.upload()  # kaggle.json をアップロード
!mkdir -p ~/.kaggle && mv kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json

!kaggle competitions download -c ai-mathematical-olympiad-progress-prize-3
!unzip ai-mathematical-olympiad-progress-prize-3.zip
```

### VSCode から Colab に接続する（参考）

公式サポートは縮小傾向のため、**GPU が必要な重い処理は Kaggle Notebook を使う方が安定**。

ローカル実行で十分な場合は VSCode + `uv run jupyter lab` で完結できる。

```bash
# ローカル Jupyter を起動
uv run jupyter lab
```

---

## Kaggle Notebook → Google Colab 対応

他人の Kaggle Notebook をコピーして Colab で動かす場合、以下の変換が必要になる。

### 環境差異の早見表

| 項目 | Kaggle Notebook | Google Colab |
|------|----------------|-------------|
| データパス | `/kaggle/input/<slug>/` | `/content/<name>/` または Drive |
| GPU | kernel-metadata.json で指定 | ランタイム設定で選択 |
| パッケージ | Kaggle 側で事前インストール済み多数 | セル内で `!pip install` |
| インターネット | コンペ規則で無効の場合あり | 基本有効 |
| モデル | `/kaggle/input/<model-slug>/` | Drive マウントまたは HuggingFace |
| 実行時間 | 最大9時間 | 最大12時間（Pro）/ 無料枠は短い |
| `kernel-metadata.json` | Kaggle push 時に使用 | **不要・無視される** |

---

### kernel-metadata.json の扱い

`kernel-metadata.json` は **Kaggle へのデプロイ設定ファイル**であり、Colab では使用しない。  
Colab で実行する際は完全に無視してよい。

Colab 対応コードを書く場合は、`kernel-metadata.json` に記載されている情報を参照して以下に変換する：

```json
// kernel-metadata.json の読み方
{
  "dataset_sources": ["amanatar/50problems"],        // → Colab では kaggle CLI でダウンロード
  "competition_sources": ["ai-mathematical-..."],    // → Colab では kaggle CLI でダウンロード
  "kernel_sources": ["andreasbis/aimo-3-utils"],     // → Colab では kaggle kernels output で取得
  "model_sources": ["danielhanchen/gpt-oss-120b/..."]// → Colab では HuggingFace or Drive から
}
```

---

### データパスの変換

Kaggle Notebook のコードに出てくるパスを Colab 用に書き換える。

```python
# Kaggle でのパス例
data_path = "/kaggle/input/ai-mathematical-olympiad-progress-prize-3/test.csv"
model_path = "/kaggle/input/danielhanchen/gpt-oss-120b/transformers/default/1"

# Colab 対応：環境を判定して切り替える
import os

def is_kaggle():
    return os.path.exists("/kaggle")

def is_colab():
    try:
        import google.colab
        return True
    except ImportError:
        return False

if is_kaggle():
    DATA_DIR = "/kaggle/input/ai-mathematical-olympiad-progress-prize-3"
    MODEL_DIR = "/kaggle/input/danielhanchen/gpt-oss-120b/transformers/default/1"
elif is_colab():
    DATA_DIR = "/content/data"
    MODEL_DIR = "/content/drive/MyDrive/models/gpt-oss-120b"
else:
    # ローカル（VSCode）
    DATA_DIR = "./data"
    MODEL_DIR = "./models/gpt-oss-120b"
```

---

### Colab セットアップセル（ノートブック先頭に追加）

他人の Kaggle Notebook をコピーしたら、先頭に以下のセルを追加する。

```python
# ===== Colab セットアップ（Kaggle では自動スキップ） =====
import os

def is_colab():
    try:
        import google.colab
        return True
    except ImportError:
        return False

if is_colab():
    # 1. Kaggle API 設定
    from google.colab import files, userdata
    os.makedirs(os.path.expanduser("~/.kaggle"), exist_ok=True)

    # Colab Secrets に KAGGLE_API_TOKEN を登録しておく場合（推奨）
    token = userdata.get("KAGGLE_API_TOKEN")
    with open(os.path.expanduser("~/.kaggle/kaggle.json"), "w") as f:
        import json
        json.dump({"key": token}, f)   # username も必要なら別途設定
    os.chmod(os.path.expanduser("~/.kaggle/kaggle.json"), 0o600)

    # 2. 必要パッケージのインストール
    # （Kaggle Notebook では事前インストール済みのものを補完）
    os.system("pip install -q kaggle vllm")

    # 3. コンペデータのダウンロード
    os.makedirs("/content/data", exist_ok=True)
    os.system("kaggle competitions download -c ai-mathematical-olympiad-progress-prize-3 -p /content/data")
    os.system("cd /content/data && unzip -q ai-mathematical-olympiad-progress-prize-3.zip")

    # 4. カーネル依存の取得
    os.system("kaggle kernels output andreasbis/aimo-3-utils -p /content/aimo-utils")
```

> Colab Secrets（左サイドバーの鍵アイコン）に `KAGGLE_API_TOKEN` を登録しておくと、毎回 kaggle.json をアップロードしなくて済む。

---

### モデルの扱い

大型モデル（GPT-OSS-120B など）は Colab の無料枠では動かない（VRAM 不足）。  
T4（15GB）や A100（40GB）でも容量が足りない場合が多い。

| モデル取得方法 | 用途 |
|--------------|------|
| HuggingFace Hub から直接ロード | 小〜中規模モデル（7B, 13B） |
| Google Drive にマウント済みを使う | 事前にダウンロードした大型モデル |
| `kaggle datasets download` で取得 | Kaggle データセットとして公開されているモデル |

```python
# HuggingFace からロード（Colab）
from transformers import AutoModelForCausalLM, AutoTokenizer

model_name = "meta-llama/Llama-3.1-8B-Instruct"  # 小さいモデルで代替
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name, device_map="auto")
```

---

### よくある変換ポイント チェックリスト

Kaggle Notebook を Colab に持ち込む際の確認事項：

- [ ] セットアップセル（上記）をノートブック先頭に追加
- [ ] `/kaggle/input/...` パスを環境判定コードで置き換え
- [ ] `kernel-metadata.json` で指定されているデータソースをすべてダウンロード
- [ ] Kaggle 側で事前インストール済みのパッケージを `!pip install` で補完
- [ ] GPU メモリ要件を確認（120B モデルは Colab 不可）
- [ ] インターネット制限がある場合、Colab では制限なしに変わる点を考慮
- [ ] セッション揮発性に対応（Drive に中間結果を保存する等）
