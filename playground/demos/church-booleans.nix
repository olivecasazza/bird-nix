# Church booleans from bird combinators
let
  true_  = K;      # K x y = x  (select first)
  false_ = KI;     # KI x y = y (select second)
  not_   = C;      # C f x y = f y x (flip)
  and_   = a: b: a b false_;
  or_    = a: b: a true_ b;
in {
  T_and_T = (and_ true_ true_)   "yes" "no";
  T_and_F = (and_ true_ false_)  "yes" "no";
  F_or_T  = (or_ false_ true_)   "yes" "no";
  not_T   = (not_ true_)         "yes" "no";
  not_F   = (not_ false_)        "yes" "no";
}
