let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  path = gcl.pathGen { nodes = 3; prefix = "r"; };
  reversed = gcl.reverseEdgesRule path;
  # Original: r0→r1, r1→r2
  # Reversed: r1→r0, r2→r1
  origEdge = g.getEdge "r0->r1" path;
  revEdge  = g.getEdge "r0->r1" reversed;
in {
  original = { src = origEdge.source; tgt = origEdge.target; };
  reversed = { src = revEdge.source;  tgt = revEdge.target; };
}
