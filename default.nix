{
  nixpkgs ? import <nixpkgs> {
    overlays = [
      (import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        rev = "ef220b4a0990fd0f5dd25c588c24b2c1ad88c8fc";
        ref = "master";
      }))
    ];
  }
}:
let
  inherit (nixpkgs) pkgs;
  emacsWithPackages = with pkgs;
    emacsWithPackagesFromUsePackage {
      config = builtins.readFile ./src/melpa-mirror-packages.el;
      alwaysEnsure = true;
      override = epkgs: epkgs // {
        racket-mode = epkgs.melpaPackages.racket-mode.overrideAttrs(old: {
          src = (builtins.fetchGit {
            url = "https://github.com/yilinwei/racket-mode.git";
            rev = "c33d4de97d90310e086ba63492ddcae700e067b1";
            ref = "master";
          });
        });
      };
    };
  site-lisp = with pkgs;
    stdenv.mkDerivation {
      name = "site-lisp";
      src = lib.cleanSource ./src;
      buildInputs = [ emacsWithPackages ];
      buildPhase = ''
        emacs --batch --eval "(byte-recompile-file \"$(pwd)/melpa-mirror-packages.el\" t 0)"
      '';
      installPhase = ''
        mkdir -p $out/share/emacs/site-lisp
        cp -r . $out/share/emacs/site-lisp/
      '';
    };
in pkgs.symlinkJoin {
  name = "emacs-site-lisp";
  paths = [ emacsWithPackages site-lisp ];
}
