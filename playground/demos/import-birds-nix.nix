let b = import ./birds.nix {};
in {
  identity = b.I "hello";
  kestrel  = b.K "yes" "no";
  compose  = b.B (x: x + 1) (x: x * 2) 5;
}
