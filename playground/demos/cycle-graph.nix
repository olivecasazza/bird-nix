let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  cycle = gcl.cycleGen { nodes = 5; prefix = "c"; };
in {
  nodes = g.getNodeIds cycle;
  edges = g.getEdgeIds cycle;
  # Last edge loops back: c4 → c0
  hasLoopBack = g.hasEdge "c4->c0" cycle;
}
