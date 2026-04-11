{ }:
let
  h = import ./test-harness.nix {};
  bn = import ../src {};

  # Convenience aliases
  eq = h.assertEq;
  ok = h.assertTrue;
  nok = h.assertFalse;
  eval = h.assertEval;
  suite = h.runSuite;

  # Test I — Identity Bird
  suite-I = suite "I — Identity Bird" [
    (eq "I hello" (bn.identityBird.call "hello") "hello")
    (eq "I 42" (bn.identityBird.call 42) 42)
    (eq "I true" (bn.identityBird.call true) true)
    (eq "I [1 2]" (bn.identityBird.call [1 2]) [1 2])
    (eq "I function applied" ((bn.identityBird.call (x: x)) 5) 5)
  ];

  # Test K — Kestrel
  suite-K = suite "K — Kestrel" [
    (eq "K a b" ((bn.kestrel.call "a") "b") "a")
    (eq "K 1 2" ((bn.kestrel.call 1) 2) 1)
    (eq "K true false" ((bn.kestrel.call true) false) true)
    (eq "K partial" ((bn.kestrel.call "locked") "ignored") "locked")
  ];

  # Test KI — Kite
  suite-KI = suite "KI — Kite" [
    (eq "KI a b" ((bn.kite.call "a") "b") "b")
    (eq "KI 1 2" ((bn.kite.call 1) 2) 2)
  ];

  # Test B — Bluebird (composition)
  suite-B = suite "B — Bluebird" [
    (eq "B comp" ((bn.bluebird.call (x: x + 1) (x: x * 2)) 5) 11)
    (eq "B toString" (((bn.bluebird.call builtins.toString) (x: x + 1)) 9) "10")
    (eq "B I I" ((bn.bluebird.call bn.identityBird.call bn.identityBird.call) 42) 42)
  ];

  # Test W — Warbler
  suite-W = suite "W — Warbler" [
    (eq "W K" ((bn.warbler.call bn.kestrel.call) "anything") "anything")
    (eq "W add" (((bn.warbler.call (a: b: a + b)) 5)) 10)
  ];

  # Test S — Starling
  suite-S = suite "S — Starling" [
    (eq "S K K string" ((bn.starling.call bn.kestrel.call bn.kestrel.call) "test") "test")
    (eq "S K K int" ((bn.starling.call bn.kestrel.call bn.kestrel.call) 42) 42)
  ];

  # Test C — Cardinal (flip)
  suite-C = suite "C — Cardinal" [
    (eq "C K a b" (bn.cardinal.call bn.kestrel.call "a" "b") "b")
    (eq "C K 1 2" (bn.cardinal.call bn.kestrel.call 1 2) 2)
  ];

  # Test V — Vireo (pair)
  suite-V = suite "V — Vireo" [
    (eq "V a b K" (bn.vireo.call "a" "b" bn.kestrel.call) "a")
    (eq "V a b KI" (bn.vireo.call "a" "b" bn.kite.call) "b")
  ];

  # Test Combinator Laws
  suite-laws = suite "Combinator Laws" [
    # S K K x = I x
    (eq "S K K = I (string)" ((bn.starling.call bn.kestrel.call bn.kestrel.call) "a") (bn.identityBird.call "a"))
    (eq "S K K = I (int)" ((bn.starling.call bn.kestrel.call bn.kestrel.call) 1) (bn.identityBird.call 1))
    (eq "S K K = I (bool)" ((bn.starling.call bn.kestrel.call bn.kestrel.call) true) (bn.identityBird.call true))
    # W K x = I x
    (eq "W K = I (string)" ((bn.warbler.call bn.kestrel.call) "a") (bn.identityBird.call "a"))
    (eq "W K = I (int)" ((bn.warbler.call bn.kestrel.call) 1) (bn.identityBird.call 1))
    (eq "W K = I (bool)" ((bn.warbler.call bn.kestrel.call) true) (bn.identityBird.call true))
    # B f I x = f x
    (eq "B f I" ((bn.bluebird.call (x: x * 2) bn.identityBird.call) 5) 10)
    # B I f x = f x
    (eq "B I f" ((bn.bluebird.call bn.identityBird.call (x: x * 2)) 5) 10)
    # K x y = x
    (eq "K x y str" ((bn.kestrel.call "x") "y") "x")
    (eq "K x y int" ((bn.kestrel.call 100) 200) 100)
    # C K = KI (Cardinal flips Kestrel to Kite)
    (eq "C K = KI" (bn.cardinal.call bn.kestrel.call "a" "b") (bn.kite.call "a" "b"))
  ];

  # Test DSL pipe
  suite-dsl-pipe = suite "DSL pipe" [
    (eq "pipe I" (bn.pipe "hello" [bn.identityBird.call]) "hello")
    (eq "pipe comp" (bn.pipe 5 [(x: x * 2) (x: x + 1)]) 11)
    (eq "pipe empty" (bn.pipe "hello" []) "hello")
    (eq "pipe chain" (bn.pipe 0 [(x: x + 1) (x: x + 1) (x: x + 1)]) 3)
  ];

  # Test DSL birdMap
  suite-dsl-map = suite "DSL birdMap" [
    (eq "birdMap I" (bn.birdMap."I" "test") "test")
    (eq "birdMap K" ((bn.birdMap."K" "a") "b") "a")
    (eq "birdMap KI" ((bn.birdMap."KI" "a") "b") "b")
    (eq "birdMap B" (((bn.birdMap."B" (x: x + 1)) (x: x * 2)) 5) 11)
    (eq "birdMap W" ((bn.birdMap."W" (a: b: a + b)) 5) 10)
    (eq "birdMap S" (((bn.birdMap."S" (x: y: x)) (x: y: y)) "a") "a")
    (eq "birdMap C" (bn.birdMap."C" bn.kestrel.call "a" "b") "b")
    (eq "birdMap V" (bn.birdMap."V" "a" "b" bn.kestrel.call) "a")
  ];

  # Test Speech birds
  suite-speech = suite "Speech birds" [
    (eq "speech.identityBird" (bn.identityBird.call (x: x + 1) 5) 6)
    (eq "speech.kestrel" (bn.kestrel.call "first" "second") "first")
    (eq "speech.kite" (bn.kite.call "first" "second") "second")
    (eq "speech.bluebird" (((bn.bluebird.call (x: x + 1)) (x: x * 2)) 3) 7)
    (eq "speech.warbler" ((bn.warbler.call bn.kestrel.call) "A") "A")
    (eq "speech.starling" (bn.starling.call bn.kestrel.call bn.kestrel.call 42) 42)
    (ok "speech.attrs" (bn.sentences != {}))
    (eq "speech.sentence.identityEcho" bn.sentences.identityEcho.result 6)
    (eq "speech.sentence.kestrelChoice" bn.sentences.kestrelChoice.result "first-choice")
    (eq "speech.sentence.kiteChoice" bn.sentences.kiteChoice.result "second-choice")
    (eq "speech.sentence.bluebirdDemo" bn.sentences.bluebirdDemo.result 7)
    (eq "speech.sentence.warblerDemo" bn.sentences.warblerDemo.result "A")
    (eq "speech.sentence.starlingDemo" bn.sentences.starlingDemo.result 42)
    (eq "speech.cardinal" (bn.cardinal.call bn.kestrel.call "first" "second") "second")
    (eq "speech.vireo" (bn.vireo.call "a" "b" bn.kestrel.call) "a")
    (eq "speech.sentence.cardinalDemo" bn.sentences.cardinalDemo.result "second")
    (eq "speech.sentence.vireoDemo" bn.sentences.vireoDemo.result "a")
  ];

in
  h.combineSuites "Bird Combinator Tests" [
    suite-I
    suite-K
    suite-KI
    suite-B
    suite-W
    suite-S
    suite-C
    suite-V
    suite-laws
    suite-dsl-pipe
    suite-dsl-map
    suite-speech
  ]
