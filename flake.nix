{
  description = "bird-nix — Combinator library from 'To Mock a Mockingbird' in pure Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      rust-overlay,
      ...
    }:
    let
      # Pure Nix library — import with: bird-nix.lib {}
      #
      # Usage in another flake:
      #   inputs.bird-nix.url = "github:olivecasazza/bird-nix";
      #
      #   # As a full library:
      #   let bn = inputs.bird-nix.lib {}; in bn.I "hello"
      #
      #   # Just the combinators:
      #   inherit (inputs.bird-nix.lib {}) I M K KI B C L W S V Y;
      libOutputs = {
        lib = import ./src;

        # Tests — run with: nix eval .#tests.summary --impure --raw
        tests = import ./tests { };

        # Individual test suites — pure Nix evaluations, accessed via
        # `nix eval .#testSuites.birds.summary --impure --raw`, etc.
        # Not under `checks.<system>.*` because these are attrsets, not
        # derivations, and `nix flake check` requires derivations.
        testSuites = {
          birds = import ./tests/test-birds.nix { };
          compiler = import ./tests/test-compiler.nix { };
          kernel = import ./tests/test-kernel.nix { };
          pbt = import ./tests/test-pbt.nix { };
          graph = import ./tests/test-graph.nix { };
        };
      };

      systemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };

          rustToolchain =
            p:
            p.rust-bin.stable.latest.default.override {
              targets = [ "wasm32-unknown-unknown" ];
            };

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          # The playground embeds bird-nix library sources via include_str!
          # at paths like "../../src/ast.nix". We stitch the repo into the
          # expected layout inside the Nix store: a root dir that contains
          # playground/, src/, tests/ — exactly how the paths resolve on disk.
          stitchedRoot = pkgs.runCommand "bird-nix-playground-root" { } ''
            mkdir -p $out
            cp -rL ${./playground} $out/playground
            cp -rL ${./src} $out/src
            cp -rL ${./tests} $out/tests
            chmod -R u+w $out
          '';

          src = pkgs.lib.cleanSourceWith {
            src = stitchedRoot;
            filter =
              path: type:
              (craneLib.filterCargoSources path type)
              || builtins.match ".*\\.(html|css|js|ico|png|svg|woff2?|nix|json|toml)$" path != null;
          };

          commonArgs = {
            inherit src;
            pname = "bird-playground";
            version = "0.1.0";
            strictDeps = true;
            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
            # Cargo.toml lives in playground/, not at src root
            cargoToml = "${src}/playground/Cargo.toml";
            cargoLock = "${src}/playground/Cargo.lock";
            sourceRoot = "source/playground";
          };

          cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { doCheck = false; });

          mkPlayground =
            extraArgs:
            craneLib.buildTrunkPackage (
              commonArgs
              // {
                inherit cargoArtifacts;
                wasm-bindgen-cli = pkgs.wasm-bindgen-cli_0_2_114;
                # Trunk's [[build.copy]] doesn't land in crane's output; copy
                # runtime-fetched assets ourselves so they're served alongside.
                postInstall = ''
                  cp ${src}/playground/bird-data.json $out/bird-data.json
                '';
              }
              // extraArgs
            );

          playground = mkPlayground { };

          # GitHub Pages build — served from https://olivecasazza.github.io/bird-nix/
          # so asset URLs must be prefixed with /bird-nix/.
          pages = mkPlayground {
            trunkExtraBuildArgs = "--public-url /bird-nix/";
          };
        in
        {
          packages = {
            default = playground;
            playground = playground;
            pages = pages;
          };

          devShells.default = craneLib.devShell {
            packages = with pkgs; [
              trunk
              wasm-bindgen-cli_0_2_114
            ];
          };
        }
      );
    in
    libOutputs // systemOutputs;
}
