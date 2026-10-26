# Functional list operations using birds
#
# Nix cannot deconstruct a list without builtins, so the "map"/"filter"
# here are let-recursive forward builders: they grow an accumulator one
# element at a time. The combinator `B` (function composition) supplies
# the `double ∘ double` step, the same way the library exposes it.
let
  double = x: x * 2;
  quadruple = B double double;   # \x. double (double x) = 4 · x

  # Grow [f 1 .. f 10] left-to-right (acc ++ [f n]).
  dbl  = acc: n: if n > 10 then acc else dbl (acc ++ [ (double n) ]) (n + 1);
  quad = acc: n: if n > 10 then acc else quad (acc ++ [ (quadruple n) ]) (n + 1);
  # Even numbers 2,4,6,8,10.
  evens = acc: n: if n > 10 then acc else evens (acc ++ [ n ]) (n + 2);
  # Sum 1..10 by counting down.
  sum = acc: n: if n == 0 then acc else sum (acc + n) (n - 1);
in {
  doubled  = dbl [] 1;    # [2 4 6 8 10 12 14 16 18 20]
  evens    = evens [] 2;  # [2 4 6 8 10]
  summed   = sum 0 10;    # 55
  composed = quad [] 1;   # [4 8 12 16 20 24 28 32 36 40]
}
