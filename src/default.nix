# bird-nix — Combinator library from "To Mock a Mockingbird"
#
# Human-readable bird names are the primary API:
#
#   bn = import ./src {};
#   bn.mockingbird.call f        # self-application
#   bn.mockingbird.speech        # "If you tell me how to respond..."
#   bn.kestrel.call "yes" "no"   # → "yes"
#   bn.pipe 5 [(x: x * 2) (x: x + 1)]  # → 11
#
# Single-letter aliases (I, K, S, ...) are available under bn.birds
# for terse combinator notation when needed.
#
# For use as a flake:
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
  graphLib = import ./graph.nix {};
  graphCombinators = import ./graph-combinators.nix { graph = graphLib; };
  pbt = import ../tests/bird-pbt.nix {};
  harness = import ../tests/test-harness.nix {};
  examples = import ../tests/real-world-birds.nix {};

in {
  # === Birds (primary API — human-readable names) ===
  # Each bird has .call (the combinator function) and .speech (description)
  inherit (speech) identityBird mockingbird kestrel kite bluebird cardinal
    warbler starling vireo lark sageBird;

  # Bird sentences — conversational descriptions
  inherit (speech) sentences;

  # === Single-letter aliases (terse notation) ===
  # Available for internal use / combinator-heavy code
  # Prefer the human-readable names above for public APIs
  inherit birds;

  # === DSL ===
  inherit (dsl) pipe birdMap;

  # === Compiler & Toolchain ===
  inherit ast compiler format toolchain kernel;
  inherit (ast) mkApp mkVar mkBird mkLambda;
  inherit (compiler) compile rewrite inferType;
  inherit (format) pp freeVars etaReduce;
  inherit (toolchain) typeCheck compileBird ppBird typeEnv;

  # === Graph ===
  inherit graphLib graphCombinators;
  inherit (graphLib) emptyGraph addNode addEdge removeNode removeEdge
    getNodeIds getEdgeIds nodeCount edgeCount hasNode hasEdge getNode getEdge
    neighbors inNeighbors degree merge isEmpty isSubgraphOf fromEdgeList
    toGraphJSON;
  inherit (graphCombinators) identityGraph constGraph edgePair composeOps
    parallelMerge flipOps dupArg makeSelfLoop
    pathGen starGen completeGen cycleGen gridGen
    subdivideRule hubRule contractRule reverseEdgesRule
    graphIdentity warblerKestrelIdentity gclTypeEnv graphSpeech;

  # === Testing ===
  inherit pbt harness examples;
  inherit (pbt) forAll forAll2 forAll3 property checkProperties domains;
  inherit (harness) assertEq assertTrue assertFalse assertPred assertEval assertThrows runSuite combineSuites;
}
