# spec-repo に gateway-remote URN を追加する段取り

## 日時
2026-01-03

## 背景

feat-gateway-remote repo は mock-spec/ を正本として開発を進めてきたが、  
spec-repo 側で URN を正式に定義し、flake.input として参照する設計に移行する。

---

## 現状確認（Survey Results）

### spec-repo

| 項目 | 現在状態 |
|------|----------|
| Path | `$HOME/spec-repo` |
| ブランチ | `refactor/dev` (HEAD) |
| 関連ブランチ | `feat/add-local-wsl-remote` (2 commits ahead of origin) |
| spec/urn/feat/ | `decide-ci-score-matrix/`, `dx-ux-test/`, `sandboxes/`, `spec/` あり |
| **gateway-remote** | ❌ 未追加 |

### feat-gateway-remote

| 項目 | 現在状態 |
|------|----------|
| mock-spec | `mock-spec/spec/urn/feat/gateway-remote/` に contract.cue, tdd_red.cue あり |
| 責務 | WSL から NixOS remote への gateway 機能を提供 |

---

## 目的（Goal）

spec-repo に `spec/urn/feat/gateway-remote/` を追加し、  
feat-gateway-remote repo の `mock-spec/` を正式な spec-repo 参照に置き換える。

---

## 逆算DoD（3段階）

### DoD-L3（最終成果）

| 項目 | 達成条件 |
|------|----------|
| spec-repo に URN 追加 | `spec/urn/feat/gateway-remote/` が存在し、`contract.cue` を含む |
| flake input 追加 | feat-gateway-remote の `flake.nix` が `spec-repo` を input として参照 |
| merge request | `feat/add-local-wsl-remote` → `refactor/dev` の MR が作成される |

### DoD-L2（中間成果）

| 項目 | 達成条件 |
|------|----------|
| worktree 作成 | `$HOME/spec-repo-worktrees/gateway-remote/` が作成され、`feat/add-local-wsl-remote` を起点とする |
| contract.cue 配置 | `spec/urn/feat/gateway-remote/contract.cue` が既存 contract.cue と同じ形式で作成される |
| コミット | worktree 上でコミット済み |

### DoD-L1（最小健全性）

| 項目 | 達成条件 |
|------|----------|
| 既存 contract.cue 確認 | spec-repo の `spec/urn/feat/spec/contract.cue` を参照し、形式を把握する |
| feat/add-local-wsl-remote 状態確認 | このブランチが何を哪些か確認する |

---

## 実行計画（Task List）

### Phase 1: 準備（確認・調査）

| Task | コマンド/操作 | 期待結果 |
|------|--------------|----------|
| 1-1 | `git -C $HOME/spec-repo checkout feat/add-local-wsl-remote` | ブランチ切换成功 |
| 1-2 | `ls -la spec/urn/feat/feat/` | 既存 URN 形式を確認 |
| 1-3 | `cat spec/urn/feat/spec/contract.cue` | contract.cue 形式を把握 |
| 1-4 | `cat /home/nixos/feat-gateway-remote/mock-spec/spec/urn/feat/gateway-remote/contract.cue` | 比較用（現在地） |

### Phase 2: Worktree 作成

| Task | コマンド/操作 | 期待結果 |
|------|--------------|----------|
| 2-1 | `mkdir -p $HOME/spec-repo-worktrees` | worktree 用ディレクトリ作成 |
| 2-2 | `git -C $HOME/spec-repo worktree add $HOME/spec-repo-worktrees/gateway-remote feat/add-local-wsl-remote` | worktree 作成 |
| 2-3 | `cd $HOME/spec-repo-worktrees/gateway-remote && git status` | 新規 worktree 確認 |

### Phase 3: URN 追加

| Task | コマンド/操作 | 期待結果 |
|------|--------------|----------|
| 3-1 | `mkdir -p spec/urn/feat/gateway-remote` | URN ディレクトリ作成 |
| 3-2 | `cp /home/nixos/feat-gateway-remote/mock-spec/spec/urn/feat/gateway-remote/contract.cue spec/urn/feat/gateway-remote/` | contract.cue コピー |
| 3-3 | `cat spec/urn/feat/gateway-remote/contract.cue` | 確認 |
| 3-4 | `git add spec/urn/feat/gateway-remote/ && git commit -m "feat: add gateway-remote URN with contract.cue"` | コミット |

### Phase 4: feat-gateway-remote で flake input 追加（将来）

| Task | コマンド/操作 | 期待結果 |
|------|--------------|----------|
| 4-1 | `git -C $HOME/feat-gateway-remote remote add spec-repo $HOME/spec-repo` | remote 追加（または確認） |
| 4-2 | `git -C $HOME/feat-gateway-remote fetch spec-repo` | fetch |
| 4-3 | `git -C $HOME/feat-gateway-remote branch -a` | branch 確認 |

### Phase 5: MR 作成（GitHub）

| Task | 操作 |
|------|------|
| 5-1 | GitHub で `feat/add-local-wsl-remote` → `refactor/dev` の MR を作成 |
| 5-2 | タイトル: `feat: add gateway-remote URN (spec/urn/feat/gateway-remote)` |
| 5-3 | 説明: 現状の `mock-spec/` を spec-repo 公式に移行 |

---

## ファイル構成（完成形）

```
spec-repo/
├── spec/
│   └── urn/
│       └── feat/
│           ├── gateway-remote/          # NEW
│           │   └── contract.cue
│           ├── spec/
│           │   └── contract.cue          # 形式参考
│           ├── decide-ci-score-matrix/
│           ├── dx-ux-test/
│           └── sandboxes/
└── ...（既存）
```

---

## 確認質問（最小）

1. **contract.cue は `mock-spec/` からそのままコピーして良いか？**  
   → 形式・内容が同一なら OK

2. **spec-repo の `refactor/dev` ブランチに直接コミットして良いか？**  
   → `feat/add-local-wsl-remote` ブランチを経由（worktree）で MR を作成方向で良いか？

3. **追加で必要な spec ファイルはあるか？**  
   → `tdd_red.cue` も移行するか？（今回は contract.cue だけで良いか？）

---

## ステータス

| Phase | ステータス |
|-------|----------|
| Phase 1: 準備 | ⏳ 未着手 |
| Phase 2: Worktree | ⏳ 未着手 |
| Phase 3: URN追加 | ⏳ 未着手 |
| Phase 4: flake input | ⏳ 未着手 |
| Phase 5: MR作成 | ⏳ 未着手 |
