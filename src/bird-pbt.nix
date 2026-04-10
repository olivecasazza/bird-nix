# bird-pbt.nix — Property-Based Testing for pure Nix
#
# A SmallCheck/QuickCheck-style PBT framework implemented in pure Nix.
# Since Nix has no IO or randomness, we use two strategies:
#   1. Exhaustive enumeration over small finite domains (SmallCheck-style)
#   2. Deterministic PRNG (LCG) for pseudo-random sampling (QuickCheck-style)
#
# Dogfoods birds.nix — uses K for selection, B for composition, pipe for chaining.
#
# Usage:
#   forAll domains.ints (x: x + 0 == x)           -- universally quantified
#   forAll2 domains.ints domains.ints (x: y: ...)  -- two quantifiers
#   property "name" (forAll ...)                    -- named property
#   checkProperties [prop1 prop2 ...]              -- run and summarize

{ }:

let
  # === BIRD BOOTSTRAP ===
  birds = import ./birds.nix {};
  inherit (birds) I K KI B W S C V;

  # === DETERMINISTIC PRNG ===
  # Linear Congruential Generator: next = (a * seed + c) mod m
  # Using Numerical Recipes constants (works well with 64-bit Nix ints)
  lcg = {
    # LCG parameters (Numerical Recipes)
    a = 1664525;
    c = 1013904223;
    # Use 2^30 to stay safely in Nix int range (no overflow)
    m = 1073741824;

    # Advance the PRNG state by one step
    next = seed: let raw = seed * lcg.a + lcg.c; in raw - (raw / lcg.m) * lcg.m;

    # Generate a list of N pseudo-random ints from a seed
    # Returns { values: [int]; seed: int; }
    genN = n: seed:
      let
        step = acc:
          if builtins.length acc.values >= n then acc
          else
            let s = lcg.next acc.seed;
            in step { values = acc.values ++ [s]; seed = s; };
      in step { values = []; inherit seed; };

    # Generate N ints in range [lo, hi] from a seed
    genRange = n: lo: hi: seed:
      let
        raw = lcg.genN n seed;
        range = hi - lo + 1;
        clamp = v: lo + (if v < 0 then (0 - v) else v) - ((if v < 0 then (0 - v) else v) / range) * range;
      in {
        values = builtins.map clamp raw.values;
        seed = raw.seed;
      };
  };

  # === DOMAINS (value generators for enumeration) ===
  domains = {
    # Boolean domain — exhaustive
    bools = [true false];

    # Small integers — exhaustive over a useful range
    ints = builtins.genList (i: i - 5) 11;  # [-5 .. 5]

    # Positive integers
    posInts = builtins.genList (i: i + 1) 10;  # [1 .. 10]

    # Natural numbers
    nats = builtins.genList (i: i) 11;  # [0 .. 10]

    # Strings
    strings = ["" "a" "b" "hello" "world" "foo" "bar"];

    # Values that can be compared with == (mixed types)
    atoms = [0 1 2 "a" "b" true false null [] [1] [1 2]];

    # Small integer pairs
    intPairs = builtins.concatMap (x:
      builtins.map (y: { fst = x; snd = y; })
        (builtins.genList (i: i - 3) 7)
    ) (builtins.genList (i: i - 3) 7);

    # Pseudo-random ints (100 values from seed 42)
    randomInts = seed: n: (lcg.genRange n (0 - 100) 100 seed).values;

    # Custom domain from a list
    fromList = xs: xs;

    # Cartesian product of two domains
    cross = xs: ys: builtins.concatMap (x:
      builtins.map (y: { fst = x; snd = y; }) ys
    ) xs;
  };

  # === PROPERTY RUNNERS ===

  # forAll: test a property over every element of a domain
  # Returns { ok, total, failures, counterexamples }
  forAll = domain: prop:
    let
      results = builtins.map (x:
        let
          r = builtins.tryEval (builtins.deepSeq (prop x) (prop x));
        in {
          input = x;
          pass = r.success && r.value == true;
          error = !r.success;
          value = if r.success then r.value else null;
        }
      ) domain;
      failures = builtins.filter (r: !r.pass) results;
    in {
      ok = builtins.length failures == 0;
      total = builtins.length results;
      failed = builtins.length failures;
      counterexamples = builtins.map (r: r.input) failures;
      # First counterexample for quick debugging
      firstCounter = if builtins.length failures > 0
        then builtins.head (builtins.map (r: r.input) failures)
        else null;
    };

  # forAll2: test a binary property over the cartesian product
  forAll2 = domainA: domainB: prop:
    let
      results = builtins.concatMap (a:
        builtins.map (b:
          let
            r = builtins.tryEval (builtins.deepSeq (prop a b) (prop a b));
          in {
            inputA = a;
            inputB = b;
            pass = r.success && r.value == true;
            error = !r.success;
          }
        ) domainB
      ) domainA;
      failures = builtins.filter (r: !r.pass) results;
    in {
      ok = builtins.length failures == 0;
      total = builtins.length results;
      failed = builtins.length failures;
      counterexamples = builtins.map (r: { a = r.inputA; b = r.inputB; }) failures;
      firstCounter = if builtins.length failures > 0
        then { a = (builtins.head failures).inputA; b = (builtins.head failures).inputB; }
        else null;
    };

  # forAll3: test a ternary property
  forAll3 = domainA: domainB: domainC: prop:
    let
      results = builtins.concatMap (a:
        builtins.concatMap (b:
          builtins.map (c:
            let
              r = builtins.tryEval (builtins.deepSeq (prop a b c) (prop a b c));
            in {
              inputA = a;
              inputB = b;
              inputC = c;
              pass = r.success && r.value == true;
              error = !r.success;
            }
          ) domainC
        ) domainB
      ) domainA;
      failures = builtins.filter (r: !r.pass) results;
    in {
      ok = builtins.length failures == 0;
      total = builtins.length results;
      failed = builtins.length failures;
      counterexamples = builtins.map (r: {
        a = r.inputA; b = r.inputB; c = r.inputC;
      }) failures;
      firstCounter = if builtins.length failures > 0
        then {
          a = (builtins.head failures).inputA;
          b = (builtins.head failures).inputB;
          c = (builtins.head failures).inputC;
        }
        else null;
    };

  # === PROPERTY CONSTRUCTORS ===

  # Named property: wraps a forAll result with metadata
  property = name: result:
    result // {
      inherit name;
      status = if result.ok then "PASS" else "FAIL";
      msg = if result.ok
        then "${name}: OK (${toString result.total} cases)"
        else "${name}: FAILED (${toString result.failed}/${toString result.total} cases, counterexample: ${builtins.toJSON result.firstCounter})";
    };

  # === SUITE RUNNER ===

  # Run a list of named properties, produce summary compatible with test-harness
  checkProperties = name: props:
    let
      total = builtins.foldl' (a: p: a + p.total) 0 props;
      propsPassed = builtins.length (builtins.filter (p: p.ok) props);
      propsFailed = builtins.length (builtins.filter (p: !p.ok) props);
      failures = builtins.filter (p: !p.ok) props;
      propLines = builtins.map (p: "  ${p.msg}") props;
    in {
      inherit name total props;
      ok = propsFailed == 0;
      propsTotal = builtins.length props;
      propsPassed = propsPassed;
      propsFailed = propsFailed;
      failures = failures;
      summary = builtins.concatStringsSep "\n" ([
        "═══════════════════════════════════════════"
        "  PBT: ${name}"
        "═══════════════════════════════════════════"
      ] ++ propLines ++ [
        "───────────────────────────────────────────"
        ("  PROPERTIES: ${toString propsPassed}/${toString (builtins.length props)} passed, ${toString total} total cases"
        + (if propsFailed > 0 then " (${toString propsFailed} FAILED)" else " ALL PASSED"))
        "═══════════════════════════════════════════"
      ]);
    };

  # === HARNESS INTEGRATION ===
  # Convert a PBT property to a test-harness compatible test result
  # so PBT suites can be mixed into combineSuites
  toHarnessTest = prop: {
    name = prop.name;
    pass = prop.ok;
    actual = if prop.ok then true else prop.firstCounter;
    expected = true;
    status = prop.status;
    msg = prop.msg;
  };

  toHarnessSuite = name: props: {
    inherit name;
    total = builtins.length props;
    passed = builtins.length (builtins.filter (p: p.ok) props);
    failed = builtins.length (builtins.filter (p: !p.ok) props);
    ok = builtins.length (builtins.filter (p: !p.ok) props) == 0;
    failures = builtins.filter (p: !p.ok) (builtins.map toHarnessTest props);
    summary = "${name}: ${toString (builtins.length (builtins.filter (p: p.ok) props))}/${toString (builtins.length props)} passed"
      + (if builtins.length (builtins.filter (p: !p.ok) props) > 0
         then " (${toString (builtins.length (builtins.filter (p: !p.ok) props))} FAILED)"
         else "");
    failureMessages = builtins.map (p: p.msg) (builtins.filter (p: !p.ok) props);
  };

in {
  inherit lcg domains;
  inherit forAll forAll2 forAll3;
  inherit property checkProperties;
  inherit toHarnessTest toHarnessSuite;
}
