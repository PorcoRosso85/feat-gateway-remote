# E2E Smoke Test Plan (Local sshd)

## Goal

DoD-L3 証拠を取得するため、ローカル環境で sshd を起動し E2E テストを実施する。

## DoD-L3 証拠要件

| # | 項目 | 証拠 |
|---|------|------|
| 1 | gw-pick 実行 | 実行ログ |
| 2 | SSH 接続確立 | 実行ログ |
| 3 | ProxyJump/ProxyCommand 禁止 | コード確認 (`-o ProxyJump=none -o ProxyCommand=none`) |
| 4 | RemoteCommand で zmx attach | remote 側の実行ログ |

## 前提条件

- `sshd` がシステムにインストールされている
- `zmx` が NixOS 上で利用可能な状態にある
- `gw-*` コマンドが `nix run` または `nix develop` で実行可能

## 手順

### Step 1: テスト用ユーザーと SSH 鍵の作成

```bash
# テストユーザー作成
sudo useradd -m testuser 2>/dev/null || true

# SSH 鍵作成
sudo mkdir -p /home/testuser/.ssh
sudo ssh-keygen -t ed25519 -f /home/testuser/.ssh/id_ed25519 -N ""
sudo chmod 700 /home/testuser/.ssh
sudo chmod 600 /home/testuser/.ssh/id_ed25519
sudo chmod 644 /home/testuser/.ssh/id_ed25519.pub
sudo chown -R testuser:testuser /home/testuser/.ssh

# authorized_keys に公開鍵追加
sudo cat /home/testuser/.ssh/id_ed25519.pub >> /home/testuser/.ssh/authorized_keys
sudo chmod 600 /home/testuser/.ssh/authorized_keys
```

### Step 2: sshd の設定と起動

```bash
# sshd_config 作成（簡易設定）
sudo mkdir -p /run/sshd
echo "Port 2222
ListenAddress 127.0.0.1
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
Subsystem sftp /run/current-system/sw/lib/ssh/sftp-server" | sudo tee /etc/ssh/sshd_config_test

# sshd 起動
sudo /run/current-system/sw/bin/sshd -f /etc/ssh/sshd_config_test

# 起動確認
sudo ss -tlnp | grep 2222
```

### Step 3: ~/.ssh/config に localhost 設定追加

```bash
# ~/.ssh/config に localhost 追加
cat << 'EOF' >> ~/.ssh/config

Host localhost-test
    HostName 127.0.0.1
    Port 2222
    User testuser
    IdentityFile /home/testuser/.ssh/id_ed25519
    StrictHostKeyChecking=no
    UserKnownHostsFile=/dev/null
EOF
```

### Step 4: gw-doctor 実行（事前チェック）

```bash
# ツール確認
nix run github:PorcoRosso85/feat-gateway-remote#gw-doctor check-tools

# 鍵健全性確認
nix run github:PorcoRosso85/feat-gateway-remote#gw-doctor key-check /home/testuser/.ssh/id_ed25519
```

### Step 5: E2E テスト実行

```bash
#!/bin/bash
set -euo pipefail

LOG_DIR="./e2e-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "=== E2E Smoke Test ===" | tee "$LOG_DIR/test.log"
echo "Timestamp: $(date)" | tee -a "$LOG_DIR/test.log"

# gw-pick 実行（localhost-test を選択）
echo "" | tee -a "$LOG_DIR/test.log"
echo "=== Step 1: gw-pick ===" | tee -a "$LOG_DIR/test.log"
echo "localhost-test" | nix run github:PorcoRosso85/feat-gateway-remote#gw-pick 2>&1 | tee -a "$LOG_DIR/test.log"
SELECTED_HOST=$(cat "$LOG_DIR/gw-pick-output" 2>/dev/null || echo "localhost-test")
echo "Selected: $SELECTED_HOST" | tee -a "$LOG_DIR/test.log"

# gw-ssh 実行（RemoteCommand で zmx session を作成）
echo "" | tee -a "$LOG_DIR/test.log"
echo "=== Step 2: gw-ssh ===" | tee -a "$LOG_DIR/test.log"
echo "echo 'E2E test completed successfully'" | nix run github:PorcoRosso85/feat-gateway-remote#gw-ssh "$SELECTED_HOST" 2>&1 | tee -a "$LOG_DIR/test.log"

echo "" | tee -a "$LOG_DIR/test.log"
echo "=== Test Complete ===" | tee -a "$LOG_DIR/test.log"
echo "Logs saved to: $LOG_DIR"
```

### Step 6: 証拠の確認

```bash
# ProxyJump/ProxyCommand 禁止の確認
grep -n "ProxyJump=none" ops/cmd/gw-ssh
grep -n "ProxyCommand=none" ops/cmd/gw-ssh

# RemoteCommand zmx attach の確認
grep -n "zmx" ops/cmd/gw-ssh
```

## 期待結果

1. `gw-doctor check-tools` が正常終了（fzf, ssh が見つかる）
2. `gw-doctor key-check` が正常終了（鍵が健全）
3. `gw-pick` が localhost-test を選択可能
4. `gw-ssh` が SSH 接続を確立
5. RemoteCommand で zmx attach が実行される（zmx session が作成される）

## クリーンアップ

```bash
# sshd 停止
sudo pkill sshd || true
sudo rm -rf /run/sshd

# テストユーザー削除
sudo userdel testuser 2>/dev/null || true

# ~/.ssh/config から localhost-test エントリを削除
sed -i '/# BEGIN localhost-test/,/# END localhost-test/d' ~/.ssh/config
```

## 実行コマンド（ワンライン）

```bash
# 完全自動化スクリプト
bash << 'EOF'
set -euo pipefail

# クリーンアップ関数
cleanup() {
    sudo pkill sshd 2>/dev/null || true
    sudo rm -rf /run/sshd 2>/dev/null || true
    sudo userdel testuser 2>/dev/null || true
}
trap cleanup EXIT

# Step 1: ユーザーと鍵作成
sudo useradd -m testuser 2>/dev/null || true
sudo mkdir -p /home/testuser/.ssh
sudo ssh-keygen -t ed25519 -f /home/testuser/.ssh/id_ed25519 -N "" -q
sudo chmod 700 /home/testuser/.ssh
sudo chmod 600 /home/testuser/.ssh/id_ed25519
sudo chown -R testuser:testuser /home/testuser/.ssh
cat /home/testuser/.ssh/id_ed25519.pub >> /home/testuser/.ssh/authorized_keys

# Step 2: sshd 起動
sudo mkdir -p /run/sshd
sudo tee /etc/ssh/sshd_config_test > /dev/null << 'SHD'
Port 2222
ListenAddress 127.0.0.1
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
SHD
sudo /run/current-system/sw/bin/sshd -f /etc/ssh/sshd_config_test

# Step 3: ssh config
cat << 'SSH' >> ~/.ssh/config

Host localhost-test
    HostName 127.0.0.1
    Port 2222
    User testuser
    IdentityFile /home/testuser/.ssh/id_ed25519
    StrictHostKeyChecking=no
    UserKnownHostsFile=/dev/null
SSH

# Step 4: E2E テスト
echo "=== E2E Smoke Test ==="
echo "1. Running gw-doctor check-tools..."
nix run github:PorcoRosso85/feat-gateway-remote#gw-doctor check-tools

echo "2. Running gw-doctor key-check..."
nix run github:PorcoRosso85/feat-gateway-remote#gw-doctor key-check /home/testuser/.ssh/id_ed25519

echo "3. Running gw-pick..."
echo "localhost-test" | nix run github:PorcoRosso85/feat-gateway-remote#gw-pick

echo "4. Running gw-ssh..."
echo "echo 'E2E test passed'" | nix run github:PorcoRosso85/feat-gateway-remote#gw-ssh localhost-test

echo "=== All tests passed ==="
EOF
```

## 備考

- ローカルテストのため、RemoteCommand zmx attach は「zmx session が作成される」まで確認
- 本番環境では remote 側で `zmx attach` のログを確認
- `zmx` が NixOS 上で正しく動作することを確認が必要
