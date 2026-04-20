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
in {
  "5!"  = factorial 5;
  "10!" = factorial 10;
  fib10 = fibonacci 10;
  fibs  = builtins.genList fibonacci 12;
}
