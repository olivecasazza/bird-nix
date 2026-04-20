{
  description = "bird-nix playground — browser-based combinator IDE with Monaco Editor";

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
    flake-utils.lib.eachDefaultSystem (
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

        # Filter source to only include Rust/HTML/CSS files
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ./.;
          filter =
            path: type:
            (craneLib.filterCargoSources path type)
            || builtins.match ".*\\.(html|css|js|ico|png|svg|woff2?)$" path != null;
        };

        commonArgs = {
          inherit src;
          strictDeps = true;
          CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
        };

        # Build dependencies separately for caching
        cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { doCheck = false; });

        # Build the trunk package
        playground = craneLib.buildTrunkPackage (
          commonArgs
          // {
            inherit cargoArtifacts;
            # trunk needs wasm-bindgen-cli version matching Cargo.lock
            wasm-bindgen-cli = pkgs.wasm-bindgen-cli_0_2_114;
          }
        );

        # Simple serve script
        serve = pkgs.writeShellScriptBin "bird-playground-serve" ''
          echo "🐦 bird-nix playground running at http://localhost:8080"
          ${pkgs.python3Minimal}/bin/python3 -m http.server --directory ${playground} 8080
        '';
      in
      {
        checks = {
          inherit playground;
          # Native tests (not WASM)
          bird-tests = craneLib.cargoTest {
            inherit src;
            cargoArtifacts = craneLib.buildDepsOnly {
              inherit src;
              strictDeps = true;
            };
          };
        };

        packages = {
          default = playground;
          serve = serve;
        };

        apps.default = flake-utils.lib.mkApp { drv = serve; };

        devShells.default = craneLib.devShell {
          checks = self.checks.${system};
          packages = with pkgs; [
            trunk
            wasm-bindgen-cli
          ];
        };
      }
    );
}
