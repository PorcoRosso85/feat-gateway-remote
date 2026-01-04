# Handoff Specs (実装者向け)

## 実装対象（A〜E）

### (A) gw-doctor read-only 方針

gw-doctor は「読み取り専用」ツールであり、以下の自動修復は一切しない:

- 鍵生成
- known_hosts 追記
- 権限修正 (chmod)
- 自動セットアップ

```bash
gw-doctor check-tools    # 必須ツール確認（読み取り）
gw-doctor forbid-scan    # 禁止項目検査（読み取り）
gw-doctor key-check      # 鍵健全性確認（読み取りのみ）
```

### (B) 鍵健全性の検出方法

```bash
gw-doctor key-check [key_file]
```

検出項目:
- ファイルが存在しない (WARN)
- 読み取り不可 (WARN)
- 破損/パスフレーズ付き (FAIL)
- 権限が600/400以外 (WARN)

```bash
# 使用例
gw-doctor key-check              # ~/.ssh/id_rsa を検査
gw-doctor key-check ~/.ssh/id_ed25519  # 指定ファイルを検査
```

### (C) hostkey UX 方針

```bash
gw-ssh [options] [user@]host
```

オプション:
- `--help` ヘルプ表示
- `--accept-new` 新しいホスト鍵を自動受理（デフォルト: ask）

```bash
# 使用例
gw-ssh user@host           # デフォルト（ask）
gw-ssh --accept-new user@host  # 自動受理
```

デフォルトは `StrictHostKeyChecking=ask` で、対話的に確認する。

### (D) DoD-L3 証拠ログ要件

E2E証拠として以下を取得:

| # | 項目 | 証拠 |
|---|------|------|
| 1 | gw-pick 実行 | 実行ログ |
| 2 | SSH 接続確立 | 実行ログ |
| 3 | ProxyJump/ProxyCommand 禁止 | コード確認 (`-o ProxyJump=none -o ProxyCommand=none`) |
| 4 | RemoteCommand で zmx attach | remote 側の実行ログ |

### (E) gw-doctor --info フラグ

gw-doctor は2つの動作モードを持つ:

| フラグ | 動作 | 用途 |
|--------|------|------|
| なし | fail-fast (問題があれば exit non-0) | CI/自動化、 Issue 検出 |
| `--info` | 情報表示のみ (常に exit 0) | 人間による確認、レポート |

```bash
# CI/自動化: 問題があれば失敗
gw-doctor check-tools    # ツール缺失 → exit 1

# 人間確認: 問題を表示するが成功扱い
gw-doctor check-tools --info   # ツール缺失 → 表示、exit 0
```

---

## 受入条件

1. doctor が「修復しない」ことが明文化されている
2. 鍵が壊れている場合に事前検知できる
3. gw-ssh で実接続が1回成功する
4. RemoteCommand で remote 側 zmx attach に入ったログが残る

---

## コミット

- `10e59e1` fix: remove local keyword from gw-doctor and add PATH for bb-red
- `3256a94` feat: gw-doctor --info flag + fail-fast policy
- `0a3b0bb` fix: gw-doctor key-check exits 0 always (informational only)
- `ba0e46e` feat: gw-doctor key-check (read-only) + gw-ssh hostkey policy
- `3b481f3` fix: gw-pick UX (exit 0 on cancel) + gw-ssh add RequestTTY=force
