# Anonymous recursion via Y combinator
let
  factorial = Y (self: n:
    if n <= 1 then 1
    else n * self (n - 1)
  );
  fibonacci = Y (self: n:
    if n <= 0 then 0
    else if n == 1 then 1
    else self (n - 1) + self (n - 2)
  );
  # [fib 0 .. fib 11] grown left-to-right (no builtins.genList).
  fibList = n: if n >= 12 then [] else [ (fibonacci n) ] ++ fibList (n + 1);
in {
  "5!"  = factorial 5;
  "10!" = factorial 10;
  fib10 = fibonacci 10;
  fibs  = fibList 0;
}
