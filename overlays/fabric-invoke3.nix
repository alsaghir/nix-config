# TEMPORARY: remove once NixOS/nixpkgs#576874 (fixes #575989) reaches the
# pinned nixpkgs. Backports that PR: build fabric from a commit that supports
# invoke v3 instead of the released 3.2.3, which nixpkgs marks broken.
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      fabric = pyPrev.fabric.overrideAttrs (old: {
        version = "3.2.3-unstable-2026-04-07";
        src = prev.fetchFromGitHub {
          owner = "fabric";
          repo = "fabric";
          rev = "cc098ad475dbbe2e10aba72692d83aee58919570";
          hash = "sha256-Z1tGcjdLrzbqcbS6XwapSgDNpyLbBiO21yeqi7XhbpQ=";
        };
        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];
}
