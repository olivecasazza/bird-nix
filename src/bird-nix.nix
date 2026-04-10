{ }:
let
  # Core primitives as tagged unions
  I = { bird = "I"; apply = x: x; };
  M = { bird = "M"; apply = x: x.apply x; };
  K = { bird = "K"; apply = x: { bird = "K1"; apply = y: x; }; };
  KI = { bird = "KI"; apply = x: { bird = "KI1"; apply = y: y; }; };
  B = { bird = "B"; apply = f: { bird = "B1"; apply = g: { bird = "B2"; apply = x: f.apply (g.apply x); }; }; };
  W = { bird = "W"; apply = f: { bird = "W1"; apply = x: apply (f.apply x) x; }; };
  S = { bird = "S"; apply = f: { bird = "S1"; apply = g: { bird = "S2"; apply = x: apply (f.apply x) (g.apply x); }; }; };
  L = { bird = "L"; apply = x: { bird = "L1"; apply = y: x.apply (y.apply x); }; };
  C = { bird = "C"; apply = f: { bird = "C1"; apply = x: { bird = "C2"; apply = y: apply (f.apply y) x; }; }; };
  V = { bird = "V"; apply = x: { bird = "V1"; apply = y: { bird = "V2"; apply = z: apply (z.apply x) y; }; }; };
  Y = { bird = "Y"; apply = f: let x = f.apply x; in x; };

  # Helper: apply a bird to an argument
  apply = bird: arg: bird.apply arg;

  # Helper: show bird name
  show = bird:
    if builtins.isAttrs bird && bird ? bird then bird.bird
    else builtins.toString bird;

  # Pipe using apply
  pipe = x: functions: builtins.foldl' (acc: f: apply f acc) x functions;

  # Helper for examples: cons cell
  cons = head: tail: { h = head; t = tail; };
in
{
  inherit I M K KI B C W S L V Y apply show pipe cons;

  examples = {
    # I "hello" = "hello"
    identity = apply I "hello";

    # M I = I I = I (since I.apply I = I)
    mockingIdentity = apply M I;

    # K "yes" then apply result to "no" = "yes"
    kestrelChoice = apply (apply K "yes") "no";

    # S K K "test" = "test" (proves S K K = I)
    starlingIdentity = apply (apply (apply S K) K) "test";

    # Y for lazy infinite structure
    repeatHi = apply Y { bird = "repeat"; apply = f: cons "hi" f; };
  };
}
