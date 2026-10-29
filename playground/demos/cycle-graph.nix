let
  cycle = gcl.cycleGen { nodes = 5; prefix = "c"; };
in {
  nodes = gcl.getNodeIds cycle;
  edges = gcl.getEdgeIds cycle;
  # Last edge loops back: c4 → c0
  hasLoopBack = gcl.hasEdge "c4->c0" cycle;
}
