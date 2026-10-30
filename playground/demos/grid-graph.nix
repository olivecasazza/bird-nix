let
  grid = gcl.gridGen { rows = 3; cols = 3; prefix = "g"; };
in {
  nodes = g.getNodeIds grid;
  edgeCount = g.edgeCount grid;
  # Corner node has 2 neighbors (right + down)
  corner = g.neighbors "g0_0" grid;
}
