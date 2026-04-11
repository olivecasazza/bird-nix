# tests/default.nix — Combine all test suites

{ }:
let
  bn = import ../src {};
  h = bn.harness;
  testBirds = import ./test-birds.nix {};
  testCompiler = import ./test-compiler.nix {};
  testKernel = import ./test-kernel.nix {};
  testPbt = import ./test-pbt.nix {};

  # Concatenate suites from all test files
  allSuites = testBirds.suites ++ testCompiler.suites ++ testKernel.suites ++ testPbt.suites;
in
  h.combineSuites "Bird-Nix Full Test Suite" allSuites
