# bird-nix — Combinator library from "To Mock a Mockingbird"
#
# Unified entry point. Import this to get everything:
#
#   bird-nix = import ./src {};
#   inherit (bird-nix) birds dsl compiler format toolchain kernel speech pbt;
#
# Or import individual modules:
#   birds = import ./src/birds.nix {};
#
# For use as a flake overlay:
#   inputs.bird-nix.url = "github:olivecasazza/bird-nix";
#   # then: bird-nix.lib { }

{ }:

let
  ast = import ./ast.nix {};
  birds = import ./birds.nix {};
  compiler = import ./bird-compiler.nix {};
  format = import ./bird-format.nix {};
  dsl = import ./bird-dsl.nix {};
  toolchain = import ./bird-toolchain.nix {};
  kernel = import ./bird-nix.nix {};
  speech = import ./birds-speech.nix {};
  pbt = import ./bird-pbt.nix {};
  harness = import ./test-harness.nix {};
  examples = import ./real-world-birds.nix {};

in {
  # === Core Combinators ===
  # I M K KI B C L W S V Y — the canonical bird definitions
  inherit birds;

  # Re-export birds at top level for convenience:
  #   bird-nix = import ./src {};
  #   bird-nix.I "hello"  # → "hello"
  inherit (birds) I M K KI B C L W S V Y;

  # === Modules ===

  # DSL with pipe operator and birdMap
  inherit dsl;

  # AST compiler with rewrite rules
  inherit compiler;

  # Pretty-printer, eta-reducer, free variable analysis
  inherit format;

  # Unified toolchain (compiler + format + type checking)
  inherit toolchain;

  # Tagged-union kernel (bird-nix.nix)
  inherit kernel;

  # Conversational wrappers with speech strings
  inherit speech;

  # Property-based testing framework
  inherit pbt;

  # Test harness (assertEq, runSuite, combineSuites)
  inherit harness;

  # Real-world usage examples
  inherit examples;

  # AST constructors (canonical source: ast.nix)
  inherit ast;

  # === Convenience Re-exports ===

  # AST constructors at top level
  inherit (ast) mkApp mkVar mkBird mkLambda;

  # Compiler operations
  inherit (compiler) compile rewrite inferType;

  # Formatter operations
  inherit (format) pp freeVars etaReduce;

  # Toolchain operations
  inherit (toolchain) typeCheck compileBird ppBird typeEnv;

  # DSL operations
  inherit (dsl) pipe birdMap;

  # PBT operations
  inherit (pbt) forAll forAll2 forAll3 property checkProperties domains;

  # Test harness operations
  inherit (harness) assertEq assertTrue assertFalse assertPred assertEval assertThrows runSuite combineSuites;
}
