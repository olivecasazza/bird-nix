# test-harness.nix — Self-bootstrapped test framework using bird combinators
#
# The harness itself is built from the combinators it tests.
# K selects (true branch), KI selects (false branch), B composes assertions,
# pipe chains test steps, and Y enables recursive test runners.
#
# Dogfoods birds.nix — all combinators imported, not redefined.
#
# Usage:
#   nix eval --impure --expr '(import ./tests/test-harness.nix {}).summary'
#   nix eval --impure --expr '(import ./tests/test-harness.nix {}).run'
{ }:

let
  # === BIRD BOOTSTRAP ===
  # Import canonical combinators from birds.nix
  birds = import ../src/birds.nix {};
  inherit (birds) I K KI B W S Y;

  # === TEST PRIMITIVES (built from birds) ===

  # Boolean selectors using K/KI encoding
  # "true" = K (selects first), "false" = KI (selects second)
  bTrue = K;
  bFalse = KI;

  # Convert Nix bool to bird-bool
  toBirdBool = b: if b then bTrue else bFalse;

  # Bird-if: select branch via K/KI
  bIf = cond: t: f: (toBirdBool cond) t f;

  # === ASSERTION FUNCTIONS ===

  # Core assertion: check equality, return test result record
  assertEq = name: actual: expected:
    let pass = actual == expected;
    in {
      inherit name pass actual expected;
      status = if pass then "PASS" else "FAIL";
      msg =
        if pass then "${name}: OK"
        else "${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
    };

  # Assert a value is true
  assertTrue = name: actual:
    assertEq name actual true;

  # Assert a value is false
  assertFalse = name: actual:
    assertEq name actual false;

  # Assert a value matches a predicate
  assertPred = name: pred: actual:
    let pass = pred actual;
    in {
      inherit name pass actual;
      expected = "<predicate>";
      status = if pass then "PASS" else "FAIL";
      msg =
        if pass then "${name}: OK"
        else "${name}: predicate failed on ${builtins.toJSON actual}";
    };

  # Assert evaluation doesn't error (for testing partial application etc.)
  assertEval = name: expr:
    let result = builtins.tryEval (builtins.deepSeq expr expr);
    in {
      inherit name;
      pass = result.success;
      actual = if result.success then result.value else "<error>";
      expected = "<no error>";
      status = if result.success then "PASS" else "FAIL";
      msg =
        if result.success then "${name}: OK (evaluates)"
        else "${name}: evaluation failed";
    };

  # Assert evaluation DOES error (for testing expected failures)
  assertThrows = name: expr:
    let result = builtins.tryEval (builtins.deepSeq expr expr);
    in {
      inherit name;
      pass = !result.success;
      actual = if result.success then "<no error>" else "<error>";
      expected = "<error>";
      status = if !result.success then "PASS" else "FAIL";
      msg =
        if !result.success then "${name}: OK (throws as expected)"
        else "${name}: expected error but got ${builtins.toJSON result.value}";
    };

  # === TEST SUITE RUNNER ===

  # Run a list of test results, produce summary
  runSuite = name: tests:
    let
      total = builtins.length tests;
      passed = builtins.length (builtins.filter (t: t.pass) tests);
      failed = builtins.length (builtins.filter (t: !t.pass) tests);
      failures = builtins.filter (t: !t.pass) tests;
      failMsgs = builtins.map (t: t.msg) failures;
    in {
      inherit name total passed failed failures;
      ok = failed == 0;
      summary = "${name}: ${toString passed}/${toString total} passed"
        + (if failed > 0 then " (${toString failed} FAILED)" else "");
      failureMessages = failMsgs;
    };

  # Combine multiple suites
  combineSuites = name: suites:
    let
      total = builtins.foldl' (a: s: a + s.total) 0 suites;
      passed = builtins.foldl' (a: s: a + s.passed) 0 suites;
      failed = builtins.foldl' (a: s: a + s.failed) 0 suites;
      allFailures = builtins.concatLists (builtins.map (s: s.failures) suites);
      suiteLines = builtins.map (s:
        "  ${s.summary}"
      ) suites;
    in {
      inherit name total passed failed suites;
      ok = failed == 0;
      failures = allFailures;
      summary = builtins.concatStringsSep "\n" ([
        "═══════════════════════════════════════════"
        "  ${name}"
        "═══════════════════════════════════════════"
      ] ++ suiteLines ++ [
        "───────────────────────────────────────────"
        ("  TOTAL: ${toString passed}/${toString total} passed"
        + (if failed > 0 then " (${toString failed} FAILED)" else " ALL PASSED"))
        "═══════════════════════════════════════════"
      ]);
    };

in {
  inherit assertEq assertTrue assertFalse assertPred assertEval assertThrows;
  inherit runSuite combineSuites;
  inherit bTrue bFalse bIf toBirdBool;

  # Self-test: the harness tests itself
  selfTest = runSuite "test-harness self-test" [
    (assertEq "assertEq pass" (assertEq "x" 1 1).pass true)
    (assertEq "assertEq fail" (assertEq "x" 1 2).pass false)
    (assertEq "assertTrue pass" (assertTrue "x" true).pass true)
    (assertEq "assertTrue fail" (assertTrue "x" false).pass false)
    (assertEq "assertFalse pass" (assertFalse "x" false).pass true)
    (assertEq "bIf true" (bIf true "yes" "no") "yes")
    (assertEq "bIf false" (bIf false "yes" "no") "no")
    (assertEq "K as true" (K "a" "b") "a")
    (assertEq "KI as false" (KI "a" "b") "b")
  ];
}
