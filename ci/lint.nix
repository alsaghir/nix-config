# `nix flake check` lint for every .nix file under `root`: statix (anti-patterns) and
# deadnix (unused bindings). Exposed as `lib.mkLintCheck` so the private flakes built on
# this one enforce the same rules (README "Conventions").
#
# statix: W10 (empty pattern) and W20 (repeated keys) are off. `{ ... }:` is the profile
# shape `importApply` expects, and `programs.a = …; programs.b = …;` groups by concern
# better than one nested block.
# deadnix: lambda arguments (`final: prev:` overlays) are not checked, and
# hardware-configuration.nix is skipped because nixos-generate-config owns it.
{
  deadnix,
  lib,
  runCommand,
  statix,
  writeText,
}:
root:
let
  src = lib.fileset.toSource {
    inherit root;
    fileset = lib.fileset.fileFilter (
      file: file.hasExt "nix" && file.name != "hardware-configuration.nix"
    ) root;
  };

  statixConfig = writeText "statix.toml" ''
    disabled = [ "empty_pattern", "repeated_keys" ]
  '';
in
runCommand "lint"
  {
    nativeBuildInputs = [
      deadnix
      statix
    ];
  }
  ''
    cd ${src}
    statix check --config ${statixConfig} .
    deadnix --fail --no-lambda-arg .
    touch $out
  ''
