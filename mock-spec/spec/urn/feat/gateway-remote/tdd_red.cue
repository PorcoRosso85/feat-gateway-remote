package gatewayremote

tdd_red: {
  tests: [
    {
      id: "gw-help"
      exec: ["gw-help"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: gw-help"]
        stdoutForbid: []
      }
    },
    {
      id: "gw-doctor-tools"
      exec: ["gw-doctor", "check-tools"]
      expect: {
        exit: 0
        stdoutContains: ["All required tools available"]
        stdoutForbid: []
      }
    },
    {
      id: "gw-pick"
      exec: ["gw-pick"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: gw-pick"]
        stdoutForbid: []
      }
    },
    {
      id: "gw-ssh-direct-only"
      exec: ["gw-ssh"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: gw-ssh"]
        stdoutForbid: ["ProxyJump", "-J", "JumpHost"]
      }
    },
    {
      id: "gw-status"
      exec: ["gw-status"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: gw-status"]
        stdoutForbid: []
      }
    },
    {
      id: "forbid-scan"
      exec: ["gw-doctor", "forbid-scan"]
      expect: {
        exit: 0
        stdoutContains: ["OK:"]
        stdoutForbid: ["FAIL"]
      }
    }
  ]
}
