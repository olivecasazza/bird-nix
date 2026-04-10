# ast.nix — CANONICAL AST node constructors for bird expressions
#
# Single source of truth for the tagged-record AST used by the compiler,
# formatter, and toolchain. Every module that builds or inspects ASTs
# MUST import these constructors rather than redefining them.
#
# No dependencies — this is a leaf node in the import DAG.

{ }:

{
  mkApp = fn: arg: { op = "App"; inherit fn arg; };
  mkVar = name: { op = "Var"; inherit name; };
  mkBird = name: { op = "Bird"; inherit name; };
  mkLambda = param: body: { op = "Lambda"; inherit param body; };
}
