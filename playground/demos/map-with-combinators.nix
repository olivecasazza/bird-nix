# Functional list operations using birds
let
  data = [1 2 3 4 5 6 7 8 9 10];
  double = x: x * 2;
  isEven = x: builtins.div x 2 * 2 == x;
in {
  doubled = builtins.map double data;
  evens   = builtins.filter isEven data;
  summed  = builtins.foldl' (a: b: a + b) 0 data;
  composed = builtins.map (B double double) data;  # quadruple
}
