let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  k4 = gcl.completeGen { nodes = 4; prefix = "v"; };
in {
  nodes = g.getNodeIds k4;
  edgeCount = g.edgeCount k4;  # 4*3 = 12 directed edges
  v0_neighbors = g.neighbors "v0" k4;
}
