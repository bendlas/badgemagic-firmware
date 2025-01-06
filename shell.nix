# with import <nixpkgs> {
let
  pkgs = import /home/herwig/code/nixpkgs { };
  crossPkgs = import /home/herwig/code/nixpkgs {
    crossSystem = {
      config = "riscv32-none-elf";
      libc = "newlib-nano";
      gcc = {
        arch = "rv32imac_zicsr";
        # arch = "rv32imac";
        abi = "ilp32";
      };
    };
  };
  # wchStdenv = crossPkgs.overrideCC crossPkgs.gccStdenv crossPkgs.buildPackages.gcc8;
  # wchStdenv = crossPkgs.gcc9Stdenv;
in crossPkgs.mkShell {
  nativeBuildInputs = with pkgs; [ wchisp ];
  buildInputs = [ ];
}
# in wchStdenv.mkDerivation {
#   name = "wch-nix-shell";
#   nativeBuildInputs = with pkgs; [ wchisp ];
# }
