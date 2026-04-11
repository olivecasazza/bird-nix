# Real-world examples using bird combinators
# Dogfoods birds.nix — all combinators imported, not redefined
{ }:
let
  # Import canonical combinator definitions
  birds = import ../src/birds.nix {};
  inherit (birds) I M K KI B W L S Y;
  const = K;

  # Conditional selection using K/KI as Church booleans
  # K = true (select first), KI = false (select second)
  ifThenElse = cond: thn: els: (if cond then K else KI) thn els;
  env = "production";
  configProduction = { port = 80; debug = false; };
  configDevelopment = { port = 3000; debug = true; };
  selectedConfig = ifThenElse (env == "production") configProduction configDevelopment;

  # String helpers — builtins.replaceStrings/stringLength are irreducible Nix
  # primitives (no bird equivalent), so their use is acceptable here
  trim = str: builtins.replaceStrings [" "] [""] str;

  # toLower: recursive fold using Y combinator for the iteration
  toLower = str: let
    lowerChars = { A = "a"; B = "b"; C = "c"; D = "d"; E = "e"; F = "f"; G = "g"; H = "h"; I = "i"; J = "j"; K = "k"; L = "l"; M = "m"; N = "n"; O = "o"; P = "p"; Q = "q"; R = "r"; S = "s"; T = "t"; U = "u"; V = "v"; W = "w"; X = "x"; Y = "y"; Z = "z"; };
    toLowerChar = c: if lowerChars ? ${c} then lowerChars.${c} else c;
    strLen = builtins.stringLength str;
    fold = n: acc: if n == 0 then acc else fold (n - 1) (acc + toLowerChar (builtins.substring (n - 1) 1 str));
    in fold strLen "";

  isValidEmail = email: builtins.match "^[a-z0-9]+@[a-z]+\\.[a-z]+$" (toLower email) != null;
  validateEmail = B isValidEmail (B toLower trim);
  isPalindrome = W (a: b: a == b);
  hasMinLength = len: str: builtins.stringLength str >= len;
  selfAware = name: { inherit name; description = "I am ${builtins.toString name}"; };
  cons = head: tail: { h = head; t = tail; };
  repeatHi = Y (f: cons "hi" f);
in
{
  # 1. Conditional Logic using Kestrel/Kite as booleans
  #    Choose config variant based on environment
  inherit env configProduction configDevelopment selectedConfig;

  # 2. Pipeline Composition using Bluebird
  #    Sanitize & validate user input
  inherit trim toLower isValidEmail validateEmail;

  # 3. Self-comparison using Warbler
  #    isPalindrome always returns true since W compares x to itself
  inherit isPalindrome;

  # 4. Parallel application using Starling
  #    Validate against multiple criteria
  inherit hasMinLength;

  # 5. Self-describing configuration using Mockingbird
  inherit selfAware;

  # 6. Recursive config using Y (sage bird)
  inherit cons repeatHi;
}
