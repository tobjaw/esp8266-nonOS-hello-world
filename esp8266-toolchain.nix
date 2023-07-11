{ stdenv, lib, fetchurl, makeWrapper, system }:

let
  toolchain = if (lib.strings.hasSuffix "darwin" system) then {
    url =
      "https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-macos.tar.gz";
    hash = "sha256-eCPF/fPOorWIzwxb2WJ3SrYKMLjZwZrgBWoO82l1N9s=";
  } else if system == "x86_64-linux" then {
    url =
      "https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz";
    hash = "sha256-ChgEteIjHG24tyr2vCoPmltplM+6KZVtQSZREJ8T/n4=";
  } else if system == "i686-linux" then {
    url =
      "https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz";
    hash = "sha256-yNzn6OtYwf304DunTrgJToA6C1uK1qnVcSFvYOtyyzY=";
  } else
    builtins.abort "Unsupported platform";

in stdenv.mkDerivation rec {
  pname = "esp8266-toolchain";
  version = "2020r3";

  src = fetchurl toolchain;

  buildInputs = [ makeWrapper ];

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -r . $out
  '';

  meta = with lib; {
    description = "ESP8266 compiler toolchain";
    platforms =
      [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "i686-linux" ];
    homepage =
      "https://docs.espressif.com/projects/esp8266-rtos-sdk/en/latest/get-started/index.html#setup-toolchain";
    license = licenses.gpl3;
  };
}
