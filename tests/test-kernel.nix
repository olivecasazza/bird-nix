# test-kernel.nix — Unit tests for bird-nix.nix tagged union kernel
# and bird-toolchain.nix integration

{ }:
let
  h = import ../src/testing/test-harness.nix {};
  k = import ../src/bird-nix.nix {};
  tc = import ../src/bird-toolchain.nix {};
  rw = import ../src/real-world-birds.nix {};

  # Suite 1: Tagged Birds Structure
  suiteTaggedBirds = h.runSuite "Tagged Birds Structure" [
    (h.assertEq "k.I.bird == \"I\"" k.I.bird "I")
    (h.assertEq "k.K.bird == \"K\"" k.K.bird "K")
    (h.assertEq "k.M.bird == \"M\"" k.M.bird "M")
    (h.assertEq "k.C.bird == \"C\"" k.C.bird "C")
    (h.assertEq "k.V.bird == \"V\"" k.V.bird "V")
    (h.assertTrue "k.I has .apply" (builtins.isFunction k.I.apply))
    (h.assertTrue "k.K has .apply" (builtins.isFunction k.K.apply))
    (h.assertTrue "k.M has .apply" (builtins.isFunction k.M.apply))
    (h.assertTrue "k.C has .apply" (builtins.isFunction k.C.apply))
    (h.assertTrue "k.V has .apply" (builtins.isFunction k.V.apply))
  ];

  # Suite 2: Tagged Bird Apply
  suiteApply = h.runSuite "Tagged Bird Apply" [
    (h.assertEq "k.apply k.I \"hello\"" (k.apply k.I "hello") "hello")
    (h.assertEq "k.apply (k.apply k.K \"yes\") \"no\"" (k.apply (k.apply k.K "yes") "no") "yes")
    (h.assertEq "k.apply (k.apply k.KI \"yes\") \"no\"" (k.apply (k.apply k.KI "yes") "no") "no")
    (h.assertEq "S K K = I" (k.apply (k.apply (k.apply k.S k.K) k.K) "test") "test")
    (h.assertEq "C K flips" (k.apply (k.apply (k.apply k.C k.K) "a") "b") "b")
    (h.assertEq "V pair with K" (k.apply (k.apply (k.apply k.V "a") "b") k.K) "a")
  ];

  # Suite 3: show function
  suiteShow = h.runSuite "show function" [
    (h.assertTrue "k.show k.I returns a string" (builtins.isString (k.show k.I)))
  ];

  # Suite 4: Kernel examples
  suiteExamples = h.runSuite "Kernel examples" [
    (h.assertEq "k.examples.identity" k.examples.identity "hello")
    (h.assertEq "k.examples.kestrelChoice" k.examples.kestrelChoice "yes")
  ];

  # Suite 5: Toolchain Type Check
  suiteTypeCheck = h.runSuite "Toolchain Type Check" [
    (let
      result = tc.typeCheck "I";
    in h.assertEq "tc.typeCheck \"I\" ok" result.ok true)
    (let
      result = tc.typeCheck "I";
    in h.assertEq "tc.typeCheck \"I\" type" result.type "a -> a")
    (let
      result = tc.typeCheck "K";
    in h.assertTrue "tc.typeCheck \"K\" ok" result.ok)
    (let
      result = tc.typeCheck "C";
    in h.assertTrue "tc.typeCheck \"C\" ok" result.ok)
    (let
      result = tc.typeCheck "V";
    in h.assertTrue "tc.typeCheck \"V\" ok" result.ok)
    (let
      result = tc.typeCheck "UNKNOWN";
    in h.assertFalse "tc.typeCheck \"UNKNOWN\" ok" result.ok)
  ];

  # Suite 6: Toolchain Config Example
  suiteConfig = h.runSuite "Toolchain Config Example" [
    (h.assertEq "tc.configExample.serverName" tc.configExample.serverName "example.com")
    (h.assertEq "tc.configExample.port" tc.configExample.port 8080)
    (h.assertEq "tc.configExample.selfRef" tc.configExample.selfRef "nginx")
  ];

  # Suite 7: Toolchain Demos
  suiteDemos = h.runSuite "Toolchain Demos" [
    (h.assertEq "tc.demos.sKK.test" tc.demos.sKK.test "hello")
    (h.assertTrue "tc.demos.sKK.pretty is a string" (builtins.isString tc.demos.sKK.pretty))
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
