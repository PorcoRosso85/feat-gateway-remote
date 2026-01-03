# gw-ssh インターフェース仕様（確定）

## 日時
2026-01-03

## 確定事項

### インターフェース

```bash
gw-ssh [user@]host
```

- host のみを受け取る
- command 引数は受け取らない（常に remote 側の zmx attach を使う）

### SSH オプション

```bash
ssh -o ProxyJump=none -o ProxyCommand=none [user@]host
```

- `ProxyJump=none`: ProxyJump を無効化
- `ProxyCommand=none`: ProxyCommand を無効化（OpenSSH 標準）

### 背景

- `JumpHost=none` は OpenSSH 標準ではない（環境によって未知オプションで落ちるリスク）
- `RemoteCommand` と `gw-ssh [command]` が衝突し得るため、command 引数は受け取らない設計に確定

## 根拠

- OpenBSD ssh_config(5) には `JumpHost` の記載がない
- `ProxyJump` と `ProxyCommand` でジャンプ禁止を表現するのが確実

## コミット

- `c564054` fix: gw-ssh uses ProxyCommand=none (not JumpHost) and removes command arg
