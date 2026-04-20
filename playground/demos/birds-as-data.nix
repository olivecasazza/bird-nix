# Birds as first-class Nix data
let
  makeBird = name: call: rule: { inherit name call rule; };
  kestrel = makeBird "K" K "K x y = x";
  identity = makeBird "I" I "I x = x";
in {
  name   = kestrel.name;
  result = kestrel.call "kept" "dropped";
  rule   = identity.rule;
}
