# Church numerals: n f x = apply f to x, n times
let
  zero  = _f: x: x;           # apply f 0 times
  one   = f: x: f x;          # apply f 1 time
  two   = f: x: f (f x);      # apply f 2 times
  three = f: x: f (f (f x));  # apply f 3 times
  succ  = n: f: x: f (n f x); # successor
  toInt = n: n (x: x + 1) 0;  # convert to Nix int
in {
  zero  = toInt zero;
  one   = toInt one;
  two   = toInt two;
  three = toInt three;
  four  = toInt (succ three);
}
