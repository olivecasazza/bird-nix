# Bird DSL Compiler - Compiles combinatory logic birds to Nix functions
# Dogfoods birds.nix — core combinators imported, not redefined
# Imports ast.nix — AST constructors are not redefined here
{ }:

let
  # Import canonical AST constructors
  ast = import ./ast.nix {};
  inherit (ast) mkApp mkVar mkBird mkLambda;

  # Import canonical combinator definitions
  birds = import ./birds.nix {};
  inherit (birds) I K S B C W M L Y V;

  # CANONICAL type environment for all birds (single source of truth)
  typeEnv = {
    I = "a -> a";
    M = "(a -> a) -> a";
    K = "a -> b -> a";
    KI = "a -> b -> b";
    B = "(b -> c) -> (a -> b) -> a -> c";
    C = "(a -> b -> c) -> b -> a -> c";
    W = "(a -> a -> b) -> a -> b";
    S = "(a -> b -> c) -> (a -> b) -> a -> c";
    L = "(a -> b -> a) -> a -> b";
    V = "a -> b -> (a -> b -> c) -> c";
    Y = "(a -> a) -> a";
  };

  # CANONICAL string→function bird lookup (single source of truth)
  birdMap = {
    "I" = I;
    "M" = M;
    "K" = K;
    "KI" = birds.KI;
    "B" = B;
    "C" = C;
    "W" = W;
    "S" = S;
    "L" = L;
    "V" = V;
    "Y" = Y;
  };

  # Helper functions for pattern matching
  isBird = name: node: node.op == "Bird" && node.name == name;

  # Rewrite rules - applies theorem-based simplifications
  rewrite = node:
    if node.op == "App" then
      let
        rewrittenFn = rewrite node.fn;
        rewrittenArg = rewrite node.arg;
        app = mkApp rewrittenFn rewrittenArg;
      in
      # S K K -> I
      if (app.fn.op or "" == "App") &&
         (isBird "S" (app.fn.fn or {})) &&
         (isBird "K" (app.fn.arg or {})) &&
         (isBird "K" app.arg)
      then mkBird "I"
      # W K -> I
      else if (isBird "W" app.fn) &&
              (isBird "K" app.arg)
      then mkBird "I"
      # K x y -> x (when both args applied)
      else if (app.fn.op or "" == "App") &&
              (app.fn.fn.op or "" == "Bird") &&
              (app.fn.fn.name or "" == "K")
      then app.fn.arg
      # M I -> I
      else if (isBird "M" app.fn) &&
              (isBird "I" app.arg)
      then mkBird "I"
      # B f I -> f
      else if (app.fn.op or "" == "App") &&
              (isBird "B" (app.fn.fn or {})) &&
              (isBird "I" app.fn.arg)
      then app.fn.fn
      else app
    else if node.op == "Lambda" then
      mkLambda node.param (rewrite node.body)
    else
      node;

  # Compile AST to Nix function
  compile = node:
    if node.op == "Bird" then
      builtins.getAttr node.name birdMap
    else if node.op == "App" then
      (compile node.fn) (compile node.arg)
    else if node.op == "Lambda" then
      x: compile (rewrite (mkApp node.body (mkVar x)))
    else if node.op == "Var" then
      builtins.throw "Free variable not allowed: ${node.name}"
    else
      builtins.throw "Unknown op: ${node.op}";

  # Simple type inference - lookup based
  inferType = node:
    if node.op == "Bird" then
      builtins.getAttr node.name typeEnv
    else if node.op == "App" then
      "applied"
    else if node.op == "Lambda" then
      "function"
    else if node.op == "Var" then
      "variable"
    else
      "unknown";

  # Examples
  examples =
    let
      sKK_ast = mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K");
      mI_ast = mkApp (mkBird "M") (mkBird "I");
      kxy_ast = mkApp (mkApp (mkBird "K") (mkBird "K")) (mkBird "S");
      wK_ast = mkApp (mkBird "W") (mkBird "K");
    in {
      sKK_ast = sKK_ast;
      sKK_rewritten = rewrite sKK_ast;
      sKK_compiled = compile (rewrite sKK_ast);
      sKK_test = (compile (rewrite sKK_ast)) "hello";
      mI_ast = mI_ast;
      mI_rewritten = rewrite mI_ast;
      kxy_ast = kxy_ast;
      kxy_rewritten = rewrite kxy_ast;
      wK_ast = wK_ast;
      wK_rewritten = rewrite wK_ast;
    };

in
# Public API
{
  inherit mkApp mkVar mkBird mkLambda;
  inherit compile rewrite inferType;
  inherit typeEnv birdMap;
  inherit I K S B C W M Y L V;
  KI = birds.KI;
  inherit examples;
}
