// feat-gateway-remote: CI要件SSOTの正本
// - spec-repoのdeliverablesを参照
// - ここにCI要件を書く（flake checksは具現）

repo: {
  // CI必須チェック一覧（flake.checks と対照）
  // 6項目: 既存5 + repo-cue-validity
  requiredChecks: [
    // 既存チェック
    "apps-wireup"
    "devshell-smoke"
    "input-test"
    "contract-apps"
    "bb-red"
    // Repo DoD（LEVEL3 - CI要件SSOT成立条件）
    "repo-cue-validity"
  ]

  // spec-repo deliverablesへの参照（repo相対パス）
  inputsRefs: [
    "mock-spec/spec/urn/feat/gateway-remote"  // 自URN
    "mock-spec/spec/ci/contract"              // 契約
    "mock-spec/spec/ci/tdd"                   // TDD
    "mock-spec/spec/ci/fixtures"              // フィクスチャ
  ]
}
