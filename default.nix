with import <nixpkgs> {};
# let
#   emscriptenPackages.zlib
#in 
pkgs.mkShell {
  buildInputs = with pkgs; [
    emscripten
    miniserve
    # if you have your own c++ packages see to compile emscripten one: https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/emscripten.section.md#user-content-usage-2-pkgsbuildemscriptenpackage
  ];
    shellHook = ''
    export EMSCRIPTEN="${pkgs.emscripten}/bin"
    echo "🚀 emscripten ready!"
  '';

}

