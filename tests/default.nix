# tests/default.nix — Combine all test suites

{ }:
let
  bn = import ../src {};
  h = bn.harness;
  testBirds = import ./test-birds.nix {};
  testCompiler = import ./test-compiler.nix {};
  testKernel = import ./test-kernel.nix {};
  testPbt = import ./test-pbt.nix {};
  testGraph = import ./test-graph.nix {};
  testGclDemos = import ./test-gcl-demos.nix {};

  # Concatenate suites from all test files
  allSuites = testBirds.suites ++ testCompiler.suites ++ testKernel.suites ++ testPbt.suites ++ testGraph.suites ++ testGclDemos.suites;
in
  h.combineSuites "Bird-Nix Full Test Suite" allSuites
