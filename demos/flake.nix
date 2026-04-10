{
  description = "bird-nix demos — Standalone demo flake that imports bird-nix";

  inputs = {
    bird-nix.url = "path:..";
  };

  outputs = { self, bird-nix }:
    let
      lib = bird-nix.lib {};
      demos = import ./default.nix { inherit lib; };
    in {
      # Export all demos for easy evaluation
      # Usage: nix eval ./demos#sKK.test --impure
      #        nix eval ./demos#mI.test --impure
      #        nix eval ./demos#typeChecks.identityType --impure
      demos = demos;

      # Also expose demos as default output
      default = demos;

      # Expose individual demos as outputs for nix eval
      # This allows: nix eval ./demos#sKK.test
      sKK = demos.sKK;
      mI = demos.mI;
      typeChecks = demos.typeChecks;
      configExample = demos.configExample;
    };
}
