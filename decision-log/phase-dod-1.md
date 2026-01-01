# Phase-DoD(1) 議決ログ

## 採用案

**C: mock-spec を正本として固定**

## 採用理由

1. **spec-repo に gateway-remote が存在しない**
   - `nix flake show github:PorcoRosso85/spec` で `spec/urn/feat/gateway-remote` を確認 → 404

2. **spec-repo への追加（案A/B）は spec 側変更が必要**
   - 現フェーズでは spec-repo を触らない運用方針
   - 後続フェーズで回帰テスト資産を使って安全に統合可能

3. **mock-spec で当面進めるのが最短**
   - Phase-DoD(0) が完成しており、回帰資産として再利用可
   - 本実装接続（Phase-DoD(2)）へ直接進められる

## 影響範囲

| 項目 | 影響 |
|-----|-----|
| flake.nix | `inputs.spec.url = "path:./mock-spec"` を維持（本物spec差し替えは将来） |
| テスト資産 | mock-spec/*.cue を当面の正本として bb-red が参照 |
| 統合コスト | 後続フェーズで spec-repo へ昇格時に、回帰テストで壊れ箇所を検出可能 |

## 覆す条件

- spec-repo に `spec/urn/feat/gateway-remote` が追加された場合 → 案 A/B へ移行検討
- mock-spec の維持コストが回帰コストを上回った場合 → 再評価

## 採用日

2026-01-01
