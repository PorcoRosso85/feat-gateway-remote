# Phase-DoD(0) Completed 詳細宣言

## 1. 完了状態サマリー

| 項目 | 状態 | 詳細 |
|-----|------|------|
| **フェーズ完了日** | 2026-01-01 | - |
| **コミット** | `b027f53` | feat: Phase-DoD(0) complete - U2 tmux-forbid, doctor forbid-scan, tests=6 |
| **タグ** | `phase-doD-0-completed` | 再現性確保のため |
| **flake check** | ✅ ALL PASS | `nix flake check` exit 0 |
| **checks** | 3/3 PASS | input-test, contract-apps, bb-red |

---

## 2. テスト結果詳細

### 2.1 input-test ✅

```bash
$ nix build .#checks.x86_64-linux.input-test
# PASS - mock-spec/spec/urn/feat/gateway-remote/{tdd_red,contract}.cue が存在
```

**検証内容**: spec 入力の必須ファイル存在確認

### 2.2 contract-apps ✅

```bash
$ nix build .#checks.x86_64-linux.contract-apps
# PASS - union(contract.commands.wsl, contract.commands.dev) == ops/cmd/* の完全一致
```

**検証内容**: CUE 契約と実ファイル群の集合一致（flatten→sort→uniq→diff）

### 2.3 bb-red ✅ (6 tests)

| # | テストID | 検証内容 | 結果 |
|---|---------|---------|------|
| 1 | help | コマンド存在・固定出力 | PASS |
| 2 | doctor-tools | 必須ツール存在チェック | PASS |
| 3 | pick | コマンド存在・固定出力 | PASS |
| 4 | ssh-direct-only | ProxyJump/-J/JumpHost 禁止 | PASS |
| 5 | status | コマンド存在・固定出力 | PASS |
| 6 | forbid-scan | tmux 混入の静的禁止 | PASS |

**検証方式**: `cue eval tdd_red.cue --out json` → `jq` 抽出 → `bash` 実行 → 結果検証

---

## 3. 成果物構造

```
feat-gateway-remote/
├── mock-spec/
│   └── spec/urn/feat/gateway-remote/
│       ├── contract.cue       # 契約定義（commands.wsl/dev）
│       └── tdd_red.cue        # TDD-RED テスト定義（6 tests）
├── ops/cmd/
│   ├── help                   # スタブ（contracted command: help）
│   ├── doctor                 # スタブ + check-tools + forbid-scan
│   ├── pick                   # スタブ（contracted command: pick）
│   ├── ssh                    # スタブ（contracted command: ssh）
│   └── status                 # スタブ（contracted command: status）
├── decision-log/
│   ├── phase-0-check.log      # flake check ログ（証拠）
│   └── phase-dod-1.md         # Phase-DoD(1) 議決ログ（統合方式 C）
├── flake.nix                  # 入力・オーバーレイ・checks 定義
└── zmx.nix                    # zmx パッケージ定義
```

---

## 4. 経緯・学び（Problem → Solution）

### 4.1 変数名衝突バグ（インフラ系）

| 項目 | 内容 |
|-----|------|
| **問題** | `bb-red` スクリプト内で `out="$(...)"` を使用していたところ、Nix の `runCommand` が `$out` を出力パス変数として使っており、`touch $out` が空文字を指していた |
| **症状** | `nix build` は ALL PASS だが derivations が「failed to produce output path」で失敗 |
| **原因** | `out` という変数名が Nix の特殊変数と衝突 |
| **解決** | `cmd_out` に改名（commit: 変数命名規則の附則追加） |
| **学び** | `runCommand` 内では `$out` を使わず、必ず別の変数名を使用する |

### 4.2 while read + サブシェル終了問題

| 項目 | 内容 |
|-----|------|
| **問題** | `while read ...; do ... exit 1; done < <(...)` 内で `exit 1` しても外のスクリプトに影響せず、原因特定に苦労 |
| **症状** | テストが FAIL  하는데、どのテストで落ちたか不明 |
| **解決** | `while` ループ内で `exit 1` せず、`fail_reason` 変数に理由を格納してループ後に判定する形式に変更 |
| **学び** | `while read` と `exit` は組み合わせない。process substitution を使う場合は `exit` をループ外へ |

### 4.3 tmux-forbid の誤検知（設計限界）

| 項目 | 内容 |
|-----|------|
| **問題** | `doctor forbid-scan` が doctor スクリプト自身の `# doctor: contract verification tool` というコメントを検出し、FAIL した |
| **症状** | `forbid-scan` テストが RED になる |
| **解決** | `grep -rIw --exclude=doctor "tmux"` に変更（doctor 自身除外） |
| **学び** | 「文字列一致」による禁止は誤検知リスクがある。`-w` (word boundary) と `--exclude` で堅牢化 |

### 4.4 U2 設計の最適解（wslinvade の除外）

| 項目 | 内容 |
|-----|------|
| **問題** | 当初 `wslinvade-forbid` を追加しようとしたが、`wsl.exe` を成果物から禁止すると将来の Windows ラッパ（`wsl.exe -d ...`）と衝突 |
| **症状** | 設計意図（WSL/NixOS 向け flake）と Windows 側の設計が混在 |
| **解決** | `wslinvade-forbid` をスコープ外へ。tmux-forbid のみに縮小 |
| **学び** | スコープを明確に。Windows 側の設計は別フェーズ（Phase-DoD(3) 将来）で扱う |

---

## 5. 設計原則の明文化（DoD 附則）

### R1: 判定と証拠の分離

- **DoD 判定**: `nix flake check` の exit code が 0 であること
- **DoD 証拠**: `decision-log/` 以下に運用者が保存したログファイル（判定とは別物）

### R2: BB 期待の配置

- BB 期待（tests[]）は spec 側（tdd_red.cue）に置き、feat 側は runner のみ（DRY）

### R3: tests の制約

- tests はブラックボックス（exit/stdout）で固定。実装詳細の拘束を増やさない（YAGNI）

### R4: 外部参照

- 外部参照は `flake.lock` で pin 再現性を確保

### R5: 禁止事項

- 禁止事項は `stdoutForbid` 等の「落ちるテスト」で担保（口約束禁止）

### R6: 議決ログ

- 意思決定は `decision-log/*.md` に保存。最低項目: 採用案 / 採用理由 / 影響範囲 / 覆す条件

### R7: 観測の隔離

- stdout に乗らない観測（SSH 経路の実際など）は E2E に隔離

---

## 6. 引き継ぎ事項（Phase-DoD(2) へ）

### 現在のスタブ

| コマンド | 現状 | 次のステップ |
|---------|------|-------------|
| help | 静的出力 `"contracted command: help"` | 実ヘルプシステムへ接続 |
| doctor | check-tools + forbid-scan 実装済み | 実システム診断へ拡張 |
| pick | 静的出力 `"contracted command: pick"` | 実 fzf 選択UIへ接続 |
| ssh | 静的出力 `"contracted command: ssh"` | 実 SSH 処理へ接続 |
| status | 静的出力 `"contracted command: status"` | 実リモート状態取得へ接続 |

### 禁止事項テスト

- **tmux-forbid**: 実装済み（doctor forbid-scan）
- ~~wslinvade-forbid~~: スコープ外（将来フェーズ）

### 回帰資産

- 現在の 6 tests は本実装後も維持。実装変更で FAIL したら設計崩壊のシグナル

---

## 7. コミット履歴（関連）

| コミット | メッセージ | 概要 |
|---------|-----------|------|
| `b027f53` | feat: Phase-DoD(0) complete | U2 実装、tests=6、FREEZE |
| 該当なし | fix: grep options (-rIw --exclude=doctor) | 堅牢化 |
| 該当なし | fix: word boundary (-w) for tmux detection | 誤検知低減 |
| 該当なし | fix: $out → cmd_out variable naming | 変数衝突回避 |

---

## 8. 再現方法

```bash
# 1. タグをチェックアウト
git checkout phase-doD-0-completed

# 2. flake check を実行
nix flake check

# 3. ログが decision-log/phase-0-check.log にあることを確認
cat decision-log/phase-0-check.log
```

---

## 9. 完了定義（DoD）再確認

**Phase-DoD(0) の DoD（完了定義）**:

1. ✅ input-test PASS（spec 入力の必須ファイル存在）
2. ✅ contract-apps PASS（契約と ops/cmd の完全一致）
3. ✅ bb-red PASS（全 6 tests）
4. ✅ REFACTOR 完了（デバッグ除去・命名衝突回避）
5. ✅ FREEZE（タグ・ログ保存）

**次フェーズへの閾値**: 上記すべてが満たされたため、Phase-DoD(2)（本実装接続）へ移行可能。
