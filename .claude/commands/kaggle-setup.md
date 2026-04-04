# kaggle-setup

他者の Kaggle Notebook をベースに、このリポジトリで開発・デプロイできる状態にセットアップする。

## 使い方

```
/kaggle-setup <notebook-url>
```

例:
```
/kaggle-setup https://www.kaggle.com/code/crazyzzz7/answer-evolve
```

## 手順

以下のステップを順番に実行すること。手動操作が必要なステップは明示してユーザーに確認を取ること。

---

### Step 1: コピー元の情報を取得

```bash
export $(cat .env | xargs)
uv run kaggle kernels pull <owner>/<slug> -p /tmp/<slug>-orig --metadata
cat /tmp/<slug>-orig/kernel-metadata.json
```

取得した `dataset_sources`, `kernel_sources`, `model_sources`, `competition_sources` を記録する。

---

### Step 2: Kaggle 上で Copy & Edit（手動）

ユーザーに以下を依頼する：

1. コピー元 URL を開く
2. **Copy & Edit** ボタンをクリック
3. タイトルを任意の名前に変更（例: `aimop-solve`）
4. 作成されたノートブックの URL スラッグを教えてもらう（例: `shotokishida/answer-evolve`）

> **なぜ手動か**: Kaggle API ではデータソースの引き継ぎができないため、UI 経由の Copy & Edit が必要。

---

### Step 3: main/ にノートブックをコピー

```bash
cp /tmp/<slug>-orig/<slug>.ipynb main/<new-name>.ipynb
```

ファイル名はコンペ名を反映した名前にする（例: `aimop-solver.ipynb`）。

---

### Step 4: kernel-metadata.json を更新

`main/kernel-metadata.json` を以下の内容で更新する：

- `id`: Step 2 で作成したスラッグ（例: `shotokishida/answer-evolve`）
- `title`: Step 2 で設定したタイトル
- `code_file`: Step 3 のファイル名
- `dataset_sources`, `kernel_sources`, `competition_sources`, `model_sources`: Step 1 で取得した値

---

### Step 5: 必要なデータをローカルにダウンロード

EDA 用に必要なデータをダウンロードする（モデルは除外）。

```bash
# コンペデータ
uv run kaggle competitions download -c <competition-slug> -p data/ 
cd data && unzip <competition-slug>.zip && cd ..

# データセット（モデル以外）
uv run kaggle datasets download <dataset-slug> -p data/<name> --unzip

# カーネル出力（必要な場合）
uv run kaggle kernels output <kernel-slug> -p data/<name>
```

---

### Step 6: デプロイして動作確認

```bash
git add main/
git commit -m "feat: <コンペ名> セットアップ"
git push origin main
```

GitHub Actions が自動デプロイされるのを確認：

```bash
export $(cat .env | xargs) && sleep 20 && gh run list --limit 3
```

Kaggle 上でノートブックを開き **Run All** で動作確認。

---

### チェックリスト

- [ ] `kernel-metadata.json` の `id` が Copy & Edit 後のスラッグになっている
- [ ] `kernel_sources` / `dataset_sources` がコピー元と一致している
- [ ] コンペデータがローカルの `data/` にある
- [ ] GitHub Actions が success になっている
- [ ] Kaggle 上の Input にデータソースが表示されている
