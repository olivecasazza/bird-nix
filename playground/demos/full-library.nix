# The bird combinators and the graph library through direct single-hop
# imports. The playground's tvix build cannot follow the multi-hop
# re-export graph in `default.nix`, so the demos import the leaf modules
# directly — the same way the playground prelude does.
let
  g = import ./graph.nix {};
  birds = import ./birds.nix {};
  oneNode = g.addNode "a" "node" g.emptyGraph;
in {
  kestrelSays = birds.K "yes" "no";
  skk         = birds.S birds.K birds.K 42;
  nodeCount   = g.nodeCount oneNode;
}
