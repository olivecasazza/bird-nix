# Bird DSL Compiler - Compiles combinatory logic birds to Nix functions
# Dogfoods birds.nix — core combinators imported, only compiler-specific birds defined locally
{ }:

let
  # AST Node Constructors
  mkApp = fn: arg: { op = "App"; inherit fn arg; };
  mkVar = name: { op = "Var"; inherit name; };
  mkBird = name: { op = "Bird"; inherit name; };
  mkLambda = param: body: { op = "Lambda"; inherit param body; };

  # Import canonical combinator definitions
  birds = import ./birds.nix {};
  inherit (birds) I K S B C W M L Y V;

  # Type environment for birds
  typeEnv = {
    I = "a -> a";
    K = "a -> b -> a";
    S = "(a -> b -> c) -> (a -> b) -> a -> c";
    B = "(b -> c) -> (a -> b) -> a -> c";
    C = "(a -> b -> c) -> b -> a -> c";
    W = "(a -> a -> b) -> a -> b";
    M = "(a -> a) -> a";
    Y = "(a -> a) -> a";
    L = "a -> (b -> c) -> b -> a c";
    V = "a -> b -> c -> c a b";
  };

  # Helper functions for pattern matching
  isBird = name: ast: ast.op == "Bird" && ast.name == name;

  # Check if AST is an App with given fn and arg conditions
  isApp = fnCond: argCond: ast:
    ast.op == "App" && (fnCond ast.fn) && (argCond ast.arg);

  # Rewrite rules - applies theorem-based simplifications
  rewrite = ast:
    if ast.op == "App" then
      let
        rewrittenFn = rewrite ast.fn;
        rewrittenArg = rewrite ast.arg;
        app = mkApp rewrittenFn rewrittenArg;
      in
      # S K K -> I
      # Check if app is App(App(S, K), K)
      if (app.op == "App") &&
         (app.fn.op == "App") &&
         (isBird "S" app.fn.fn) &&
         (isBird "K" app.fn.arg) &&
         (isBird "K" app.arg)
      then mkBird "I"
      # W K -> I
      else if (app.op == "App") &&
              (isBird "W" app.fn) &&
              (isBird "K" app.arg)
      then mkBird "I"
      # K x y -> x (when both args applied)
      # Check if app is App(App(K, x), y)
      else if (app.op == "App") &&
              (app.fn.op == "App") &&
              (app.fn.fn.op == "Bird") &&
              (app.fn.fn.name == "K")
      then app.fn.arg
      # M I -> I
      else if (app.op == "App") &&
              (isBird "M" app.fn) &&
              (isBird "I" app.arg)
      then mkBird "I"
      # B f I -> f
      else if (app.op == "App") &&
              (app.fn.op == "App") &&
              (isBird "B" app.fn.fn) &&
              (isBird "I" app.fn.arg)
      then app.fn.fn
      else app
    else if ast.op == "Lambda" then
      mkLambda ast.param (rewrite ast.body)
    else
      ast;

  # Compile AST to Nix function
  compile = ast:
    let
      getBird = name:
        builtins.getAttr name {
          I = I;
          K = K;
          S = S;
          B = B;
          C = C;
          W = W;
          M = M;
          Y = Y;
          L = L;
          V = V;
        };
    in
    if ast.op == "Bird" then
      getBird ast.name
    else if ast.op == "App" then
      (compile ast.fn) (compile ast.arg)
    else if ast.op == "Lambda" then
      x: compile (rewrite (mkApp ast.body (mkVar x)))
    else if ast.op == "Var" then
      builtins.throw "Free variable not allowed: ${ast.name}"
    else
      builtins.throw "Unknown op: ${ast.op}";

  # Simple type inference - lookup based
  inferType = ast:
    if ast.op == "Bird" then
      builtins.getAttr ast.name typeEnv
    else if ast.op == "App" then
      "applied"
    else if ast.op == "Lambda" then
      "function"
    else if ast.op == "Var" then
      "variable"
    else
      "unknown";

  # Examples - defined after rewrite and compile so they can use them
  sKK_ast = mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K");
  sKK_rewritten = rewrite sKK_ast;
  sKK_compiled = compile (rewrite sKK_ast);
  sKK_test = (compile (rewrite sKK_ast)) "hello";

  mI_ast = mkApp (mkBird "M") (mkBird "I");
  mI_rewritten = rewrite mI_ast;

  kxy_ast = mkApp (mkApp (mkBird "K") (mkBird "K")) (mkBird "S");
  kxy_rewritten = rewrite kxy_ast;

  wK_ast = mkApp (mkBird "W") (mkBird "K");
  wK_rewritten = rewrite wK_ast;

  examples = {
    inherit sKK_ast sKK_rewritten sKK_compiled sKK_test;
    inherit mI_ast mI_rewritten;
    inherit kxy_ast kxy_rewritten;
    inherit wK_ast wK_rewritten;
  };

in
# Public API
{
  inherit mkApp mkVar mkBird mkLambda;
  inherit compile rewrite inferType;
  inherit I K S B C W M Y L V;
  inherit typeEnv;
  inherit examples;
}
