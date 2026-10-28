let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  path = gcl.pathGen { nodes = 5; prefix = "n"; };
in {
  nodes = gcl.getNodeIds path;
  edges = gcl.getEdgeIds path;
  count = { nodes = gcl.nodeCount path; edges = gcl.edgeCount path; };
}
