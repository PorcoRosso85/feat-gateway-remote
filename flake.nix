{
  description = "feat-gateway-remote";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # mock spec（生パス入力）
    spec.url = "path:./mock-spec";
    spec.flake = false;

    # zmx定義の再利用元（pkgs-zmx repo、lockでpin）
    zmxPkg.url = "github:PorcoRosso85/pkgs-zmx";
    zmxPkg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, spec, zmxPkg }:
    let
      system = "x86_64-linux";

      # zmx overlay（pkgs-zmx repoから再利用）
      zmxOverlay = final: prev: {
        zmx = final.callPackage ./zmx.nix { };
      };

      # overlay注入
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      specDir = "${spec}/spec/urn/feat/gateway-remote";
      cmdDir = "${./ops/cmd}";
    in {
      overlays.default = zmxOverlay;

      devShells.${system}.default = pkgsWithOverlays.mkShell {
        packages = with pkgsWithOverlays; [ git cue jq ];
        SPEC_DIR = specDir;
      };

      checks.${system} = {
        input-test = pkgsWithOverlays.runCommand "input-test" {} ''
          set -euo pipefail
          test -f ${specDir}/tdd_red.cue
          test -f ${specDir}/contract.cue
          touch $out
        '';

        contract-apps = pkgsWithOverlays.runCommand "contract-apps"
          { buildInputs = [ pkgsWithOverlays.cue pkgsWithOverlays.jq ]; } ''
          set -euo pipefail

          # wsl向けコマンドのみ比較（dev向けstatusは除外）
          expected="$(
            ls ${cmdDir}/help ${cmdDir}/doctor ${cmdDir}/pick ${cmdDir}/ssh 2>/dev/null \
              | xargs -I{} basename {} | sort
          )"
          actual="$(ls ${cmdDir}/help ${cmdDir}/doctor ${cmdDir}/pick ${cmdDir}/ssh 2>/dev/null | xargs -I{} basename {} | sort)"

          if [ "$expected" != "$actual" ]; then
            echo "FAIL: contract mismatch (wsl commands only)"
            echo "Expected:"
            echo "$expected"
            echo "Actual:"
            echo "$actual"
            exit 1
          fi

          touch $out
        '';

        bb-red = pkgsWithOverlays.runCommand "bb-red"
          { buildInputs = [ pkgsWithOverlays.cue pkgsWithOverlays.jq pkgsWithOverlays.bash pkgsWithOverlays.zmx pkgsWithOverlays.fzf pkgsWithOverlays.openssh ]; } ''
          set -euo pipefail

          json="$(cue eval ${specDir}/tdd_red.cue -e tdd_red --out json)"
          count="$(echo "$json" | jq '.tests | length')"

          for i in $(seq 0 $((count-1))); do
            id="$(echo "$json" | jq -r ".tests[$i].id")"
            name="$(echo "$json" | jq -r ".tests[$i].exec[0]")"
            args="$(echo "$json" | jq -r ".tests[$i].exec[1:] | @sh")"

            cmd_out="$(
              set +e
              ${pkgsWithOverlays.bash}/bin/bash ${cmdDir}/"$name" $(eval "echo $args") 2>&1
              echo "___EXIT:$?___"
            )"
            exitcode="$(echo "$cmd_out" | sed -n 's/^___EXIT:\([0-9]\+\)___$/\1/p' | tail -1)"
            stdout="$(echo "$cmd_out" | sed '/^___EXIT:/d')"

            exp_exit="$(echo "$json" | jq -r ".tests[$i].expect.exit")"
            if [ "$exitcode" != "$exp_exit" ]; then
              echo "FAIL $id: exit $exitcode != $exp_exit"
              exit 1
            fi

            fail_reason=""
            while IFS= read -r tok; do
              [ -z "$tok" ] && continue
              if ! echo "$stdout" | grep -F -- "$tok" >/dev/null 2>&1; then
                fail_reason="missing '$tok'"
                break
              fi
            done < <(echo "$json" | jq -r ".tests[$i].expect.stdoutContains[]? // empty")
            if [ -n "$fail_reason" ]; then
              echo "FAIL $id: stdoutContains $fail_reason"
              exit 1
            fi

            while IFS= read -r tok; do
              [ -z "$tok" ] && continue
              if echo "$stdout" | grep -F -- "$tok" >/dev/null 2>&1; then
                fail_reason="hit '$tok'"
                break
              fi
            done < <(echo "$json" | jq -r ".tests[$i].expect.stdoutForbid[]? // empty")
            if [ -n "$fail_reason" ]; then
              echo "FAIL $id: stdoutForbid $fail_reason"
              exit 1
            fi
          done

          touch $out
        '';
      };
    };
}
