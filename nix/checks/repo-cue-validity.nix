{
  self,
  checksAttrNames,
  system,
  nixpkgs,
}:

let
  pkgs = nixpkgs.legacyPackages.${system};
in

pkgs.runCommand "repo-cue-validity"
  {
    buildInputs = [ pkgs.jq ];
    checksJson = pkgs.writeText "checks.json" (builtins.toJSON checksAttrNames);
  }
  ''
    set -euo pipefail
    cd ${self}

    echo "🔍 repo-cue-validity check"
    echo ""

    # 1. repo.cue exists
    echo "→ Checking repo.cue exists..."
    if [ ! -f "./repo.cue" ]; then
      echo "❌ FAIL: repo.cue not found"
      exit 1
    fi
    echo "✅ repo.cue exists"
    echo ""

    # 2. Extract requiredChecks from repo.cue
    echo "→ Extracting requiredChecks..."
    REQUIRED_CHECKS=$(grep -oP '^\s+"\K[^"]+(?="\s*$)' ./repo.cue | grep -v '^$' | grep -v 'inputsRefs' | head -20 || echo "")

    if [ -z "$REQUIRED_CHECKS" ]; then
      echo "❌ FAIL: repo.requiredChecks not found or empty"
      exit 1
    fi

    echo "Found $(echo "$REQUIRED_CHECKS" | wc -l) required checks"
    echo ""

    # 3. Check for duplicates
    echo "→ Checking for duplicates..."
    DUPLICATES=$(echo "$REQUIRED_CHECKS" | sort | uniq -d)
    if [ -n "$DUPLICATES" ]; then
      echo "❌ FAIL: Duplicate checks found"
      exit 1
    fi
    echo "✅ No duplicates"
    echo ""

    # 4. Get flake checks
    echo "→ Getting flake checks..."
    FLAKE_CHECKS=$(cat "$checksJson" | jq -r '.[]' 2>/dev/null | sort -u || echo "")
    echo "Found $(echo "$FLAKE_CHECKS" | wc -l) flake checks"
    echo ""

    # 5. Verify requiredChecks in flake
    echo "→ Verifying requiredChecks..."
    MISSING=""
    for check in $REQUIRED_CHECKS; do
      if ! echo "$FLAKE_CHECKS" | grep -qx "$check"; then
        MISSING="$MISSING$check "
        echo "  ❌ Missing: $check"
      fi
    done

    if [ -n "$MISSING" ]; then
      echo ""
      echo "❌ FAIL: Required checks not in flake"
      exit 1
    fi
    echo "✅ All required checks found"
    echo ""

    # 6. Check inputsRefs paths
    echo "→ Checking inputsRefs..."
    INPUTS_REFS=$(grep -A 100 'inputsRefs:' ./repo.cue 2>/dev/null | grep -oP '^\s+"\K[^"]+(?="\s*$)' | head -10 || echo "")

    for ref in $INPUTS_REFS; do
      if [[ "$ref" == *:* ]]; then
        echo "  📎 Input ref (structural): $ref"
      elif [ -e "$ref" ]; then
        echo "  ✅ Ref exists: $ref"
      else
        echo "  ⚠️  Ref not found (may be external): $ref"
      fi
    done
    echo ""

    echo "✅ repo-cue-validity PASS"
    mkdir -p $out && echo "ok" > $out/result
  ''
