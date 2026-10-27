let
  g = import ./graph.nix {};
  gcl = import ./graph-combinators.nix { graph = g; };
  triangle = gcl.cycleGen { nodes = 3; prefix = "t"; };
  hubbed = gcl.hubRule triangle;
in {
  before = gcl.nodeCount triangle;
  after  = gcl.nodeCount hubbed;
  hubDegree = gcl.degree "hub" hubbed;
}
