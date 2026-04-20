{ }:
let
  graph = import ./graph.nix {};
in {
  addNode = graph.addNode;
}
