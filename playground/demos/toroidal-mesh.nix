# 2D torus network — NoC (Network-on-Chip) router topology
# A 4×4 toroidal mesh where each router connects to its 4 neighbors
# with wraparound edges. Used in real chip designs (Tilera TILE-Gx,
# Intel Xeon Phi) and supercomputer interconnects (IBM Blue Gene/L).
# Every node has identical degree — the topology's symmetry gives
# uniform bisection bandwidth and predictable worst-case latency.
let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  rows = 4; cols = 4;
  str = n: if n == 0 then "0" else if n == 1 then "1" else if n == 2 then "2" else if n == 3 then "3" else if n == 4 then "4" else if n == 5 then "5" else if n == 6 then "6" else if n == 7 then "7" else if n == 8 then "8" else "9";
  nid = r: c: "n" + str r + "_" + str c;
  wrap = x: n: if x >= n then 0 else if x < 0 then n - 1 else x;

  # ── Router nodes: n{r}_{c} ────────────────────────────────────────
  rowNodes = r: c:
    if c >= cols then [] else [ { id = nid r c; type = "router"; } ]
      ++ rowNodes r (c + 1);
  gridNodes = r:
    if r >= rows then [] else rowNodes r 0 ++ gridNodes (r + 1);
  nodes = gridNodes 0;

  # ── Horizontal links (east, with wraparound) ──────────────────────
  hRow = r: c:
    if c >= cols then []
    else
      [ { from = nid r c; to = nid r (wrap (c + 1) cols); id = "h_" + str r + "_" + str c; directed = false; } ]
      ++ hRow r (c + 1);
  hGrid = r:
    if r >= rows then [] else hRow r 0 ++ hGrid (r + 1);
  hLinks = hGrid 0;

  # ── Vertical links (south, with wraparound) ───────────────────────
  vRow = r: c:
    if c >= cols then []
    else
      [ { from = nid r c; to = nid (wrap (r + 1) rows) c; id = "v_" + str r + "_" + str c; directed = false; } ]
      ++ vRow r (c + 1);
  vGrid = r:
    if r >= rows then [] else vRow r 0 ++ vGrid (r + 1);
  vLinks = vGrid 0;

  torus = gcl.fromSpec { nodes = nodes; edges = hLinks ++ vLinks; };
in {
  dimensions = str rows + "x" + str cols + " torus";
  total_routers = gcl.nodeCount torus;
  total_links = gcl.edgeCount torus;

  # Every node in a torus should have degree 4 (N, S, E, W)
  # Using undirected edges, each link counted once per endpoint
  n0_0_degree = gcl.degree "n0_0" torus;
  n2_3_degree = gcl.degree "n2_3" torus;
  center_degree = gcl.degree "n1_1" torus;

  # Wraparound verification: n0_0 connects to n0_3 (west) and n3_0 (north)
  n0_0_neighbors = gcl.neighbors "n0_0" torus;

  json = gcl.toGraphJSON torus;
}
