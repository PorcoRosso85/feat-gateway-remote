package gatewayremote

contract: {
  components: ["wsl-nixos", "dev-nixos"]

  commands: {
    wsl: ["gw-help", "gw-doctor", "gw-pick", "gw-ssh"]
    dev: ["gw-status"]
  }

  wsl: {
    tools: ["fzf", "openssh", "zmx"]
    forbid: ["tmux"]
  }

  windows: {
    wslExe: {
      allowArgs: ["--list", "-l", "--verbose", "-v"]
      denyArgs:  ["-d", "--distribution", "--exec", "-e"]
    }
  }
}
