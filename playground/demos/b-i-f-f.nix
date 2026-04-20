# B I f = f  (left identity)
let
  addOne = x: x + 1;
  composed = B I addOne;
in {
  direct   = addOne 7;
  composed = composed 7;
  equal    = addOne 7 == composed 7;
}
