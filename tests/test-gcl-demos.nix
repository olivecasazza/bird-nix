# tests/test-gcl-demos.nix — Native Nix tests for GCL demos
# Tests: generators, rewrite rules, real-world graph patterns
#
# These are the test counterparts of playground/demos/*.nix,
# written as proper assertions using the test harness instead of
# standalone demo scripts.

{ }:

let
  h = import ./test-harness.nix {};
  birds = import ../src/birds.nix {};
  g = import ../src/graph.nix {};
  gc = import ../src/graph-combinators.nix { graph = g; };

  inherit (birds) K KI;
  eq = h.assertEq;
  ok = h.assertTrue;
  nok = h.assertFalse;
  suite = h.runSuite;
  str = builtins.toString;

  # ════════════════════════════════════════════════════════════════
  # GCL GENERATORS
  # ════════════════════════════════════════════════════════════════

  # ── Path Graph ──────────────────────────────────────────────────
  # Demo: playground/demos/path-graph.nix
  # Linear chain: n0 → n1 → n2 → n3 → n4

  path5 = gc.pathGen { nodes = 5; prefix = "n"; };

  suite-path = suite "GCL Demo — Path Graph" [
    (eq  "path5 node count"     (g.nodeCount path5) 5)
    (eq  "path5 edge count"     (g.edgeCount path5) 4)
    (ok  "path5 has n0"         (g.hasNode "n0" path5))
    (ok  "path5 has n4"         (g.hasNode "n4" path5))
    (ok  "path5 has edge n0→n1" (g.hasEdge "n0->n1" path5))
    (ok  "path5 has edge n3→n4" (g.hasEdge "n3->n4" path5))
    # Invariant: edges = nodes - 1
    (eq  "path invariant e=n-1" (g.edgeCount path5) (g.nodeCount path5 - 1))
    # Endpoint n0 has degree 1 (out to n1)
    (eq  "endpoint n0 degree"   (g.degree "n0" path5) 1)
    # Interior node n2 has degree 1 (out to n3; in-edge from n1 doesn't count in degree)
    (eq  "interior n2 out-deg"  (g.degree "n2" path5) 1)
    # Endpoint n4 has degree 0 (no outgoing edges)
    (eq  "endpoint n4 degree"   (g.degree "n4" path5) 0)
    # Edge cases
    (ok  "path0 is empty"       (g.isEmpty (gc.pathGen { nodes = 0; })))
    (eq  "path1 has 1 node"     (g.nodeCount (gc.pathGen { nodes = 1; prefix = "x"; })) 1)
    (eq  "path1 has 0 edges"    (g.edgeCount (gc.pathGen { nodes = 1; prefix = "x"; })) 0)
    # Path of 10: verify invariant scales
    (let p10 = gc.pathGen { nodes = 10; prefix = "p"; };
     in eq "path10 e=n-1" (g.edgeCount p10) 9)
  ];

  # ── Star Graph ──────────────────────────────────────────────────
  # Demo: playground/demos/star-graph.nix
  # Hub s0 → {s1, s2, s3, s4, s5}

  star6 = gc.starGen { nodes = 6; prefix = "s"; };

  suite-star = suite "GCL Demo — Star Graph" [
    (eq  "star6 node count"     (g.nodeCount star6) 6)
    (eq  "star6 edge count"     (g.edgeCount star6) 5)
    (ok  "star6 has center s0"  (g.hasNode "s0" star6))
    (ok  "star6 has spoke s5"   (g.hasNode "s5" star6))
    # Hub degree = nodes - 1
    (eq  "hub degree = n-1"     (g.degree "s0" star6) 5)
    # Spokes have 0 out-degree (directed: hub→spoke only)
    (eq  "spoke s1 degree"      (g.degree "s1" star6) 0)
    (eq  "spoke s5 degree"      (g.degree "s5" star6) 0)
    # Invariant: edges = nodes - 1
    (eq  "star invariant e=n-1" (g.edgeCount star6) (g.nodeCount star6 - 1))
    # Neighbors of hub = all spokes
    (eq  "hub neighbor count"   (builtins.length (g.neighbors "s0" star6)) 5)
    # Each spoke has hub as inNeighbor
    (eq  "spoke inNeighbor"     (g.inNeighbors "s1" star6) ["s0"])
    # Edge cases
    (eq  "star1 edges"          (g.edgeCount (gc.starGen { nodes = 1; prefix = "x"; })) 0)
    (eq  "star2 edges"          (g.edgeCount (gc.starGen { nodes = 2; prefix = "x"; })) 1)
  ];

  # ── Complete Graph ──────────────────────────────────────────────
  # Demo: playground/demos/complete-graph.nix
  # Every node connected to every other (directed)

  k4 = gc.completeGen { nodes = 4; prefix = "v"; };

  suite-complete = suite "GCL Demo — Complete Graph" [
    (eq  "K4 node count"        (g.nodeCount k4) 4)
    # Directed complete: n*(n-1) edges
    (eq  "K4 edge count"        (g.edgeCount k4) 12)
    (ok  "K4 has v0"            (g.hasNode "v0" k4))
    (ok  "K4 has v3"            (g.hasNode "v3" k4))
    # Each node has out-degree n-1
    (eq  "v0 out-degree"        (g.degree "v0" k4) 3)
    (eq  "v3 out-degree"        (g.degree "v3" k4) 3)
    # Each node has in-degree n-1
    (eq  "v0 in-degree"         (builtins.length (g.inNeighbors "v0" k4)) 3)
    # Specific edges exist
    (ok  "has v0→v1"            (g.hasEdge "v0->v1" k4))
    (ok  "has v3→v0"            (g.hasEdge "v3->v0" k4))
    # Invariants at different sizes
    (eq  "K1 edges = 0"         (g.edgeCount (gc.completeGen { nodes = 1; prefix = "x"; })) 0)
    (eq  "K2 edges = 2"         (g.edgeCount (gc.completeGen { nodes = 2; prefix = "x"; })) 2)
    (eq  "K3 edges = 6"         (g.edgeCount (gc.completeGen { nodes = 3; prefix = "x"; })) 6)
    (eq  "K5 edges = 20"        (g.edgeCount (gc.completeGen { nodes = 5; prefix = "x"; })) 20)
  ];

  # ── Cycle Graph ─────────────────────────────────────────────────
  # Demo: playground/demos/cycle-graph.nix
  # Path with wrap-around: c0 → c1 → c2 → c3 → c4 → c0

  cyc5 = gc.cycleGen { nodes = 5; prefix = "c"; };

  suite-cycle = suite "GCL Demo — Cycle Graph" [
    (eq  "cycle5 node count"    (g.nodeCount cyc5) 5)
    # Invariant: edges = nodes (one extra wrap-around edge)
    (eq  "cycle5 edge count"    (g.edgeCount cyc5) 5)
    (ok  "has wrap-around c4→c0" (g.hasEdge "c4->c0" cyc5))
    (ok  "has forward c0→c1"    (g.hasEdge "c0->c1" cyc5))
    # Every node has out-degree 1
    (eq  "c0 out-degree"        (g.degree "c0" cyc5) 1)
    (eq  "c2 out-degree"        (g.degree "c2" cyc5) 1)
    (eq  "c4 out-degree"        (g.degree "c4" cyc5) 1)
    # Every node has in-degree 1
    (eq  "c0 in-degree"         (builtins.length (g.inNeighbors "c0" cyc5)) 1)
    (eq  "c3 in-degree"         (builtins.length (g.inNeighbors "c3" cyc5)) 1)
    # Invariant: edges = nodes at different sizes
    (eq  "cycle3 edges=3"       (g.edgeCount (gc.cycleGen { nodes = 3; prefix = "x"; })) 3)
    (eq  "cycle8 edges=8"       (g.edgeCount (gc.cycleGen { nodes = 8; prefix = "x"; })) 8)
  ];

  # ── Grid Graph ──────────────────────────────────────────────────
  # Demo: playground/demos/grid-graph.nix
  # 2D lattice with right and down edges

  grid3x3 = gc.gridGen { rows = 3; cols = 3; prefix = "g"; };

  suite-grid = suite "GCL Demo — Grid Graph" [
    (eq  "grid 3x3 nodes"       (g.nodeCount grid3x3) 9)
    # Grid edges: rows*(cols-1) + cols*(rows-1) = 3*2 + 3*2 = 12
    (eq  "grid 3x3 edges"       (g.edgeCount grid3x3) 12)
    (ok  "grid has g0_0"        (g.hasNode "g0_0" grid3x3))
    (ok  "grid has g2_2"        (g.hasNode "g2_2" grid3x3))
    # Corner g0_0: right + down = 2 out-edges
    (eq  "corner g0_0 degree"   (g.degree "g0_0" grid3x3) 2)
    # Edge g0_1: right + down = 2 out-edges
    (eq  "edge g0_1 degree"     (g.degree "g0_1" grid3x3) 2)
    # Bottom-right corner g2_2: no right, no down = 0 out-edges
    (eq  "corner g2_2 degree"   (g.degree "g2_2" grid3x3) 0)
    # Interior g1_1: right + down = 2 out-edges
    (eq  "interior g1_1 degree" (g.degree "g1_1" grid3x3) 2)
    # Edge formula: rows*(cols-1) + cols*(rows-1)
    (let grid4x5 = gc.gridGen { rows = 4; cols = 5; prefix = "x"; };
     in eq "grid 4x5 nodes" (g.nodeCount grid4x5) 20)
    (let grid4x5 = gc.gridGen { rows = 4; cols = 5; prefix = "x"; };
     in eq "grid 4x5 edges" (g.edgeCount grid4x5) 31)  # 4*4 + 5*3 = 16+15 = 31
    # Degenerate cases
    (eq  "grid 1x1 nodes"       (g.nodeCount (gc.gridGen { rows = 1; cols = 1; })) 1)
    (eq  "grid 1x1 edges"       (g.edgeCount (gc.gridGen { rows = 1; cols = 1; })) 0)
    (eq  "grid 1x5 edges"       (g.edgeCount (gc.gridGen { rows = 1; cols = 5; })) 4)
    (eq  "grid 5x1 edges"       (g.edgeCount (gc.gridGen { rows = 5; cols = 1; })) 4)
  ];

  # ════════════════════════════════════════════════════════════════
  # GCL REWRITES
  # ════════════════════════════════════════════════════════════════

  # ── Subdivide Edge ──────────────────────────────────────────────
  # Demo: playground/demos/subdivide-edge.nix
  # Replace a→b with a→mid→b

  path3 = gc.pathGen { nodes = 3; prefix = "p"; };
  subdivided = gc.subdivideRule path3 "p0->p1";

  suite-subdivide = suite "GCL Demo — Subdivide Edge" [
    # Before: 3 nodes, 2 edges
    (eq  "before: 3 nodes"          (g.nodeCount path3) 3)
    (eq  "before: 2 edges"          (g.edgeCount path3) 2)
    # After: +1 node (mid), +1 edge (split 1 into 2)
    (eq  "after: 4 nodes"           (g.nodeCount subdivided) 4)
    (eq  "after: 3 edges"           (g.edgeCount subdivided) 3)
    # Original edge gone, replaced by two halves
    (nok "original edge gone"       (g.hasEdge "p0->p1" subdivided))
    (ok  "first half exists"        (g.hasEdge "p0->p1_a" subdivided))
    (ok  "second half exists"       (g.hasEdge "p0->p1_b" subdivided))
    # Mid node inserted
    (ok  "mid node exists"          (g.hasNode "p0_p1_mid" subdivided))
    # Other edge untouched
    (ok  "p1→p2 still exists"       (g.hasEdge "p1->p2" subdivided))
    # Invariant: subdivide adds exactly 1 node and 1 edge
    (eq  "Δnodes = +1"             (g.nodeCount subdivided - g.nodeCount path3) 1)
    (eq  "Δedges = +1"             (g.edgeCount subdivided - g.edgeCount path3) 1)
  ];

  # ── Hub Rule ────────────────────────────────────────────────────
  # Demo: playground/demos/hub-rule.nix
  # Add hub node connected bidirectionally to all existing nodes

  triangle = gc.cycleGen { nodes = 3; prefix = "t"; };
  hubbed = gc.hubRule triangle;

  suite-hub = suite "GCL Demo — Hub Rule" [
    # Before: 3 nodes, 3 edges (cycle)
    (eq  "before: 3 nodes"          (g.nodeCount triangle) 3)
    (eq  "before: 3 edges"          (g.edgeCount triangle) 3)
    # After: +1 node (hub), +2*n edges (bidirectional to each)
    (eq  "after: 4 nodes"           (g.nodeCount hubbed) 4)
    (ok  "hub node exists"          (g.hasNode "hub" hubbed))
    # Hub has bidirectional edges to all 3 original nodes: 3 out + 3 in = 6 new edges
    (eq  "after: 9 edges"           (g.edgeCount hubbed) 9)  # 3 original + 6 hub
    # Hub out-degree = 3 (hub→t0, hub→t1, hub→t2)
    (eq  "hub out-degree"           (g.degree "hub" hubbed) 3)
    # Hub in-degree = 3 (t0→hub, t1→hub, t2→hub)
    (eq  "hub in-degree"            (builtins.length (g.inNeighbors "hub" hubbed)) 3)
    # Original edges preserved
    (ok  "original t0→t1 preserved" (g.hasEdge "t0->t1" hubbed))
    (ok  "hub→t0 edge exists"       (g.hasEdge "hub->t0" hubbed))
    (ok  "t0→hub edge exists"       (g.hasEdge "t0->hub" hubbed))
    # Invariant: hub adds exactly 1 node
    (eq  "Δnodes = +1"             (g.nodeCount hubbed - g.nodeCount triangle) 1)
  ];

  # ── Reverse Edges ───────────────────────────────────────────────
  # Demo: playground/demos/reverse-edges.nix
  # Flip all edge directions

  rpath = gc.pathGen { nodes = 3; prefix = "r"; };
  reversed = gc.reverseEdgesRule rpath;

  suite-reverse = suite "GCL Demo — Reverse Edges" [
    # Same node count
    (eq  "same node count"          (g.nodeCount reversed) (g.nodeCount rpath))
    # Same edge count
    (eq  "same edge count"          (g.edgeCount reversed) (g.edgeCount rpath))
    # Original: r0→r1 has source=r0, target=r1
    (eq  "original r0→r1 source"    (g.getEdge "r0->r1" rpath).source "r0")
    (eq  "original r0→r1 target"    (g.getEdge "r0->r1" rpath).target "r1")
    # Reversed: r0→r1 has source=r1, target=r0 (edge ID preserved, endpoints swapped)
    (eq  "reversed r0→r1 source"    (g.getEdge "r0->r1" reversed).source "r1")
    (eq  "reversed r0→r1 target"    (g.getEdge "r0->r1" reversed).target "r0")
    (eq  "reversed r1→r2 source"    (g.getEdge "r1->r2" reversed).source "r2")
    (eq  "reversed r1→r2 target"    (g.getEdge "r1->r2" reversed).target "r1")
    # Double-reverse = identity
    (let drev = gc.reverseEdgesRule reversed;
     in eq "double-reverse source" (g.getEdge "r0->r1" drev).source "r0")
    (let drev = gc.reverseEdgesRule reversed;
     in eq "double-reverse target" (g.getEdge "r0->r1" drev).target "r1")
  ];

  # ── Compose Transforms ─────────────────────────────────────────
  # Demo: playground/demos/compose-transforms.nix
  # Compose: first reverse, then add hub

  composePath = gc.pathGen { nodes = 4; prefix = "x"; };
  transform = gc.composeOps gc.hubRule gc.reverseEdgesRule;
  composed = transform composePath;

  suite-compose = suite "GCL Demo — Compose Transforms" [
    (eq  "original: 4 nodes"        (g.nodeCount composePath) 4)
    # After compose: reversed first (same nodes), then hub (+1)
    (eq  "composed: 5 nodes"        (g.nodeCount composed) 5)
    (ok  "composed has hub"         (g.hasNode "hub" composed))
    # Hub connects to all 4 original nodes
    (eq  "hub out-degree"           (g.degree "hub" composed) 4)
    # Edges were reversed before hub was added
    (eq  "reversed x0→x1 source"    (g.getEdge "x0->x1" composed).source "x1")
    # Compose is B: (B f g) x = f (g x)
    (let
      manualResult = gc.hubRule (gc.reverseEdgesRule composePath);
    in eq "compose = manual apply" (g.nodeCount composed) (g.nodeCount manualResult))
  ];

  # ════════════════════════════════════════════════════════════════
  # GCL REAL-WORLD PATTERNS
  # ════════════════════════════════════════════════════════════════

  # ── Social Network ──────────────────────────────────────────────
  # Demo: playground/demos/social-network.nix

  social =
    g.addEdge "u0-u1" "user0" "user1" false
    (g.addEdge "u1-u2" "user1" "user2" false
    (g.addEdge "u2-u3" "user2" "user3" false
    (g.addEdge "u0-u4" "user0" "user4" false
    (g.addNode "user0" "person"
    (g.addNode "user1" "person"
    (g.addNode "user2" "person"
    (g.addNode "user3" "person"
    (g.addNode "user4" "person"
    g.emptyGraph))))))));

  suite-social = suite "GCL Demo — Social Network" [
    (eq  "5 users"                 (g.nodeCount social) 5)
    (eq  "4 friendships"           (g.edgeCount social) 4)
    # user0 has out-edges to user1 and user4
    (eq  "user0 friend count"      (builtins.length (g.neighbors "user0" social)) 2)
    # user2 has out-edge to user3
    (eq  "user2 friend count"      (builtins.length (g.neighbors "user2" social)) 1)
    # user3 has no out-edges (leaf)
    (eq  "user3 friend count"      (builtins.length (g.neighbors "user3" social)) 0)
    # user1 in-neighbors: user0
    (eq  "user1 incoming"          (g.inNeighbors "user1" social) ["user0"])
  ];

  # ── Neural Network Layers ───────────────────────────────────────
  # Demo: playground/demos/neural-network-layers.nix
  # 4 input → 6 hidden → 3 output (fully connected between layers)

  nnInputNodes = builtins.genList (i: "L0N${str i}") 4;
  nnHiddenNodes = builtins.genList (i: "L1N${str i}") 6;
  nnOutputNodes = builtins.genList (i: "L2N${str i}") 3;
  nnWithNodes = builtins.foldl'
    (acc: nid: g.addNode nid "neuron" acc)
    g.emptyGraph
    (nnInputNodes ++ nnHiddenNodes ++ nnOutputNodes);
  nnWithIH = builtins.foldl' (acc: i:
    builtins.foldl' (acc2: j:
      g.addEdge "L0N${str i}->L1N${str j}" "L0N${str i}" "L1N${str j}" true acc2
    ) acc (builtins.genList (x: x) 6)
  ) nnWithNodes (builtins.genList (x: x) 4);
  nn = builtins.foldl' (acc: i:
    builtins.foldl' (acc2: j:
      g.addEdge "L1N${str i}->L2N${str j}" "L1N${str i}" "L2N${str j}" true acc2
    ) acc (builtins.genList (x: x) 3)
  ) nnWithIH (builtins.genList (x: x) 6);

  suite-neural = suite "GCL Demo — Neural Network" [
    # Total neurons: 4 + 6 + 3 = 13
    (eq  "total neurons"           (g.nodeCount nn) 13)
    # Total synapses: 4*6 + 6*3 = 24 + 18 = 42
    (eq  "total synapses"          (g.edgeCount nn) 42)
    # Input→hidden invariant: input_count * hidden_count
    (eq  "input→hidden synapses"   (4 * 6) 24)
    # Hidden→output invariant: hidden_count * output_count
    (eq  "hidden→output synapses"  (6 * 3) 18)
    # Each hidden neuron has out-degree 3 (to output layer)
    (eq  "L1N0 out-degree"         (builtins.length (g.neighbors "L1N0" nn)) 3)
    # Each input neuron has out-degree 6 (to hidden layer)
    (eq  "L0N0 out-degree"         (builtins.length (g.neighbors "L0N0" nn)) 6)
    # Output neurons have no outgoing edges
    (eq  "L2N0 out-degree"         (builtins.length (g.neighbors "L2N0" nn)) 0)
    # Output neurons have in-degree 6 (from all hidden)
    (eq  "L2N0 in-degree"          (builtins.length (g.inNeighbors "L2N0" nn)) 6)
  ];

  # ── HPC Cluster Topology ───────────────────────────────────────
  # Demo: playground/demos/hpc-cluster-topology.nix
  # scheduler + storage → 16 compute nodes

  clusterBase = g.addNode "scheduler" "slurm"
    (g.addNode "storage" "lustre" g.emptyGraph);
  clusterWithCompute = builtins.foldl' (acc: i:
    let tier = if i < 8 then "gpu" else "cpu";
        nid = "node${str i}";
    in g.addNode nid tier acc
  ) clusterBase (builtins.genList (x: x) 16);
  clusterWithSched = builtins.foldl' (acc: i:
    let nid = "node${str i}";
    in g.addEdge "sched->${nid}" "scheduler" nid true acc
  ) clusterWithCompute (builtins.genList (x: x) 16);
  cluster = builtins.foldl' (acc: i:
    let nid = "node${str i}";
    in g.addEdge "store->${nid}" "storage" nid true acc
  ) clusterWithSched (builtins.genList (x: x) 16);

  suite-hpc = suite "GCL Demo — HPC Cluster" [
    # 2 management + 16 compute = 18 nodes
    (eq  "total nodes"             (g.nodeCount cluster) 18)
    # 16 scheduler edges + 16 storage edges = 32
    (eq  "total edges"             (g.edgeCount cluster) 32)
    # Scheduler fan-out = 16
    (eq  "scheduler fan-out"       (g.degree "scheduler" cluster) 16)
    # Storage fan-out = 16
    (eq  "storage fan-out"         (g.degree "storage" cluster) 16)
    # Compute nodes have 0 out-degree
    (eq  "node0 out-degree"        (g.degree "node0" cluster) 0)
    (eq  "node15 out-degree"       (g.degree "node15" cluster) 0)
    # Each compute node has in-degree 2 (from scheduler + storage)
    (eq  "node0 in-degree"         (builtins.length (g.inNeighbors "node0" cluster)) 2)
    # GPU nodes (0-7) and CPU nodes (8-15) have the right types
    (eq  "node0 is gpu"            (g.getNode "node0" cluster).type "gpu")
    (eq  "node8 is cpu"            (g.getNode "node8" cluster).type "cpu")
    # Invariant: edges = 2 * compute_count
    (eq  "edges = 2*compute"       (g.edgeCount cluster) (2 * 16))
  ];

  # ── Quantum Circuit ────────────────────────────────────────────
  # Demo: playground/demos/quantum-circuit.nix

  qWithQubits = builtins.foldl' (acc: i:
    g.addNode "q${str i}" "qubit" acc
  ) g.emptyGraph (builtins.genList (x: x) 4);
  qWithGates =
    g.addNode "H_gate" "hadamard"
    (g.addNode "CNOT_gate" "cnot"
    (g.addNode "X_gate" "pauli_x"
    (g.addNode "measure" "measurement"
    qWithQubits)));
  qCircuit =
    g.addEdge "q0->H" "q0" "H_gate" true
    (g.addEdge "H->q0" "H_gate" "q0" true
    (g.addEdge "q1->CNOT" "q1" "CNOT_gate" true
    (g.addEdge "q0->CNOT" "q0" "CNOT_gate" true
    (g.addEdge "q3->meas" "q3" "measure" true
    qWithGates))));

  suite-quantum = suite "GCL Demo — Quantum Circuit" [
    # 4 qubits + 4 gates = 8 nodes
    (eq  "total nodes"             (g.nodeCount qCircuit) 8)
    # 5 operations
    (eq  "total operations"        (g.edgeCount qCircuit) 5)
    # q0 connects to H_gate and CNOT_gate
    (eq  "q0 out-degree"           (builtins.length (g.neighbors "q0" qCircuit)) 2)
    # H_gate connects back to q0
    (eq  "H_gate out-degree"       (builtins.length (g.neighbors "H_gate" qCircuit)) 1)
    # CNOT receives from q0 and q1
    (eq  "CNOT in-degree"          (builtins.length (g.inNeighbors "CNOT_gate" qCircuit)) 2)
    # X_gate has no connections (unused gate)
    (eq  "X_gate isolated"         (g.degree "X_gate" qCircuit) 0)
    # q3 connects to measure
    (eq  "q3→measure"              (g.neighbors "q3" qCircuit) ["measure"])
    # Gate types
    (eq  "H_gate type"             (g.getNode "H_gate" qCircuit).type "hadamard")
    (eq  "CNOT_gate type"          (g.getNode "CNOT_gate" qCircuit).type "cnot")
  ];

  # ── Toroidal Mesh ──────────────────────────────────────────────
  # Demo: playground/demos/toroidal-mesh.nix
  # 4×4 grid with wrap-around edges (torus)

  tRows = 4; tCols = 4;
  tNid = r: c: "n${str r}_${str c}";
  tWithNodes = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      g.addNode (tNid r c) "router" acc2
    ) acc (builtins.genList (x: x) tCols)
  ) g.emptyGraph (builtins.genList (x: x) tRows);
  tWithH = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      g.addEdge "${tNid r c}->h${str r}_${str c}" (tNid r c) (tNid r (if c + 1 >= tCols then 0 else c + 1)) true acc2
    ) acc (builtins.genList (x: x) tCols)
  ) tWithNodes (builtins.genList (x: x) tRows);
  torus = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      g.addEdge "${tNid r c}->v${str r}_${str c}" (tNid r c) (tNid (if r + 1 >= tRows then 0 else r + 1) c) true acc2
    ) acc (builtins.genList (x: x) tCols)
  ) tWithH (builtins.genList (x: x) tRows);

  suite-torus = suite "GCL Demo — Toroidal Mesh" [
    # nodes = rows * cols
    (eq  "torus nodes"             (g.nodeCount torus) 16)
    # edges = 2 * rows * cols (horizontal + vertical, each with wrap)
    (eq  "torus edges"             (g.edgeCount torus) 32)
    # Every node has out-degree 2 (right + down)
    (eq  "n0_0 out-degree"         (g.degree "n0_0" torus) 2)
    (eq  "n3_3 out-degree"         (g.degree "n3_3" torus) 2)
    (eq  "n1_2 out-degree"         (g.degree "n1_2" torus) 2)
    # Wrap-around edges exist: n0_3 → n0_0 (horizontal wrap)
    (ok  "horizontal wrap"         (g.hasEdge "n0_3->h0_3" torus))
    # Wrap-around edges exist: n3_0 → n0_0 (vertical wrap)
    (ok  "vertical wrap"           (g.hasEdge "n3_0->v3_0" torus))
    # Invariant: every node has in-degree 2 as well
    (eq  "n0_0 in-degree"          (builtins.length (g.inNeighbors "n0_0" torus)) 2)
    (eq  "n2_2 in-degree"          (builtins.length (g.inNeighbors "n2_2" torus)) 2)
    # Torus invariant: edges = 2 * nodes
    (eq  "torus edges=2*nodes"     (g.edgeCount torus) (2 * g.nodeCount torus))
  ];

  # ── Protein Interaction Network ─────────────────────────────────
  # Demo: playground/demos/protein-interaction-network.nix

  pProteins =
    g.addNode "p53" "protein"
    (g.addNode "MDM2" "protein"
    (g.addNode "ATM" "sensor"
    (g.addNode "effector0" "effector"
    (g.addNode "effector1" "effector"
    (g.addNode "effector2" "effector"
    g.emptyGraph)))));
  pNetwork =
    g.addEdge "ATM->p53" "ATM" "p53" true
    (g.addEdge "p53->eff0" "p53" "effector0" true
    (g.addEdge "p53->eff1" "p53" "effector1" true
    (g.addEdge "MDM2->p53" "MDM2" "p53" true
    (g.addEdge "ATM->eff2" "ATM" "effector2" true
    (g.addEdge "p53->MDM2" "p53" "MDM2" true
    pProteins)))));

  suite-protein = suite "GCL Demo — Protein Interaction" [
    (eq  "6 proteins"              (g.nodeCount pNetwork) 6)
    (eq  "6 interactions"          (g.edgeCount pNetwork) 6)
    # p53 activates effector0, effector1, MDM2
    (eq  "p53 targets"             (builtins.length (g.neighbors "p53" pNetwork)) 3)
    # p53 is regulated by ATM and MDM2
    (eq  "p53 regulators"          (builtins.length (g.inNeighbors "p53" pNetwork)) 2)
    # ATM activates p53 and effector2
    (eq  "ATM targets"             (builtins.length (g.neighbors "ATM" pNetwork)) 2)
    # Feedback loop: p53→MDM2 and MDM2→p53
    (ok  "p53→MDM2 exists"         (g.hasEdge "p53->MDM2" pNetwork))
    (ok  "MDM2→p53 exists"         (g.hasEdge "MDM2->p53" pNetwork))
    # Effectors are sinks (no outgoing edges)
    (eq  "effector0 out-degree"    (g.degree "effector0" pNetwork) 0)
    (eq  "effector1 out-degree"    (g.degree "effector1" pNetwork) 0)
    (eq  "effector2 out-degree"    (g.degree "effector2" pNetwork) 0)
  ];

  # ── Chemical Reaction Graph ─────────────────────────────────────
  # Demo: playground/demos/chemical-reaction-graph.nix

  cMolecules =
    g.addNode "H2" "molecule"
    (g.addNode "O2" "molecule"
    (g.addNode "H2O" "product"
    (g.addNode "Pt" "catalyst"
    (g.addNode "transition_state" "energy"
    g.emptyGraph))));
  cReaction =
    g.addEdge "H2->H2O" "H2" "H2O" true
    (g.addEdge "O2->H2O" "O2" "H2O" true
    (g.addEdge "Pt->H2" "Pt" "H2" true
    (g.addEdge "Pt->O2" "Pt" "O2" true
    (g.addEdge "Pt->H2O" "Pt" "H2O" true
    (g.addEdge "H2->TS" "H2" "transition_state" true
    (g.addEdge "TS->H2O" "transition_state" "H2O" true
    cMolecules))))));

  suite-chemical = suite "GCL Demo — Chemical Reaction" [
    (eq  "5 species"               (g.nodeCount cReaction) 5)
    (eq  "7 pathways"              (g.edgeCount cReaction) 7)
    # Catalyst (Pt) has 3 outgoing: H2, O2, H2O
    (eq  "Pt targets"              (builtins.length (g.neighbors "Pt" cReaction)) 3)
    # H2O (product) has 4 incoming: H2, O2, Pt, transition_state
    (eq  "H2O sources"            (builtins.length (g.inNeighbors "H2O" cReaction)) 4)
    # H2 has 2 outgoing: H2O, transition_state
    (eq  "H2 targets"             (builtins.length (g.neighbors "H2" cReaction)) 2)
    # H2O is a sink (product, no outgoing)
    (eq  "H2O out-degree"          (g.degree "H2O" cReaction) 0)
    # transition_state has 1 outgoing: H2O
    (eq  "TS→H2O"                  (g.neighbors "transition_state" cReaction) ["H2O"])
    # Node types
    (eq  "Pt type"                 (g.getNode "Pt" cReaction).type "catalyst")
    (eq  "H2O type"                (g.getNode "H2O" cReaction).type "product")
  ];

in
  h.combineSuites "GCL Demo Tests" [
    # Generators
    suite-path
    suite-star
    suite-complete
    suite-cycle
    suite-grid
    # Rewrites
    suite-subdivide
    suite-hub
    suite-reverse
    suite-compose
    # Real-World Patterns
    suite-social
    suite-neural
    suite-hpc
    suite-quantum
    suite-torus
    suite-protein
    suite-chemical
  ]
