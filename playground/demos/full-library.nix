# The whole library through one import: `default.nix` re-exports every module.
#
# Nested selects and calls reached through a second import hop are not
# evaluable in the playground's tvix build, so this demo counts the export
# surface and makes its runnable call through `birds.nix` directly — the way
# the playground prelude does.
let
  bn = import ./default.nix { };
  birds = import ./birds.nix { };
in
{
  exports = builtins.length (builtins.attrNames bn);
  kestrelSays = birds.K "yes" "no";
}
