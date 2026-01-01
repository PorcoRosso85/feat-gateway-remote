package gatewayremote

tdd_red: {
  tests: [
    {
      id: "help"
      exec: ["help"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: help"]
        stdoutForbid: []
      }
    },
    {
      id: "doctor-tools"
      exec: ["doctor", "check-tools"]
      expect: {
        exit: 0
        stdoutContains: ["All required tools available"]
        stdoutForbid: []
      }
    },
    {
      id: "pick"
      exec: ["pick"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: pick"]
        stdoutForbid: []
      }
    },
    {
      id: "ssh-direct-only"
      exec: ["ssh"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: ssh"]
        stdoutForbid: ["ProxyJump", "-J", "JumpHost"]
      }
    },
    {
      id: "status"
      exec: ["status"]
      expect: {
        exit: 0
        stdoutContains: ["contracted command: status"]
        stdoutForbid: []
      }
    },
    {
      id: "forbid-scan"
      exec: ["doctor", "forbid-scan"]
      expect: {
        exit: 0
        stdoutContains: ["OK:"]
        stdoutForbid: ["FAIL"]
      }
    }
  ]
}
