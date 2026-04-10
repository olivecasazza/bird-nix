# Bird Toolchain - Unified toolchain combining compiler, formatter, type checking, and config builder
# Dogfoods birds.nix — all combinators imported, not redefined

{ }:
let
  # Import canonical combinator definitions and sub-modules
  birds = import ./birds.nix {};
  inherit (birds) I M K KI B C W S L V Y;
  compiler = import ./bird-compiler.nix {};
  format = import ./bird-format.nix {};

  # Type environment
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

  # Type check: returns { ok, type, errors }
  #
  # Uses K/KI as Church booleans for selection:
  #   K  selects first  arg (success path)
  #   KI selects second arg (failure path)
  #
  # The predicate `builtins.hasAttr` is an irreducible Nix primitive,
  # but the branching uses birds: (if pred then K else KI) success failure
  typeCheck = birdName:
    let
      selector = if builtins.hasAttr birdName typeEnv then K else KI;
      success  = { ok = true;  type = typeEnv.${birdName}; errors = []; };
      failure  = { ok = false;  type = null; errors = ["Unknown bird: ${birdName}"]; };
    in selector success failure;
  # Compile helper: build AST, rewrite, compile
  compileBird = ast: compiler.compile (compiler.rewrite ast);
  # Pretty-print helper
  ppBird = ast: format.pp ast;

in
{
  inherit compiler format;
  inherit I M K KI B C W S L V Y;
  inherit typeEnv typeCheck compileBird ppBird;

  # Demos (kept for backward compatibility — canonical demos are in demos/ flake)
  demos = {
    # S K K = I
    sKK = rec {
      ast = compiler.mkApp (compiler.mkApp (compiler.mkBird "S") (compiler.mkBird "K")) (compiler.mkBird "K");
      rewritten = compiler.rewrite ast;
      pretty = format.pp rewritten;
      compiled = compiler.compile rewritten;
      test = compiled "hello";  # should be "hello"
      type = typeCheck "I";
    };

    # M I = I
    mI = rec {
      ast = compiler.mkApp (compiler.mkBird "M") (compiler.mkBird "I");
      rewritten = compiler.rewrite ast;
      pretty = format.pp rewritten;
      compiled = compiler.compile rewritten;
      test = compiled "world";
    };

    # Type checking
    typeChecks = {
      identityType = typeCheck "I";
      kestrelType = typeCheck "K";
      unknownType = typeCheck "Z";
    };
  };

  # NixOS-style config example using birds
  configExample = {
    serverName = K "example.com" "dev.example.com";
    port = (S K K) 8080;
    selfRef = (W K) "nginx";
  };
}
