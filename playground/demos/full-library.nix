let bn = import ./default.nix {};
in {
  birdNames = builtins.attrNames bn.birds;
  skk_test  = bn.birds.S bn.birds.K bn.birds.K 42;
}
