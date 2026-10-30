# Bird combinators and graph-library queries come from the playground
# prelude: bare I/K/S... for birds, `g` for raw graph queries, `gcl`
# for combinator-powered graph transforms.
let
  oneNode = g.addNode "a" "node" g.emptyGraph;
in {
  kestrelSays = K "yes" "no";
  skk         = S K K 42;
  nodeCount   = g.nodeCount oneNode;
}
