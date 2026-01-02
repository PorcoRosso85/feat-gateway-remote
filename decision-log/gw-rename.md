# Phase-DoD(0) gw-* rename 証拠

## 日時
2026-01-02

## 背景
- `help` (bash builtin), `ssh` (openssh) との衝突回避のため、コマンド名を `gw-*` プレフィックスに変更

## コミット履歴
```
abfc299 fix: update contract and tests for gw-* command names
c86f29d feat: rename commands to gw-* prefix to avoid conflicts
32875db cmd (original)
phase-doD-0-completed (tag)
```

## flakeが実際にexportするもの outputs（このrepo）
```
$ nix flake show

git+file:///home/nixos/feat-gateway-remote

├── checks
│   └── x86_64-linux
│       ├── bb-red: derivation 'bb-red'
│       ├── contract-apps: derivation 'contract-apps'
│       └── input-test: derivation 'input-test'
├── devShells
│   └── x86_64-linux
│       └── default: development environment 'nix-shell'
├── overlays
│   └── default: Nixpkgs overlay
└── packages
    └── x86_64-linux
        └── gateway-remote: package 'gateway-remote-0.1.0'

# 注意: nixosModules, nixosConfigurations は存在しない
```

## Git情報
- Remote: `git@github.com:PorcoRosso85/feat-gateway-remote.git`
- ブランチ: main
- 最新コミット: `abfc299`

## コマンド一覧
| 対象 | コマンド |
|------|----------|
| wsl | gw-help, gw-doctor, gw-pick, gw-ssh |
| dev | gw-status |

## 導入方法（WSL system flake 側での設定）
```nix
# WSLの system flake (configuration.nix 等)
environment.systemPackages = [
  inputs.feat-gateway-remote.packages.x86_64-linux.gateway-remote
];
```

## 制約事項
- このrepoは `packages` のみexport
- `nixosModules` は提供しない（YAGNI）
- WSL側での `environment.systemPackages` 追加は **別repo（system flake）の責務**
