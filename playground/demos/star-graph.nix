let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  star = gcl.starGen { nodes = 6; prefix = "s"; };
in {
  nodes = g.getNodeIds star;
  edges = g.getEdgeIds star;
  hub_degree = g.degree "s0" star;
}
