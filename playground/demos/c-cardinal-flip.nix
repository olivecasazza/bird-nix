# C f x y = f y x  — argument flipper
let
  greet = first: second: "${first}, ${second}!";
in C greet "world" "hello"
