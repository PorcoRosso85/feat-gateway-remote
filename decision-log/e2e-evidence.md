# E2E 証拠記録（2026-01-03）

## 取得済み証拠

### (1) gw-pick 実行（non-interactive）

```bash
$ nix develop github:PorcoRosso85/feat-gateway-remote --command bash -c 'gw-pick'
contracted command: gw-pick (uses fzf)
Usage: gw-pick [options]
...
Available hosts from ~/.ssh/config:
（~/.ssh/config が空の場合は表示されない）
```

### (2) gw-ssh help 出力

```bash
$ nix develop github:PorcoRosso85/feat-gateway-remote --command bash -c 'gw-ssh --help'
contracted command: gw-ssh
Usage: gw-ssh [user@]host

Options:
  --help     Show this help

Note: Direct connection only. Jump/Proxy methods are prohibited.
```

### (3) ジャンプ禁止オプション（コードレビュー）

```bash
$ grep -n "ProxyJump\|ProxyCommand" ops/cmd/gw-ssh
exec ssh -o ProxyJump=none -o ProxyCommand=none "$HOST"
```

### (4) zmx attach（未検証）

**条件:**
- 接続可能な remote host が必要
- remote で zmx が動く必要あり

**次回 E2E で検証:**
```bash
# WSL
gw-pick  # または gw-ssh user@host

# remote (ssh 接続後)
zmx list
```

---

## 未完了事項

| # | 項目 | 条件 |
|---|------|------|
| (2) | SSH 接続確立 | 接続可能な remote host が必要 |
| (4) | zmx attach に入る | remote で zmx が動く必要あり |

---

## 必要な設定（次回 E2E 向け）

~/.ssh/config に接続先を設定:

```ssh-config
Host my-remote
    HostName remote.example.com
    User username
    RemoteCommand zmx attach my-session || zmx run my-session
    RequestTTY force
```

または remote 側で zmx を自動 attach する設定を事先に行う。
