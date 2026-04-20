let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  # Compose: first reverse edges, then add hub
  transform = gcl.composeOps gcl.hubRule gcl.reverseEdgesRule;
  path = gcl.pathGen { nodes = 4; prefix = "x"; };
  result = transform path;
in {
  original_nodes = g.nodeCount path;
  result_nodes   = g.nodeCount result;  # +1 for hub
  has_hub        = g.hasNode "hub" result;
}
