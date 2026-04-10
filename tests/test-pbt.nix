# test-pbt.nix — Property-based tests for bird combinators
#
# Tests algebraic laws and identities across many inputs rather than
# individual examples. Uses bird-pbt.nix for exhaustive enumeration
# over small domains.

{ }:
let
  h = import ../src/testing/test-harness.nix {};
  pbt = import ../src/testing/bird-pbt.nix {};
  birds = import ../src/birds.nix {};
  inherit (birds) I M K KI B C W S V Y L;
  inherit (pbt) forAll forAll2 forAll3 property domains;

  # Domains for combinator testing
  # We use atoms (ints, strings, bools) as opaque values passed through combinators
  vals = domains.atoms;
  ints = domains.ints;
  strs = domains.strings;

  # === IDENTITY LAWS ===
  propIdentity = pbt.toHarnessSuite "PBT: Identity Laws" [

    # I x = x for all x
    (property "∀x. I x = x (atoms)"
      (forAll vals (x: I x == x)))

    (property "∀x. I x = x (ints)"
      (forAll ints (x: I x == x)))

    (property "∀x. I x = x (strings)"
      (forAll strs (x: I x == x)))

    # I is idempotent: I (I x) = x
    (property "∀x. I (I x) = x"
      (forAll vals (x: I (I x) == x)))
  ];

  # === KESTREL LAWS ===
  propKestrel = pbt.toHarnessSuite "PBT: Kestrel Laws" [

    # K x y = x for all x, y
    (property "∀x,y. K x y = x (ints)"
      (forAll2 ints ints (x: y: K x y == x)))

    (property "∀x,y. K x y = x (strings)"
      (forAll2 strs strs (x: y: K x y == x)))

    # K x y = x for mixed types
    (property "∀x,y. K x y = x (atoms)"
      (forAll2 vals vals (x: y: K x y == x)))
  ];

  # === KITE LAWS ===
  propKite = pbt.toHarnessSuite "PBT: Kite Laws" [

    # KI x y = y for all x, y
    (property "∀x,y. KI x y = y"
      (forAll2 vals vals (x: y: KI x y == y)))

    # KI = K I (kite is kestrel applied to identity)
    # Can't directly compare functions, but we can check behavioral equivalence
    (property "∀x,y. KI x y = K I x y"
      (forAll2 vals vals (x: y: KI x y == K I x y)))
  ];

  # === CARDINAL LAWS ===
  propCardinal = pbt.toHarnessSuite "PBT: Cardinal Laws" [

    # C K = KI (flipping K gives KI)
    (property "∀x,y. C K x y = KI x y"
      (forAll2 vals vals (x: y: C K x y == KI x y)))

    # C (C K) = K (double flip restores original)
    (property "∀x,y. C (C K) x y = K x y"
      (forAll2 vals vals (x: y: C (C K) x y == K x y)))

    # C flips: C f x y = f y x (test with a concrete asymmetric f)
    (property "∀x,y. C K x y = K y x (ints)"
      (forAll2 ints ints (x: y: C K x y == K y x)))
  ];

  # === VIREO LAWS ===
  propVireo = pbt.toHarnessSuite "PBT: Vireo Laws" [

    # V x y K = x (pair with K selects first)
    (property "∀x,y. V x y K = x"
      (forAll2 vals vals (x: y: V x y K == x)))

    # V x y KI = y (pair with KI selects second)
    (property "∀x,y. V x y KI = y"
      (forAll2 vals vals (x: y: V x y KI == y)))
  ];

  # === BLUEBIRD LAWS ===
  propBluebird = pbt.toHarnessSuite "PBT: Bluebird Laws" [

    # B I f x = f x (left identity of composition)
    (property "∀x. B I I x = x"
      (forAll vals (x: B I I x == x)))

    # B f I x = f x (right identity of composition)
    (property "∀x. B I (I) x = I x"
      (forAll vals (x: B I I x == I x)))

    # B (B f g) h = B f (B g h) — associativity of composition
    # Test with concrete functions on ints
    (property "∀x. B (B inc inc) double x = inc(inc(double(x))) (ints)"
      (forAll (builtins.genList (i: i) 6) (x:
        let
          inc = a: a + 1;
          double = a: a * 2;
        in B (B inc inc) double x == inc (inc (double x)))))
  ];

  # === WARBLER LAWS ===
  propWarbler = pbt.toHarnessSuite "PBT: Warbler Laws" [

    # W K x = x (warbler-kestrel = identity)
    (property "∀x. W K x = x (atoms)"
      (forAll vals (x: W K x == x)))

    (property "∀x. W K x = I x (ints)"
      (forAll ints (x: W K x == I x)))
  ];

  # === STARLING LAWS ===
  propStarling = pbt.toHarnessSuite "PBT: Starling Laws" [

    # S K K x = x (S K K = I)
    (property "∀x. S K K x = x (atoms)"
      (forAll vals (x: S K K x == x)))

    (property "∀x. S K K x = I x (ints)"
      (forAll ints (x: S K K x == I x)))

    # S K K x = W K x (both equal I)
    (property "∀x. S K K x = W K x"
      (forAll vals (x: S K K x == W K x)))
  ];

  # === CROSS-COMBINATOR IDENTITIES ===
  propIdentities = pbt.toHarnessSuite "PBT: Cross-Combinator Identities" [

    # S K K = I (the classic)
    (property "∀x. S K K x = I x"
      (forAll vals (x: S K K x == I x)))

    # W K = I
    (property "∀x. W K x = I x"
      (forAll vals (x: W K x == I x)))

    # C K = KI
    (property "∀x,y. C K x y = KI x y"
      (forAll2 vals vals (x: y: C K x y == KI x y)))

    # B I f = f (for I as f)
    (property "∀x. B I I x = I x"
      (forAll vals (x: B I I x == I x)))

    # K I x y = y (K applied to I gives a function that ignores first arg)
    (property "∀x,y. K I x y = y"
      (forAll2 vals vals (x: y: K I x y == y)))

    # V x y K = K x y = x
    (property "∀x,y. V x y K = K x y"
      (forAll2 vals vals (x: y: V x y K == K x y)))
  ];

  # === PRNG SELF-TEST ===
  propPRNG = pbt.toHarnessSuite "PBT: PRNG Self-Test" [

    # LCG produces values in range
    (property "genRange values in [0,10]"
      (forAll (pbt.lcg.genRange 50 0 10 42).values (x: x >= 0 && x <= 10)))

    # LCG produces values in negative range
    (property "genRange values in [-5,5]"
      (forAll (pbt.lcg.genRange 50 (0 - 5) 5 123).values (x: x >= (0 - 5) && x <= 5)))

    # LCG is deterministic (same seed → same output)
    (property "LCG deterministic"
      (forAll [42 0 1 999 123456] (seed:
        (pbt.lcg.genN 10 seed).values == (pbt.lcg.genN 10 seed).values)))

    # LCG different seeds → different outputs (probabilistic but reliable)
    (property "LCG different seeds differ"
      (forAll [{ a = 42; b = 43; } { a = 0; b = 1; } { a = 100; b = 200; }]
        (pair: (pbt.lcg.genN 5 pair.a).values != (pbt.lcg.genN 5 pair.b).values)))
  ];

  # === RANDOM INPUT TESTS ===
  # Use the PRNG to generate larger test sets
  randomVals = domains.randomInts 42 50;

  propRandomized = pbt.toHarnessSuite "PBT: Randomized (50 PRNG values)" [

    (property "∀x. I x = x (random ints)"
      (forAll randomVals (x: I x == x)))

    (property "∀x,y. K x y = x (random ints)"
      (forAll2 (domains.randomInts 1 20) (domains.randomInts 2 20) (x: y: K x y == x)))

    (property "∀x. S K K x = x (random ints)"
      (forAll randomVals (x: S K K x == x)))

    (property "∀x. W K x = x (random ints)"
      (forAll randomVals (x: W K x == x)))
  ];

in
  h.combineSuites "Property-Based Tests" [
    propIdentity
    propKestrel
    propKite
    propCardinal
    propVireo
    propBluebird
    propWarbler
    propStarling
    propIdentities
    propPRNG
    propRandomized
  ]
