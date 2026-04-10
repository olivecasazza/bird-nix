{ }:

let
  # AST helpers
  mkApp = fn: arg: { op = "App"; inherit fn arg; };
  mkVar = name: { op = "Var"; inherit name; };
  mkBird = name: { op = "Bird"; inherit name; };
  mkLambda = param: body: { op = "Lambda"; inherit param body; };

  # Pretty-printer
  pp = ast:
    if ast.op == "Var" then ast.name
    else if ast.op == "Bird" then ast.name
    else if ast.op == "Lambda" then "(lambda ${ast.param}. ${pp ast.body})"
    else if ast.op == "App" then
      let fnStr = pp ast.fn; argStr = pp ast.arg;
      in if ast.fn.op == "App" || ast.fn.op == "Lambda"
         then "(${fnStr}) ${argStr}"
         else "${fnStr} ${argStr}"
    else builtins.throw "Unknown op";

  # Free variables
  freeVars = ast:
    if ast.op == "Var" then [ast.name]
    else if ast.op == "Bird" then []
    else if ast.op == "Lambda" then
      builtins.filter (x: x != ast.param) (freeVars ast.body)
    else if ast.op == "App" then
      (freeVars ast.fn) ++ (freeVars ast.arg)
    else [];

  # Eta-reduction
  etaReduce = ast:
    if ast.op == "Lambda" then
      let body = etaReduce ast.body;
      in
      # lambda x. f x -> f (if x not in freeVars of f)
      if body.op == "App"
         && body.arg.op == "Var"
         && body.arg.name == ast.param
         && !(builtins.elem ast.param (freeVars body.fn))
      then etaReduce body.fn
      # lambda x. x -> I
      else if body.op == "Var" && body.name == ast.param
      then mkBird "I"
      else mkLambda ast.param body
    else if ast.op == "App" then
      mkApp (etaReduce ast.fn) (etaReduce ast.arg)
    else ast;

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
