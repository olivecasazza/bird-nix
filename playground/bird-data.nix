# Generate playground metadata from canonical Nix sources.
# Evaluated at build time: `nix eval --json -f bird-data.nix > bird-data.json`
#
# This ensures the playground's autocomplete, hover, and demo data
# always matches the real bird-nix library — Nix is the single source
# of truth, not the Rust WASM or JS.

{ }:

let
  compiler = import ../src/bird-compiler.nix {};
  speech = import ../src/birds-speech.nix {};

  # Canonical type environment (from bird-compiler.nix)
  typeEnv = compiler.typeEnv;

  # Map from bird letter(s) to { aka, rule, description, speech }
  birdMeta = {
    I = {
      aka = "Identity Bird";
      rule = "I x = x";
      description = "Returns its argument unchanged";
      speech = speech.identityBird.speech;
    };
    K = {
      aka = "Kestrel";
      rule = "K x y = x";
      description = "Always returns the first argument, discarding the second";
      speech = speech.kestrel.speech;
    };
    KI = {
      aka = "Kite";
      rule = "KI x y = y";
      description = "Always returns the second argument, discarding the first";
      speech = speech.kite.speech;
    };
    M = {
      aka = "Mockingbird";
      rule = "M f = f f";
      description = "Self-application: applies a function to itself";
      speech = speech.mockingbird.speech;
    };
    B = {
      aka = "Bluebird";
      rule = "B f g x = f (g x)";
      description = "Function composition: composes two functions";
      speech = speech.bluebird.speech;
    };
    C = {
      aka = "Cardinal";
      rule = "C f x y = f y x";
      description = "Flips the order of arguments to a function";
      speech = speech.cardinal.speech;
    };
    W = {
      aka = "Warbler";
      rule = "W f x = f x x";
      description = "Duplicates the argument: passes it twice to the function";
      speech = speech.warbler.speech;
    };
    S = {
      aka = "Starling";
      rule = "S f g x = f x (g x)";
      description = "Distributes the argument to both functions and combines results";
      speech = speech.starling.speech;
    };
    L = {
      aka = "Lark";
      rule = "L x y = x (y x)";
      description = "Applies the second argument to the first, then the first to the result";
      speech = speech.lark.speech;
    };
    V = {
      aka = "Vireo";
      rule = "V x y f = f x y";
      description = "Creates a pair: stores two values and applies a selector function";
      speech = speech.vireo.speech;
    };
    Y = {
      aka = "Sage Bird";
      rule = "Y f = f (Y f)";
      description = "Fixed-point combinator: enables recursion";
      speech = speech.sageBird.speech;
    };
  };

  # Build the birds list for autocomplete
  birdNames = builtins.attrNames birdMeta;
  birdList = map (name: {
    inherit name;
    type = typeEnv.${name};
    aka = birdMeta.${name}.aka;
    rule = birdMeta.${name}.rule;
    description = birdMeta.${name}.description;
    speech = birdMeta.${name}.speech;
  }) birdNames;

  # Algebraic laws — tested identities from the Nix test suite
  laws = [
    { name = "S K K = I"; description = "Starling-Kestrel-Kestrel reduces to Identity"; }
    { name = "W K = I"; description = "Warbler-Kestrel reduces to Identity"; }
    { name = "M I = I"; description = "Mockingbird of Identity is Identity"; }
    { name = "C K = KI"; description = "Cardinal-Kestrel equals Kite"; }
    { name = "B f I = f"; description = "Right identity of composition"; }
    { name = "B I f = f"; description = "Left identity of composition"; }
    { name = "V x y K = x"; description = "Vireo pair with Kestrel selects first"; }
    { name = "V x y KI = y"; description = "Vireo pair with Kite selects second"; }
  ];

in {
  inherit birdList laws;
  # Also expose typeEnv directly for any future use
  inherit typeEnv;
}
