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
  # TODO(questionable-implementation): see if we can use our birds for type checking implementation
  typeCheck = birdName:
    if builtins.hasAttr birdName typeEnv
    then { ok = true; type = typeEnv.${birdName}; errors = []; }
    else { ok = false; type = null; errors = ["Unknown bird: ${birdName}"]; };
  # Compile helper: build AST, rewrite, compile
  compileBird = ast: compiler.compile (compiler.rewrite ast);
  # Pretty-print helper
  ppBird = ast: format.pp ast;

in
{
  inherit compiler format;
  inherit I M K KI B C W S L V Y;
  inherit typeEnv typeCheck compileBird ppBird;

  # Demos
  # TODO(bad-implementation): Demos should be an separate folder / flake that import this flake as an export, pinned at aversion
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
