# test-compiler.nix — Unit tests for bird-compiler.nix

{ }:
let
  h = import ../src/test-harness.nix {};
  c = import ../src/bird-compiler.nix {};
  f = import ../src/bird-format.nix {};

  # Convenience aliases
  eq = h.assertEq;
  ok = h.assertTrue;
  suite = h.runSuite;

  # Suite 1: AST Construction
  suiteAST = suite "AST Construction" [
    (eq "mkBird \"I\"" (c.mkBird "I").op "Bird")
    (eq "mkBird \"I\" name" (c.mkBird "I").name "I")
    (eq "mkApp" (c.mkApp (c.mkBird "K") (c.mkBird "S")).op "App")
    (eq "mkLambda" (c.mkLambda "x" (c.mkVar "x")).op "Lambda")
    (eq "mkVar" (c.mkVar "y").op "Var")
  ];

  # Suite 2: Rewrite Rules
  suiteRewrite = suite "Rewrite Rules" [
    # S K K -> I
    (eq "S K K rewrites to I" (c.rewrite (c.mkApp (c.mkApp (c.mkBird "S") (c.mkBird "K")) (c.mkBird "K"))).op "Bird")
    (eq "S K K rewrites to I name" (c.rewrite (c.mkApp (c.mkApp (c.mkBird "S") (c.mkBird "K")) (c.mkBird "K"))).name "I")
    # W K -> I
    (eq "W K rewrites to I" (c.rewrite (c.mkApp (c.mkBird "W") (c.mkBird "K"))).op "Bird")
    (eq "W K rewrites to I name" (c.rewrite (c.mkApp (c.mkBird "W") (c.mkBird "K"))).name "I")
    # K x y -> x
    (eq "K x y rewrites to x" (c.rewrite (c.mkApp (c.mkApp (c.mkBird "K") (c.mkBird "a")) (c.mkBird "b"))).op "Bird")
    (eq "K x y rewrites to x name" (c.rewrite (c.mkApp (c.mkApp (c.mkBird "K") (c.mkBird "a")) (c.mkBird "b"))).name "a")
    # M I -> I
    (eq "M I rewrites to I" (c.rewrite (c.mkApp (c.mkBird "M") (c.mkBird "I"))).op "Bird")
    (eq "M I rewrites to I name" (c.rewrite (c.mkApp (c.mkBird "M") (c.mkBird "I"))).name "I")
  ];

  # Suite 3: Compile
  suiteCompile = suite "Compile" [
    # I compiles to identity function
    (eq "compile I" ((c.compile (c.mkBird "I")) "hello") "hello")
    # K compiles to const function
    (eq "compile K" (((c.compile (c.mkBird "K")) "a") "b") "a")
    # S compiles to starling function
    (eq "compile S" (((c.compile (c.mkBird "S")) (c.compile (c.mkBird "K"))) (c.compile (c.mkBird "K")) "test") "test")
    # S K K compiles to identity
    (eq "compile S K K" ((c.compile (c.rewrite (c.mkApp (c.mkApp (c.mkBird "S") (c.mkBird "K")) (c.mkBird "K")))) "hello") "hello")
    # C compiles to flip
    (eq "compile C" (((c.compile (c.mkBird "C")) (c.compile (c.mkBird "K"))) "a" "b") "b")
    # V compiles to pair constructor
    (eq "compile V" (((c.compile (c.mkBird "V")) "a") "b" (c.compile (c.mkBird "K"))) "a")
  ];

  # Suite 4: Type Inference
  suiteType = suite "Type Inference" [
    (eq "inferType I" (c.inferType (c.mkBird "I")) "a -> a")
    (eq "inferType K" (c.inferType (c.mkBird "K")) "a -> b -> a")
    (eq "inferType S" (c.inferType (c.mkBird "S")) "(a -> b -> c) -> (a -> b) -> a -> c")
    (eq "inferType C" (c.inferType (c.mkBird "C")) "(a -> b -> c) -> b -> a -> c")
    (eq "inferType V" (c.inferType (c.mkBird "V")) "a -> b -> (a -> b -> c) -> c")
    (eq "inferType App" (c.inferType (c.mkApp (c.mkBird "K") (c.mkBird "S"))) "applied")
  ];

  # Suite 5: Pretty Printer
  suitePretty = suite "Pretty Printer" [
    (eq "pp Bird" (f.pp (c.mkBird "I")) "I")
    (eq "pp Var" (f.pp (c.mkVar "x")) "x")
    (eq "pp App" (f.pp (c.mkApp (c.mkBird "S") (c.mkBird "K"))) "S K")
    (eq "pp Lambda" (f.pp (c.mkLambda "x" (c.mkVar "x"))) "(lambda x. x)")
  ];

  # Suite 6: Examples
  suiteExamples = suite "Examples" [
    (eq "examples.sKK_test" c.examples.sKK_test "hello")
    (eq "examples.mI_rewritten" (c.examples.mI_rewritten.op) "Bird")
    (eq "examples.wK_rewritten" (c.examples.wK_rewritten.op) "Bird")
  ];

  # Suite 7: Free Variables
  suiteFreeVars = suite "Free Variables" [
    (eq "freeVars Bird" (f.freeVars (c.mkBird "I")) [])
    (eq "freeVars Var" (f.freeVars (c.mkVar "x")) ["x"])
    (eq "freeVars App" (f.freeVars (c.mkApp (c.mkVar "x") (c.mkVar "y"))) ["x" "y"])
  ];

  # Suite 8: Eta Reduction
  suiteEta = suite "Eta Reduction" [
    # lambda x. f x -> f (if x not in freeVars of f)
    # f is a free variable, so eta reduction returns the Var "f"
    (eq "etaReduce lambda x. f x op" (f.etaReduce (c.mkLambda "x" (c.mkApp (c.mkVar "f") (c.mkVar "x")))).op "Var")
    (eq "etaReduce lambda x. f x name" (f.etaReduce (c.mkLambda "x" (c.mkApp (c.mkVar "f") (c.mkVar "x")))).name "f")
    # lambda x. x -> I
    (eq "etaReduce lambda x. x" (f.etaReduce (c.mkLambda "x" (c.mkVar "x"))).op "Bird")
    (eq "etaReduce lambda x. x name" (f.etaReduce (c.mkLambda "x" (c.mkVar "x"))).name "I")
  ];

in
  h.combineSuites "Compiler Tests" [
    suiteAST
    suiteRewrite
    suiteCompile
    suiteType
    suitePretty
    suiteExamples
    suiteFreeVars
    suiteEta
  ]
