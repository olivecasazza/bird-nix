let
  gcl = import ./graph-combinators.nix { graph = g; };
  g = import ./graph.nix {};
  path = gcl.pathGen { nodes = 3; prefix = "p"; };
  # Subdivide the edge p0→p1
  subdivided = gcl.subdivideRule path "p0->p1";
in {
  before = { nodes = g.getNodeIds path; edges = g.getEdgeIds path; };
  after  = { nodes = g.getNodeIds subdivided; edges = g.getEdgeIds subdivided; };
}
