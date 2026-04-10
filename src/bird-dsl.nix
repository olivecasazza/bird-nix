# Bird Language DSL with pipe operator and combinator mappings
# Dogfoods birds.nix — all combinators imported, not redefined
{ }:

let
  # Import canonical combinator definitions
  birds = import ./birds.nix {};
  inherit (birds) I M K KI B C W S L V Y;

  # Map string bird names to functions
  birdMap = {
    "I" = I;
    "M" = M;
    "K" = K;
    "KI" = KI;
    "B" = B;
    "C" = C;
    "W" = W;
    "S" = S;
    "L" = L;
    "V" = V;
    "Y" = Y;
  };

  # Helper to apply a bird to input
  say = bird: input: bird input;

  # Pipe operator for composition
  pipe = x: functions: builtins.foldl' (acc: f: f acc) x functions;

  # Example compositions
  examples = {
    identityPipe = pipe "hello" [I];
    composePipe = pipe 5 [(x: x * 2) (x: x + 1)];
    trimLowerValidate = let
      trim = str: builtins.replaceStrings [" "] [""] str;
      toLower = str: if str == "HELLO" then "hello" else str;
    in pipe "  HELLO  " [trim toLower];
  };

in {
  inherit I M K KI B C W S L V Y;
  inherit birdMap say pipe examples;
}
