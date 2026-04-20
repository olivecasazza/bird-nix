# C K x y = K y x = y  (same as KI)
let
  ck = C K;
in {
  ck_result = ck "first" "second";    # "second"
  ki_result = KI "first" "second";    # "second"
  equal     = ck "a" "b" == KI "a" "b";
}
