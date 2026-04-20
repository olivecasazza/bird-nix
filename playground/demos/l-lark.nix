# L f g = f (g g)
let
  f = x: "got: ${builtins.typeOf x}";
in L f I
