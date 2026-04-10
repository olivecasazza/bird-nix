# bird-format.nix — Pretty-printer, free variable analysis, and eta-reducer
# Imports ast.nix — AST constructors are not redefined here
# Standalone: no dependency on birds.nix (operates on AST nodes only)
{ }:

let
  # Import canonical AST constructors
  ast = import ./ast.nix {};
  inherit (ast) mkApp mkVar mkBird mkLambda;

  # Pretty-printer
  pp = node:
    if node.op == "Var" then node.name
    else if node.op == "Bird" then node.name
    else if node.op == "Lambda" then "(lambda ${node.param}. ${pp node.body})"
    else if node.op == "App" then
      let fnStr = pp node.fn; argStr = pp node.arg;
      in if node.fn.op == "App" || node.fn.op == "Lambda"
         then "(${fnStr}) ${argStr}"
         else "${fnStr} ${argStr}"
    else builtins.throw "Unknown op";

  # Free variables
  freeVars = node:
    if node.op == "Var" then [node.name]
    else if node.op == "Bird" then []
    else if node.op == "Lambda" then
      builtins.filter (x: x != node.param) (freeVars node.body)
    else if node.op == "App" then
      (freeVars node.fn) ++ (freeVars node.arg)
    else [];

  # Eta-reduction
  etaReduce = node:
    if node.op == "Lambda" then
      let body = etaReduce node.body;
      in
      # lambda x. f x -> f (if x not in freeVars of f)
      if body.op == "App"
         && body.arg.op == "Var"
         && body.arg.name == node.param
         && !(builtins.elem node.param (freeVars body.fn))
      then etaReduce body.fn
      # lambda x. x -> I
      else if body.op == "Var" && body.name == node.param
      then mkBird "I"
      else mkLambda node.param body
    else if node.op == "App" then
      mkApp (etaReduce node.fn) (etaReduce node.arg)
    else node;

  # Examples
  examples = {
    # S K K -> "S K K"
    ppSKK = pp (mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K"));

    # lambda x. f x -> f
    etaFx = pp (etaReduce (mkLambda "x" (mkApp (mkVar "f") (mkVar "x"))));

    # lambda x. x -> I
    etaId = pp (etaReduce (mkLambda "x" (mkVar "x")));
  };

in {
  inherit mkApp mkVar mkBird mkLambda pp freeVars etaReduce examples;
}
