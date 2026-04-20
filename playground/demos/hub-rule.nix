let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  triangle = gcl.cycleGen { nodes = 3; prefix = "t"; };
  hubbed = gcl.hubRule triangle;
in {
  before = g.nodeCount triangle;
  after  = g.nodeCount hubbed;
  hubDegree = g.degree "hub" hubbed;
}
