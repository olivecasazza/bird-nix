# Bird-nix demos - standalone demo definitions
# Takes bird-nix lib as an argument

{ lib }:

let
  inherit (lib) I M K KI B C W S L V Y;
  inherit (lib.compiler) mkApp mkBird compile rewrite;
  inherit (lib.format) pp;
  inherit (lib.toolchain) typeCheck;
in

{
  # S K K = I
  sKK = rec {
    ast = mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K");
    rewritten = rewrite ast;
    pretty = pp rewritten;
    compiled = compile rewritten;
    test = compiled "hello";
    type = typeCheck "I";
  };

  # M I = I
  mI = rec {
    ast = mkApp (mkBird "M") (mkBird "I");
    rewritten = rewrite ast;
    pretty = pp rewritten;
    compiled = compile rewritten;
    test = compiled "world";
  };

  # Type checking demos
  typeChecks = {
    identityType = typeCheck "I";
    kestrelType = typeCheck "K";
    unknownType = typeCheck "Z";
  };

  # NixOS-style config example using birds
  configExample = {
    serverName = K "example.com" "dev.example.com";
    port = (S K K) 8080;
    selfRef = (W K) "nginx";
  };
}
