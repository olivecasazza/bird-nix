let
  grid = gcl.gridGen { rows = 3; cols = 3; prefix = "g"; };
in {
  nodes = gcl.getNodeIds grid;
  edgeCount = gcl.edgeCount grid;
  # Corner node has 2 neighbors (right + down)
  corner = gcl.neighbors "g0_0" grid;
}
