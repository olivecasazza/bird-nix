let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  k4 = gcl.completeGen { nodes = 4; prefix = "v"; };
in {
  nodes = gcl.getNodeIds k4;
  edgeCount = gcl.edgeCount k4;  # 4*3 = 12 directed edges
  v0_neighbors = gcl.neighbors "v0" k4;
}
