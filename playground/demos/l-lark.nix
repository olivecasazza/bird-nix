# L f g = f (g g)
#
# With g = I, the self-application (I I) reduces to I, so `L f I` calls
# `f` with a lambda. The result names that concrete value directly.
let
  f = x: "got: lambda";
in L f I
