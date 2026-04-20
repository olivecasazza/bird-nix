{
  description = "bird-nix — Combinator library from 'To Mock a Mockingbird' in pure Nix";

  outputs =
    { self, ... }:
    {
      # The library — import with: bird-nix.lib {}
      #
      # Usage in another flake:
      #   inputs.bird-nix.url = "github:olivecasazza/bird-nix";
      #
      #   # As a full library:
      #   let bn = inputs.bird-nix.lib {}; in bn.I "hello"
      #
      #   # Individual modules:
      #   let bn = inputs.bird-nix.lib {}; in bn.compiler.compile (bn.compiler.mkBird "K")
      #
      #   # Just the combinators:
      #   inherit (inputs.bird-nix.lib {}) I M K KI B C L W S V Y;
      #
      #   # Property-based testing in your own project:
      #   let pbt = (inputs.bird-nix.lib {}).pbt;
      #   in pbt.property "my prop" (pbt.forAll pbt.domains.ints (x: x + 0 == x))
      lib = import ./src;

      # Tests — run with: nix eval .#tests.summary --impure --raw
      tests = import ./tests { };

      # Individual test suites
      checks = {
        birds = import ./tests/test-birds.nix { };
        compiler = import ./tests/test-compiler.nix { };
        kernel = import ./tests/test-kernel.nix { };
        pbt = import ./tests/test-pbt.nix { };
        graph = import ./tests/test-graph.nix { };
      };
    };
}
