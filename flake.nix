{
  description = "feat-gateway-remote";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # mock spec（生パス入力）
    spec.url = "path:./mock-spec";
    spec.flake = false;

    # zmx定義の再利用元（GitHub参照、lockでpin）
    home.url = "github:PorcoRosso85/home";
    home.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, spec, home }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # zmx overlay（home repoから再利用）
      zmxOverlay = final: prev: {
        zmx = final.callPackage "${home}/.os/hosts/nixos-vm/zmx.nix" { };
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

      checks.${system}.input-test = pkgsWithOverlays.runCommand "input-test" {} ''
        set -euo pipefail
        test -f ${specDir}/tdd_red.cue
        test -f ${specDir}/contract.cue
        touch $out
      '';

      checks.${system}.contract-apps = pkgsWithOverlays.runCommand "contract-apps"
        { buildInputs = [ pkgsWithOverlays.cue pkgsWithOverlays.jq ]; } ''
        set -euo pipefail

        expected="$(
          cue eval ${specDir}/contract.cue -e contract.commands.wsl --out json \
            | jq -r '.[]' | sort
        )"
        actual="$(ls ${cmdDir} | sort)"

        if [ "$expected" != "$actual" ]; then
          echo "FAIL: contract mismatch"
          echo "Expected:"
          echo "$expected"
          echo "Actual:"
          echo "$actual"
          exit 1
        fi

        touch $out
      '';

      checks.${system}.bb-red = pkgsWithOverlays.runCommand "bb-red"
        { buildInputs = [ pkgsWithOverlays.cue pkgsWithOverlays.jq pkgsWithOverlays.bash pkgs.zmx pkgs.fzf pkgs.openssh ]; } ''
        set -euo pipefail

        json="$(cue eval ${specDir}/tdd_red.cue -e tdd_red --out json)"
        count="$(echo "$json" | jq '.tests | length')"

        for i in $(seq 0 $((count-1))); do
          id="$(echo "$json" | jq -r ".tests[$i].id")"
          name="$(echo "$json" | jq -r ".tests[$i].exec[0]")"

          args="$(echo "$json" | jq -r ".tests[$i].exec[1:] | @sh")"

          out="$(
            set +e
            ${pkgsWithOverlays.bash}/bin/bash ${cmdDir}/"$name" $(eval "echo $args") 2>&1
            echo "___EXIT:$?___"
          )"
          exitcode="$(echo "$out" | sed -n 's/^___EXIT:\([0-9]\+\)___$/\1/p' | tail -1)"
          stdout="$(echo "$out" | sed '/^___EXIT:/d')"

          exp_exit="$(echo "$json" | jq -r ".tests[$i].expect.exit")"
          [ "$exitcode" = "$exp_exit" ] || { echo "FAIL $id: exit $exitcode != $exp_exit"; exit 1; }

          echo "$json" | jq -r ".tests[$i].expect.stdoutContains[]? // empty" | while read -r tok; do
            echo "$stdout" | grep -F -- "$tok" >/dev/null || { echo "FAIL $id: missing $tok"; exit 1; }
          done

          echo "$json" | jq -r ".tests[$i].expect.stdoutForbid[]? // empty" | while read -r tok; do
            echo "$stdout" | grep -F -- "$tok" >/dev/null && { echo "FAIL $id: forbid hit $tok"; exit 1; }
          done
        done

        touch $out
      '';
    };
}
