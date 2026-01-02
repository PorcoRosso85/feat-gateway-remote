# gw-pick zmx 統合記録

## 日時
2026-01-02

## 実装内容

### gw-pick の機能
1. `zmx list` で既存セッションを取得
2. fzf でセッション選択、または新規接続を選択
3. 選択に応じて `zmx attach` または `zmx run` を実行

### 設計理由
- zmx は「セッション継続」ツール
- gw-pick は「セッション選択/作成」インターフェースを提供
- 接続先ホスト情報は zmx で管理（セッション名がホスト識別子として機能）

## コミット
- `fbe899c` feat: integrate zmx sessions into gw-pick
