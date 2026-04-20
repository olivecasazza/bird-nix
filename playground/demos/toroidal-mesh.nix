# 2D torus network — NoC (Network-on-Chip) router topology
# A 4×4 toroidal mesh where each router connects to its 4 neighbors
# with wraparound edges. Used in real chip designs (Tilera TILE-Gx,
# Intel Xeon Phi) and supercomputer interconnects (IBM Blue Gene/L).
# Every node has identical degree — the topology's symmetry gives
# uniform bisection bandwidth and predictable worst-case latency.
let
  g = import ./graph.nix {};
  str = builtins.toString;
  rows = 4; cols = 4;
  nid = r: c: "n${str r}_${str c}";
  wrap = x: n: if x >= n then 0 else if x < 0 then n - 1 else x;

  # Create router nodes
  withNodes = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      g.addNode (nid r c) "router" acc2
    ) acc (builtins.genList (x: x) cols)
  ) g.emptyGraph (builtins.genList (x: x) rows);

  # Horizontal links (east, with wraparound)
  withH = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      let
        src = nid r c;
        dst = nid r (wrap (c + 1) cols);
      in g.addEdge "h_${str r}_${str c}" src dst false acc2
    ) acc (builtins.genList (x: x) cols)
  ) withNodes (builtins.genList (x: x) rows);

  # Vertical links (south, with wraparound)
  torus = builtins.foldl' (acc: r:
    builtins.foldl' (acc2: c:
      let
        src = nid r c;
        dst = nid (wrap (r + 1) rows) c;
      in g.addEdge "v_${str r}_${str c}" src dst false acc2
    ) acc (builtins.genList (x: x) cols)
  ) withH (builtins.genList (x: x) rows);
in {
  dimensions = "${str rows}x${str cols} torus";
  total_routers = g.nodeCount torus;
  total_links = g.edgeCount torus;

  # Every node in a torus should have degree 4 (N, S, E, W)
  # Using undirected edges, each link counted once per endpoint
  n0_0_degree = g.degree "n0_0" torus;
  n2_3_degree = g.degree "n2_3" torus;
  center_degree = g.degree "n1_1" torus;

  # Wraparound verification: n0_0 connects to n0_3 (west) and n3_0 (north)
  n0_0_neighbors = g.neighbors "n0_0" torus;

  json = g.toGraphJSON torus;
}
