# V x y K  = K x y  = x  (select first)
# V x y KI = KI x y = y  (select second)
let pair = V "alpha" "beta";
in {
  first  = pair K;     # "alpha"
  second = pair KI;    # "beta"
}
