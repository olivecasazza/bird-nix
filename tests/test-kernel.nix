# test-kernel.nix — Unit tests for bird-nix.nix tagged union kernel
# and bird-toolchain.nix integration

{ }:
let
  h = import ./test-harness.nix {};
  bn = import ../src {};
  rw = import ./real-world-birds.nix {};

  # Suite 1: Tagged Birds Structure
  suiteTaggedBirds = h.runSuite "Tagged Birds Structure" [
    (h.assertEq "bn.kernel.I.bird == \"I\"" bn.kernel.I.bird "I")
    (h.assertEq "bn.kernel.K.bird == \"K\"" bn.kernel.K.bird "K")
    (h.assertEq "bn.kernel.M.bird == \"M\"" bn.kernel.M.bird "M")
    (h.assertEq "bn.kernel.C.bird == \"C\"" bn.kernel.C.bird "C")
    (h.assertEq "bn.kernel.V.bird == \"V\"" bn.kernel.V.bird "V")
    (h.assertTrue "bn.kernel.I has .apply" (builtins.isFunction bn.kernel.I.apply))
    (h.assertTrue "bn.kernel.K has .apply" (builtins.isFunction bn.kernel.K.apply))
    (h.assertTrue "bn.kernel.M has .apply" (builtins.isFunction bn.kernel.M.apply))
    (h.assertTrue "bn.kernel.C has .apply" (builtins.isFunction bn.kernel.C.apply))
    (h.assertTrue "bn.kernel.V has .apply" (builtins.isFunction bn.kernel.V.apply))
  ];

  # Suite 2: Tagged Bird Apply
  suiteApply = h.runSuite "Tagged Bird Apply" [
    (h.assertEq "bn.kernel.apply bn.kernel.I \"hello\"" (bn.kernel.apply bn.kernel.I "hello") "hello")
    (h.assertEq "bn.kernel.apply (bn.kernel.apply bn.kernel.K \"yes\") \"no\"" (bn.kernel.apply (bn.kernel.apply bn.kernel.K "yes") "no") "yes")
    (h.assertEq "bn.kernel.apply (bn.kernel.apply bn.kernel.KI \"yes\") \"no\"" (bn.kernel.apply (bn.kernel.apply bn.kernel.KI "yes") "no") "no")
    (h.assertEq "S K K = I" (bn.kernel.apply (bn.kernel.apply (bn.kernel.apply bn.kernel.S bn.kernel.K) bn.kernel.K) "test") "test")
    (h.assertEq "C K flips" (bn.kernel.apply (bn.kernel.apply (bn.kernel.apply bn.kernel.C bn.kernel.K) "a") "b") "b")
    (h.assertEq "V pair with K" (bn.kernel.apply (bn.kernel.apply (bn.kernel.apply bn.kernel.V "a") "b") bn.kernel.K) "a")
  ];

  # Suite 3: show function
  suiteShow = h.runSuite "show function" [
    (h.assertTrue "bn.kernel.show bn.kernel.I returns a string" (builtins.isString (bn.kernel.show bn.kernel.I)))
  ];

  # Suite 4: Kernel examples
  suiteExamples = h.runSuite "Kernel examples" [
    (h.assertEq "bn.kernel.examples.identity" bn.kernel.examples.identity "hello")
    (h.assertEq "bn.kernel.examples.kestrelChoice" bn.kernel.examples.kestrelChoice "yes")
  ];

  # Suite 5: Toolchain Type Check
  suiteTypeCheck = h.runSuite "Toolchain Type Check" [
    (let
      result = bn.typeCheck "I";
    in h.assertEq "bn.typeCheck \"I\" ok" result.ok true)
    (let
      result = bn.typeCheck "I";
    in h.assertEq "bn.typeCheck \"I\" type" result.type "a -> a")
    (let
      result = bn.typeCheck "K";
    in h.assertTrue "bn.typeCheck \"K\" ok" result.ok)
    (let
      result = bn.typeCheck "C";
    in h.assertTrue "bn.typeCheck \"C\" ok" result.ok)
    (let
      result = bn.typeCheck "V";
    in h.assertTrue "bn.typeCheck \"V\" ok" result.ok)
    (let
      result = bn.typeCheck "UNKNOWN";
    in h.assertFalse "bn.typeCheck \"UNKNOWN\" ok" result.ok)
  ];

  # Suite 6: Toolchain Config Example
  suiteConfig = h.runSuite "Toolchain Config Example" [
    (h.assertEq "bn.toolchain.configExample.serverName" bn.toolchain.configExample.serverName "example.com")
    (h.assertEq "bn.toolchain.configExample.port" bn.toolchain.configExample.port 8080)
    (h.assertEq "bn.toolchain.configExample.selfRef" bn.toolchain.configExample.selfRef "nginx")
  ];

  # Suite 7: Toolchain Demos
  suiteDemos = h.runSuite "Toolchain Demos" [
    (h.assertEq "bn.toolchain.demos.sKK.test" bn.toolchain.demos.sKK.test "hello")
    (h.assertTrue "bn.toolchain.demos.sKK.pretty is a string" (builtins.isString bn.toolchain.demos.sKK.pretty))
  ];

  # Suite 8: Real World Examples
  suiteRealWorld = h.runSuite "Real World Examples" [
    (h.assertEq "rw.selectedConfig.port" rw.selectedConfig.port 80)
    (h.assertEq "rw.selectedConfig.debug" rw.selectedConfig.debug false)
    (h.assertTrue "rw.isPalindrome \"anything\"" (rw.isPalindrome "anything"))
    (h.assertTrue "rw.hasMinLength 3 \"hello\"" (rw.hasMinLength 3 "hello"))
    (h.assertFalse "rw.hasMinLength 10 \"hi\"" (rw.hasMinLength 10 "hi"))
    (h.assertEq "rw.selfAware \"test\" name" (rw.selfAware "test").name "test")
    (h.assertEq "rw.selfAware \"test\" description" (rw.selfAware "test").description "I am test")
  ];

in
  h.combineSuites "Bird-Nix Kernel Tests" [
    suiteTaggedBirds
    suiteApply
    suiteShow
    suiteExamples
    suiteTypeCheck
    suiteConfig
    suiteDemos
    suiteRealWorld
  ]
