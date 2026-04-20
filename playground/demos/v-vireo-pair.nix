# V x y f = f x y  — pair constructor
let
  pair = V "first" "second";
in {
  fst = pair K;    # K "first" "second" = "first"
  snd = pair KI;   # KI "first" "second" = "second"
}
