# B f g x = f (g x)  — function composition
let
  double = x: x * 2;
  addOne = x: x + 1;
in B addOne double 5
