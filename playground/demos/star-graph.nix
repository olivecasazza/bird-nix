let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  star = gcl.starGen { nodes = 6; prefix = "s"; };
in {
  nodes = gcl.getNodeIds star;
  edges = gcl.getEdgeIds star;
  hub_degree = gcl.degree "s0" star;
}
