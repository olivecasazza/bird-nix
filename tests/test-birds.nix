{ }:
let
  h = import ../src/testing/test-harness.nix {};
  birds = import ../src/birds.nix {};
  speech = import ../src/birds-speech.nix {};
  dsl = import ../src/bird-dsl.nix {};

  # Convenience aliases
  eq = h.assertEq;
  ok = h.assertTrue;
  nok = h.assertFalse;
  eval = h.assertEval;
  suite = h.runSuite;

  # Test I — Identity Bird
  suite-I = suite "I — Identity Bird" [
    (eq "I hello" (birds.I "hello") "hello")
    (eq "I 42" (birds.I 42) 42)
    (eq "I true" (birds.I true) true)
    (eq "I [1 2]" (birds.I [1 2]) [1 2])
    (eq "I function applied" ((birds.I (x: x)) 5) 5)
  ];

  # Test K — Kestrel
  suite-K = suite "K — Kestrel" [
    (eq "K a b" ((birds.K "a") "b") "a")
    (eq "K 1 2" ((birds.K 1) 2) 1)
    (eq "K true false" ((birds.K true) false) true)
    (eq "K partial" ((birds.K "locked") "ignored") "locked")
  ];

  # Test KI — Kite
  suite-KI = suite "KI — Kite" [
    (eq "KI a b" ((birds.KI "a") "b") "b")
    (eq "KI 1 2" ((birds.KI 1) 2) 2)
  ];

  # Test B — Bluebird (composition)
  suite-B = suite "B — Bluebird" [
    (eq "B comp" ((birds.B (x: x + 1) (x: x * 2)) 5) 11)
    (eq "B toString" (((birds.B builtins.toString) (x: x + 1)) 9) "10")
    (eq "B I I" ((birds.B birds.I birds.I) 42) 42)
  ];

  # Test W — Warbler
  suite-W = suite "W — Warbler" [
    (eq "W K" ((birds.W birds.K) "anything") "anything")
    (eq "W add" (((birds.W (a: b: a + b)) 5)) 10)
  ];

  # Test S — Starling
  suite-S = suite "S — Starling" [
    (eq "S K K string" ((birds.S birds.K birds.K) "test") "test")
    (eq "S K K int" ((birds.S birds.K birds.K) 42) 42)
  ];

  # Test C — Cardinal (flip)
  suite-C = suite "C — Cardinal" [
    (eq "C K a b" (birds.C birds.K "a" "b") "b")
    (eq "C K 1 2" (birds.C birds.K 1 2) 2)
  ];

  # Test V — Vireo (pair)
  suite-V = suite "V — Vireo" [
    (eq "V a b K" (birds.V "a" "b" birds.K) "a")
    (eq "V a b KI" (birds.V "a" "b" birds.KI) "b")
  ];

  # Test Combinator Laws
  suite-laws = suite "Combinator Laws" [
    # S K K x = I x
    (eq "S K K = I (string)" ((birds.S birds.K birds.K) "a") (birds.I "a"))
    (eq "S K K = I (int)" ((birds.S birds.K birds.K) 1) (birds.I 1))
    (eq "S K K = I (bool)" ((birds.S birds.K birds.K) true) (birds.I true))
    # W K x = I x
    (eq "W K = I (string)" ((birds.W birds.K) "a") (birds.I "a"))
    (eq "W K = I (int)" ((birds.W birds.K) 1) (birds.I 1))
    (eq "W K = I (bool)" ((birds.W birds.K) true) (birds.I true))
    # B f I x = f x
    (eq "B f I" ((birds.B (x: x * 2) birds.I) 5) 10)
    # B I f x = f x
    (eq "B I f" ((birds.B birds.I (x: x * 2)) 5) 10)
    # K x y = x
    (eq "K x y str" ((birds.K "x") "y") "x")
    (eq "K x y int" ((birds.K 100) 200) 100)
    # C K = KI (Cardinal flips Kestrel to Kite)
    (eq "C K = KI" (birds.C birds.K "a" "b") (birds.KI "a" "b"))
  ];

  # Test DSL pipe
  suite-dsl-pipe = suite "DSL pipe" [
    (eq "pipe I" (dsl.pipe "hello" [dsl.I]) "hello")
    (eq "pipe comp" (dsl.pipe 5 [(x: x * 2) (x: x + 1)]) 11)
    (eq "pipe empty" (dsl.pipe "hello" []) "hello")
    (eq "pipe chain" (dsl.pipe 0 [(x: x + 1) (x: x + 1) (x: x + 1)]) 3)
  ];

  # Test DSL birdMap
  suite-dsl-map = suite "DSL birdMap" [
    (eq "birdMap I" (dsl.birdMap."I" "test") "test")
    (eq "birdMap K" ((dsl.birdMap."K" "a") "b") "a")
    (eq "birdMap KI" ((dsl.birdMap."KI" "a") "b") "b")
    (eq "birdMap B" (((dsl.birdMap."B" (x: x + 1)) (x: x * 2)) 5) 11)
    (eq "birdMap W" ((dsl.birdMap."W" (a: b: a + b)) 5) 10)
    (eq "birdMap S" (((dsl.birdMap."S" (x: y: x)) (x: y: y)) "a") "a")
    (eq "birdMap C" (dsl.birdMap."C" birds.K "a" "b") "b")
    (eq "birdMap V" (dsl.birdMap."V" "a" "b" birds.K) "a")
  ];

  # Test Speech birds
  suite-speech = suite "Speech birds" [
    (eq "speech.identityBird" (speech.identityBird.call (x: x + 1) 5) 6)
    (eq "speech.kestrel" (speech.kestrel.call "first" "second") "first")
    (eq "speech.kite" (speech.kite.call "first" "second") "second")
    (eq "speech.bluebird" (((speech.bluebird.call (x: x + 1)) (x: x * 2)) 3) 7)
    (eq "speech.warbler" ((speech.warbler.call speech.kestrel.call) "A") "A")
    (eq "speech.starling" (speech.starling.call speech.kestrel.call speech.kestrel.call 42) 42)
    (ok "speech.attrs" (speech != {}))
    (eq "speech.sentence.identityEcho" speech.sentences.identityEcho.result 6)
    (eq "speech.sentence.kestrelChoice" speech.sentences.kestrelChoice.result "first-choice")
    (eq "speech.sentence.kiteChoice" speech.sentences.kiteChoice.result "second-choice")
    (eq "speech.sentence.bluebirdDemo" speech.sentences.bluebirdDemo.result 7)
    (eq "speech.sentence.warblerDemo" speech.sentences.warblerDemo.result "A")
    (eq "speech.sentence.starlingDemo" speech.sentences.starlingDemo.result 42)
    (eq "speech.cardinal" (speech.cardinal.call speech.kestrel.call "first" "second") "second")
    (eq "speech.vireo" (speech.vireo.call "a" "b" speech.kestrel.call) "a")
    (eq "speech.sentence.cardinalDemo" speech.sentences.cardinalDemo.result "second")
    (eq "speech.sentence.vireoDemo" speech.sentences.vireoDemo.result "a")
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
