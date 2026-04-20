let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  path = gcl.pathGen { nodes = 5; prefix = "n"; };
in {
  nodes = g.getNodeIds path;
  edges = g.getEdgeIds path;
  count = { nodes = g.nodeCount path; edges = g.edgeCount path; };
}
