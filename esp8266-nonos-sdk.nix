{ stdenv, lib, fetchurl, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "esp8266-nonos-sdk";
  version = "3.0.5";

  src = builtins.fetchGit {
       url = "git@github.com:espressif/ESP8266_NONOS_SDK.git";
       ref = "refs/tags/v${version}";
       rev = "7b5b35da98ad9ee2de7afc63277d4933027ae91c";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -r . $out
  '';

  meta = with lib; {
    description = "ESP8266 nonOS SDK";
    license = licenses.mit;
  };
}
