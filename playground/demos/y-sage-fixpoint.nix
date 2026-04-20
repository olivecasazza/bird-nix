# Y f = f (Y f)  — fixpoint combinator
let
  factorial = Y (self: n:
    if n <= 1 then 1
    else n * self (n - 1)
  );
in {
  "5!" = factorial 5;
  "10!" = factorial 10;
}
