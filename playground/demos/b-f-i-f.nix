# B f I = f  (right identity)
let
  double = x: x * 2;
  composed = B double I;
in {
  direct   = double 7;
  composed = composed 7;
  equal    = double 7 == composed 7;
}
