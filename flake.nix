{
  description = "ESP8266 non-OS Hello World";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "i686-linux"
    ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        esp8266-toolchain =
          pkgs.callPackage ./esp8266-toolchain.nix { inherit system; };
        esp8266-nonos-sdk = pkgs.callPackage ./esp8266-nonos-sdk.nix { };
      in {
        packages = {
          inherit esp8266-toolchain esp8266-nonos-sdk;
          default = esp8266-toolchain;
        };

        devShells = {
          default = pkgs.mkShell {
            ESP8266_NONOS_SDK = esp8266-nonos-sdk;
            buildInputs = with pkgs; [
              gnumake
              esp8266-toolchain
              esp8266-nonos-sdk
              esptool
            ];
          };
        };
      });
}
