{
  description = "A flake with pre-commit hooks";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        imports = [
          inputs.git-hooks-nix.flakeModule
        ];
        systems = [ "x86_64-linux" "aarch64-linux" ];
        perSystem = { config, self', inputs', pkgs, ... }: {
          packages.default = pkgs.testers.runNixOSTest ./test.nix;
          pre-commit.settings.hooks.nixpkgs-fmt.enable = true;
          devShells.default = config.pre-commit.devShell;
        };
        flake = { };
      };
}
