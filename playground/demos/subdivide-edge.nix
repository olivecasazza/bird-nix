let
  path = gcl.pathGen { nodes = 3; prefix = "p"; };
  # Subdivide the edge p0→p1
  subdivided = gcl.subdivideRule path "p0->p1";
in {
  before = { nodes = gcl.getNodeIds path; edges = gcl.getEdgeIds path; };
  after  = { nodes = gcl.getNodeIds subdivided; edges = gcl.getEdgeIds subdivided; };
}
