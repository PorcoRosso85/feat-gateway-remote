package gatewayremote

contract: {
  components: ["wsl-nixos", "dev-nixos"]

  commands: {
    wsl: ["help", "doctor", "pick", "ssh"]
    dev: ["status"]
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
