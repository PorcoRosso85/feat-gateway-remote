# repo-cue-validity: inputsRefs 扱い方針

## 日時
2026-01-02

## 方針（確定）

`repo.cue` の `inputsRefs` は **補助情報** であり、欠損しても CI を FAIL にしない。

## 理由

- `inputsRefs` は「参照可能なリソース」へのポインタ
- 外部リソース（GitHub etc.）や将来追加されるリソースへの参照を含む可能性がある
- これらを「必須」にすると、CI の成否が参照先 disponibilidad に依存してしまう

## 実装

`nix/checks/repo-cue-validity.nix` では以下のように実装：

```bash
# 存在確認のみ。欠損は警告でFAILにしない
for ref in $INPUTS_REFS; do
  if [[ "$ref" == *:* ]]; then
    echo "  📎 Input ref (structural): $ref"
  elif [ -e "$ref" ]; then
    echo "  ✅ Ref exists: $ref"
  else
    echo "  ⚠️  Ref not found (may be external): $ref"
  fi
done
```

## コミット
- `597c029` fix: repo-cue-validity script robustness
