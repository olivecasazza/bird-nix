# S f g x = f x (g x)  — fork-join
let
  add = x: y: x + y;
  double = x: x * 2;
in S add double 3
