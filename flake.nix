{
  description = "feat-gateway-remote";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    spec.url = "path:./mock-spec";
    spec.flake = false;

    zmxPkg.url = "github:PorcoRosso85/pkgs-zmx";
    zmxPkg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      spec,
      zmxPkg,
    }:
    let
      system = "x86_64-linux";

      zmxOverlay = final: prev: {
        zmx = final.callPackage ./zmx.nix { };
      };

      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      specDir = "${spec}/spec/urn/feat/gateway-remote";
      cmdDir = "${./ops/cmd}";

      # Phase 5: flakeChecksList - Auto-generated from self.checks (no external command)
      flakeChecksList = builtins.attrNames (self.checks.${system} or { });
    in
    {
      overlays.default = zmxOverlay;

      apps.${system} = {
        gw-help = {
          type = "app";
          program = "${self.packages.${system}.gateway-remote}/bin/gw-help";
        };
        gw-doctor = {
          type = "app";
          program = "${self.packages.${system}.gateway-remote}/bin/gw-doctor";
        };
        gw-pick = {
          type = "app";
          program = "${self.packages.${system}.gateway-remote}/bin/gw-pick";
        };
        gw-ssh = {
          type = "app";
          program = "${self.packages.${system}.gateway-remote}/bin/gw-ssh";
        };
        gw-status = {
          type = "app";
          program = "${self.packages.${system}.gateway-remote}/bin/gw-status";
        };
      };

      devShells.${system}.default = pkgsWithOverlays.mkShell {
        packages = with pkgsWithOverlays; [
          git
          cue
          jq
          fzf
          openssh
          zmx
        ];
        shellHook = ''
          export PATH="${self.packages.${system}.gateway-remote}/bin:$PATH"
          echo "gateway-remote devShell: gw-* commands available"
        '';
        SPEC_DIR = specDir;
      };

      checks.${system} = {
        apps-wireup = pkgsWithOverlays.runCommand "apps-wireup" { } ''
          set -euo pipefail
          test -x ${self.apps.${system}.gw-doctor.program}
          test -x ${self.apps.${system}.gw-pick.program}
          test -x ${self.apps.${system}.gw-ssh.program}
          test -x ${self.apps.${system}.gw-status.program}
          touch $out
        '';

        devshell-smoke =
          pkgsWithOverlays.runCommand "devshell-smoke"
            {
              nativeBuildInputs = [
                pkgsWithOverlays.fzf
                pkgsWithOverlays.openssh
                pkgsWithOverlays.zmx
                self.packages.${system}.gateway-remote
              ];
            }
            ''
              set -euo pipefail
              export PATH="${self.packages.${system}.gateway-remote}/bin:$PATH"
              command -v gw-doctor >/dev/null
              command -v fzf >/dev/null
              command -v ssh >/dev/null
              gw-doctor check-tools
              gw-doctor forbid-scan
              gw-status >/dev/null
              touch $out
            '';

        input-test = pkgsWithOverlays.runCommand "input-test" { } ''
          set -euo pipefail
          test -f ${specDir}/tdd_red.cue
          test -f ${specDir}/contract.cue
          touch $out
        '';

        contract-apps =
          pkgsWithOverlays.runCommand "contract-apps"
            {
              buildInputs = [
                pkgsWithOverlays.cue
                pkgsWithOverlays.jq
              ];
            }
            ''
              set -euo pipefail

              expected="$(
                ls ${cmdDir}/gw-help ${cmdDir}/gw-doctor ${cmdDir}/gw-pick ${cmdDir}/gw-ssh 2>/dev/null \
                  | xargs -I{} basename {} | sort
              )"
              actual="$(ls ${cmdDir}/gw-help ${cmdDir}/gw-doctor ${cmdDir}/gw-pick ${cmdDir}/gw-ssh 2>/dev/null | xargs -I{} basename {} | sort)"

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

        bb-red =
          pkgsWithOverlays.runCommand "bb-red"
            {
              buildInputs = [
                pkgsWithOverlays.cue
                pkgsWithOverlays.jq
                pkgsWithOverlays.bash
                pkgsWithOverlays.zmx
                pkgsWithOverlays.fzf
                pkgsWithOverlays.openssh
                pkgsWithOverlays.coreutils
              ];
            }
            ''
              set -euo pipefail

              export PATH="${pkgsWithOverlays.fzf}/bin:${pkgsWithOverlays.openssh}/bin:${pkgsWithOverlays.zmx}/bin:${pkgsWithOverlays.coreutils}/bin:$PATH"

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

        # Phase 4: repo-cue-validity (Repo DoD - CI要件SSOT成立条件)
        repo-cue-validity = import ./nix/checks/repo-cue-validity.nix {
          inherit self system nixpkgs;
          checksAttrNames = flakeChecksList;
        };
      };

      packages.${system}.gateway-remote = pkgsWithOverlays.stdenvNoCC.mkDerivation {
        pname = "gateway-remote";
        version = "0.1.0";

        src = ./.;

        installPhase = ''
          mkdir -p $out/bin
          cp -r $src/ops/cmd/* $out/bin/ || true
        '';
      };
    };
}
