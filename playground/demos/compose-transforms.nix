let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  # Compose: first reverse edges, then add hub
  transform = gcl.composeOps gcl.hubRule gcl.reverseEdgesRule;
  path = gcl.pathGen { nodes = 4; prefix = "x"; };
  result = transform path;
in {
  original_nodes = gcl.nodeCount path;
  result_nodes   = gcl.nodeCount result;  # +1 for hub
  has_hub        = gcl.hasNode "hub" result;
}
