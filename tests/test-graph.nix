# tests/test-graph.nix — Tests for graph.nix and graph-combinators.nix
# Tests: core graph ops, combinator ops, generators, rewrite rules, algebraic laws

{ }:

let
  h = import ./test-harness.nix {};
  birds = import ../src/birds.nix {};
  g = import ../src/graph.nix {};
  gc = import ../src/graph-combinators.nix { graph = g; };

  inherit (birds) K KI V;
  eq = h.assertEq;
  ok = h.assertTrue;
  nok = h.assertFalse;
  eval = h.assertEval;
  suite = h.runSuite;

  # ── Fixture graphs ─────────────────────────────────────────────

  g0 = g.emptyGraph;
  g1 = g.addNode "a" "server" g0;
  g2 = g.addNode "b" "client" g1;
  g3 = g.addEdge "e1" "a" "b" true g2;

  path3 = gc.pathGen { nodes = 3; prefix = "p"; };
  star4 = gc.starGen { nodes = 4; prefix = "s"; };
  k3 = gc.completeGen { nodes = 3; prefix = "c"; };
  cyc4 = gc.cycleGen { nodes = 4; prefix = "cy"; };
  grid2x3 = gc.gridGen { rows = 2; cols = 3; prefix = "g"; };

  # ── Graph Core Tests ───────────────────────────────────────────

  suite-empty = suite "Graph — Empty" [
    (ok  "empty is empty"      (g.isEmpty g0))
    (eq  "empty node count"    (g.nodeCount g0) 0)
    (eq  "empty edge count"    (g.edgeCount g0) 0)
    (eq  "empty node ids"      (g.getNodeIds g0) [])
    (eq  "empty edge ids"      (g.getEdgeIds g0) [])
  ];

  suite-addNode = suite "Graph — addNode" [
    (eq  "one node count"      (g.nodeCount g1) 1)
    (ok  "has node a"          (g.hasNode "a" g1))
    (nok "no node b yet"       (g.hasNode "b" g1))
    (eq  "node a id"           (g.getNode "a" g1).id "a")
    (eq  "node a type"         (g.getNode "a" g1).type "server")
    (eq  "two nodes count"     (g.nodeCount g2) 2)
    (ok  "has node b"          (g.hasNode "b" g2))
    (nok "not empty after add" (g.isEmpty g1))
  ];

  suite-addEdge = suite "Graph — addEdge" [
    (eq  "one edge count"      (g.edgeCount g3) 1)
    (ok  "has edge e1"         (g.hasEdge "e1" g3))
    (eq  "edge e1 source"      (g.getEdge "e1" g3).source "a")
    (eq  "edge e1 target"      (g.getEdge "e1" g3).target "b")
    (ok  "edge e1 directed"    (g.getEdge "e1" g3).directed)
  ];

  suite-remove = suite "Graph — remove" [
    (let r = g.removeEdge "e1" g3;
     in eq "remove edge count" (g.edgeCount r) 0)
    (let r = g.removeEdge "e1" g3;
     in nok "edge gone" (g.hasEdge "e1" r))
    (let r = g.removeEdge "e1" g3;
     in eq "nodes unchanged" (g.nodeCount r) 2)
    (let r = g.removeNode "a" g3;
     in nok "node a gone" (g.hasNode "a" r))
    (let r = g.removeNode "a" g3;
     in eq "cascade edge removal" (g.edgeCount r) 0)
  ];

  suite-queries = suite "Graph — queries" [
    (eq  "neighbors of a"      (g.neighbors "a" g3) ["b"])
    (eq  "neighbors of b"      (g.neighbors "b" g3) [])
    (eq  "inNeighbors of b"    (g.inNeighbors "b" g3) ["a"])
    (eq  "inNeighbors of a"    (g.inNeighbors "a" g3) [])
    (eq  "degree of a"         (g.degree "a" g3) 1)
    (eq  "degree of b"         (g.degree "b" g3) 0)
    (eq  "edgesFrom a count"   (builtins.length (g.edgesFrom "a" g3)) 1)
    (eq  "edgesTo b count"     (builtins.length (g.edgesTo "b" g3)) 1)
  ];

  suite-merge = suite "Graph — merge" [
    (let
      ga = g.addNode "x" "node" g0;
      gb = g.addNode "y" "node" g0;
      m = g.merge ga gb;
    in eq "merge node count" (g.nodeCount m) 2)
    (let
      ga = g.addNode "x" "node" g0;
      gb = g.addNode "y" "node" g0;
      m = g.merge ga gb;
    in ok "merge has x" (g.hasNode "x" m))
    (let
      ga = g.addNode "x" "node" g0;
      gb = g.addNode "y" "node" g0;
      m = g.merge ga gb;
    in ok "merge has y" (g.hasNode "y" m))
  ];

  suite-subgraph = suite "Graph — isSubgraphOf" [
    (ok  "g1 subgraph of g2"   (g.isSubgraphOf g1 g2))
    (ok  "g2 subgraph of g3"   (g.isSubgraphOf g2 g3))
    (ok  "empty subgraph of all" (g.isSubgraphOf g0 g3))
    (ok  "self subgraph"       (g.isSubgraphOf g3 g3))
  ];

  suite-conv = suite "Graph — conversions" [
    (eq  "toNodeList count"    (builtins.length (g.toNodeList g2)) 2)
    (eq  "toEdgeList count"    (builtins.length (g.toEdgeList g3)) 1)
    (let
      el = g.fromEdgeList [
        { source = "x"; target = "y"; }
        { source = "y"; target = "z"; }
      ];
    in eq "fromEdgeList nodes" (g.nodeCount el) 3)
    (let
      el = g.fromEdgeList [
        { source = "x"; target = "y"; }
        { source = "y"; target = "z"; }
      ];
    in eq "fromEdgeList edges" (g.edgeCount el) 2)
  ];

  # ── Combinator Graph Ops Tests ─────────────────────────────────

  suite-identity = suite "GCL — Identity (I)" [
    (eq  "I graph = graph"     (gc.identityGraph g3) g3)
    (eq  "I empty = empty"     (gc.identityGraph g0) g0)
  ];

  suite-vireo = suite "GCL — Vireo Edge Pair (V)" [
    (eq  "V src tgt K = src"   (gc.edgePair "server" "client" K) "server")
    (eq  "V src tgt KI = tgt"  (gc.edgePair "server" "client" KI) "client")
    (eq  "V a b f = f a b"     (gc.edgePair "a" "b" (x: y: x + "->" + y)) "a->b")
  ];

  suite-compose = suite "GCL — Bluebird Composition (B)" [
    (let
      addA = g.addNode "a" "node";
      addB = g.addNode "b" "node";
      comp = gc.composeOps addB addA g0;
    in eq "B compose count" (g.nodeCount comp) 2)
    (let
      addA = g.addNode "a" "node";
      addB = g.addNode "b" "node";
      comp = gc.composeOps addB addA g0;
    in ok "B compose has a" (g.hasNode "a" comp))
  ];

  suite-parallel = suite "GCL — Parallel Merge" [
    (let
      addX = g.addNode "x" "node";
      addY = g.addNode "y" "node";
      par = gc.parallelMerge addX addY g0;
    in eq "parallel count" (g.nodeCount par) 2)
    (let
      addX = g.addNode "x" "node";
      addY = g.addNode "y" "node";
      par = gc.parallelMerge addX addY g0;
    in ok "parallel has x" (g.hasNode "x" par))
    (let
      addX = g.addNode "x" "node";
      addY = g.addNode "y" "node";
      par = gc.parallelMerge addX addY g0;
    in ok "parallel has y" (g.hasNode "y" par))
  ];

  suite-selfloop = suite "GCL — Self-Loop (W)" [
    (let sl = gc.makeSelfLoop "n" g0;
    in ok "has node" (g.hasNode "n" sl))
    (let sl = gc.makeSelfLoop "n" g0;
    in eq "has loop edge" (g.edgeCount sl) 1)
    (let sl = gc.makeSelfLoop "n" g0;
         e = builtins.head (g.toEdgeList sl);
    in eq "loop source=target" e.source e.target)
  ];

  # ── Generator Tests ────────────────────────────────────────────

  suite-pathGen = suite "GCL — Path Generator" [
    (eq  "path3 nodes"         (g.nodeCount path3) 3)
    (eq  "path3 edges"         (g.edgeCount path3) 2)
    (ok  "path3 has p0"        (g.hasNode "p0" path3))
    (ok  "path3 has p1"        (g.hasNode "p1" path3))
    (ok  "path3 has p2"        (g.hasNode "p2" path3))
    (eq  "path1 nodes"         (g.nodeCount (gc.pathGen { nodes = 1; prefix = "x"; })) 1)
    (eq  "path1 edges"         (g.edgeCount (gc.pathGen { nodes = 1; prefix = "x"; })) 0)
    (ok  "path0 empty"         (g.isEmpty (gc.pathGen { nodes = 0; })))
  ];

  suite-starGen = suite "GCL — Star Generator" [
    (eq  "star4 nodes"         (g.nodeCount star4) 4)
    (eq  "star4 edges"         (g.edgeCount star4) 3)
    (ok  "star4 has center"    (g.hasNode "s0" star4))
    (ok  "star4 has spoke1"    (g.hasNode "s1" star4))
    (ok  "star4 has spoke2"    (g.hasNode "s2" star4))
    (ok  "star4 has spoke3"    (g.hasNode "s3" star4))
    (eq  "star center degree"  (g.degree "s0" star4) 3)
  ];

  suite-completeGen = suite "GCL — Complete Generator" [
    (eq  "K3 nodes"            (g.nodeCount k3) 3)
    (eq  "K3 edges"            (g.edgeCount k3) 6)
    (eq  "K1 edges"            (g.edgeCount (gc.completeGen { nodes = 1; prefix = "x"; })) 0)
    (eq  "K4 edges"            (g.edgeCount (gc.completeGen { nodes = 4; prefix = "x"; })) 12)
  ];

  suite-cycleGen = suite "GCL — Cycle Generator" [
    (eq  "cycle4 nodes"        (g.nodeCount cyc4) 4)
    (eq  "cycle4 edges"        (g.edgeCount cyc4) 4)
    (eq  "cycle3 edges"        (g.edgeCount (gc.cycleGen { nodes = 3; prefix = "x"; })) 3)
  ];

  suite-gridGen = suite "GCL — Grid Generator" [
    (eq  "grid 2x3 nodes"     (g.nodeCount grid2x3) 6)
    (eq  "grid 2x3 edges"     (g.edgeCount grid2x3) 7)
    (eq  "grid 1x1 nodes"     (g.nodeCount (gc.gridGen { rows = 1; cols = 1; })) 1)
    (eq  "grid 1x1 edges"     (g.edgeCount (gc.gridGen { rows = 1; cols = 1; })) 0)
    (eq  "grid 3x3 nodes"     (g.nodeCount (gc.gridGen { rows = 3; cols = 3; })) 9)
    (eq  "grid 3x3 edges"     (g.edgeCount (gc.gridGen { rows = 3; cols = 3; })) 12)
  ];

  # ── Rewrite Rule Tests ─────────────────────────────────────────

  suite-subdivide = suite "GCL — Subdivide Rule" [
    (let s = gc.subdivideRule g3 "e1";
    in eq "subdivide adds mid node" (g.nodeCount s) 3)
    (let s = gc.subdivideRule g3 "e1";
    in eq "subdivide replaces 1 edge with 2" (g.edgeCount s) 2)
    (let s = gc.subdivideRule g3 "e1";
    in nok "original edge gone" (g.hasEdge "e1" s))
    (let s = gc.subdivideRule g3 "e1";
    in ok "has edge a" (g.hasEdge "e1_a" s))
    (let s = gc.subdivideRule g3 "e1";
    in ok "has edge b" (g.hasEdge "e1_b" s))
  ];

  suite-hub = suite "GCL — Hub Rule" [
    (let h = gc.hubRule g2;
    in eq "hub adds 1 node" (g.nodeCount h) 3)
    (let h = gc.hubRule g2;
    in ok "hub node exists" (g.hasNode "hub" h))
    # hub connects bidirectionally to all existing nodes: 2 nodes * 2 dirs = 4 edges
    (let h = gc.hubRule g2;
    in eq "hub edge count" (g.edgeCount h) 4)
  ];

  suite-reverse = suite "GCL — Reverse Edges Rule" [
    (let r = gc.reverseEdgesRule g3;
    in eq "reversed source" (g.getEdge "e1" r).source "b")
    (let r = gc.reverseEdgesRule g3;
    in eq "reversed target" (g.getEdge "e1" r).target "a")
    (let r = gc.reverseEdgesRule g3;
    in eq "edge count preserved" (g.edgeCount r) 1)
    (let r = gc.reverseEdgesRule g3;
    in eq "node count preserved" (g.nodeCount r) 2)
  ];

  suite-contract = suite "GCL — Contract Rule" [
    (let
      ga = g.addEdge "e2" "b" "c" true
        (g.addNode "c" "node" g3);
      c = gc.contractRule ga "e1";
    in eq "contract removes target node" (g.nodeCount c) 2)
    (let
      ga = g.addEdge "e2" "b" "c" true
        (g.addNode "c" "node" g3);
      c = gc.contractRule ga "e1";
    in nok "contracted node gone" (g.hasNode "b" c))
    (let
      ga = g.addEdge "e2" "b" "c" true
        (g.addNode "c" "node" g3);
      c = gc.contractRule ga "e1";
    in eq "contracted edge gone" (g.edgeCount c) 1)
  ];

  # ── Algebraic Law Tests ────────────────────────────────────────

  suite-laws = suite "GCL — Algebraic Laws" [
    # S K K = I
    (ok  "S K K = I (int)"     (gc.graphIdentity 42 == 42))
    (ok  "S K K = I (string)"  (gc.graphIdentity "hello" == "hello"))
    (ok  "S K K = I (graph)"   (gc.graphIdentity g3 == g3))

    # W K = I
    (ok  "W K = I (int)"       (gc.warblerKestrelIdentity 42 == 42))
    (ok  "W K = I (string)"    (gc.warblerKestrelIdentity "hello" == "hello"))
    (ok  "W K = I (graph)"     (gc.warblerKestrelIdentity g3 == g3))

    # V x y K = x  (vireo pair with kestrel selects first)
    (eq  "V x y K = x"         (V "first" "second" K) "first")

    # V x y KI = y  (vireo pair with kite selects second)
    (eq  "V x y KI = y"        (V "first" "second" KI) "second")

    # C K = KI  (cardinal-kestrel = kite)
    (let ck = birds.C K;
    in eq "C K x y = KI x y" (ck "a" "b") "b")

    # B f I = f  (right identity of composition)
    (let f = x: x + 1;
    in eq "B f I = f" (birds.B f birds.I 5) (f 5))

    # B I f = f  (left identity of composition)
    (let f = x: x * 2;
    in eq "B I f = f" (birds.B birds.I f 5) (f 5))

    # M I = I  (mockingbird-identity = identity)
    (eq  "M I = I" (birds.M birds.I 42) 42)
  ];

  # ── Speech Tests ───────────────────────────────────────────────

  suite-speech = suite "GCL — Speech descriptions" [
    (eval "identityGraph speech" gc.graphSpeech.identityGraph.speech)
    (eval "edgePair speech"      gc.graphSpeech.edgePair.speech)
    (eval "pathGen speech"       gc.graphSpeech.pathGen.speech)
    (eval "starGen speech"       gc.graphSpeech.starGen.speech)
    (eval "completeGen speech"   gc.graphSpeech.completeGen.speech)
    (eval "subdivideRule speech" gc.graphSpeech.subdivideRule.speech)
    (eval "hubRule speech"       gc.graphSpeech.hubRule.speech)
  ];

  # ── Type Environment Tests ─────────────────────────────────────

  suite-types = suite "GCL — Type Environment" [
    (eval "typeEnv I"   gc.gclTypeEnv.I)
    (eval "typeEnv K"   gc.gclTypeEnv.K)
    (eval "typeEnv V"   gc.gclTypeEnv.V)
    (eval "typeEnv B"   gc.gclTypeEnv.B)
    (eval "typeEnv S"   gc.gclTypeEnv.S)
    (eval "typeEnv W"   gc.gclTypeEnv.W)
    (eval "typeEnv M"   gc.gclTypeEnv.M)
    (eval "typeEnv Y"   gc.gclTypeEnv.Y)
  ];

in
  h.combineSuites "Graph Combinator Tests" [
    suite-empty
    suite-addNode
    suite-addEdge
    suite-remove
    suite-queries
    suite-merge
    suite-subgraph
    suite-conv
    suite-identity
    suite-vireo
    suite-compose
    suite-parallel
    suite-selfloop
    suite-pathGen
    suite-starGen
    suite-completeGen
    suite-cycleGen
    suite-gridGen
    suite-subdivide
    suite-hub
    suite-reverse
    suite-contract
    suite-laws
    suite-speech
    suite-types
  ]
