# Microsoft.AI.Foundry.Local.Core.so dlopen()s libssl at runtime. Its RUNPATH is
# only $ORIGIN, so the app aborts with "No usable version of libssl was found".
# appendRunpaths (unlike runtimeDependencies, which only touches executables)
# is applied by autoPatchelfHook to every ELF, including shared libraries.
# getLib: openssl's default output is `bin`, which has no lib/.
# autoPatchelfHook *replaces* the RUNPATH, so $ORIGIN must be re-added or the
# bundled sibling libonnxruntime.so is no longer found.
# Remove once nixpkgs includes NixOS/nixpkgs#581720.
#
# patchelf 0.15.2 (nixpkgs pinned it back from 0.19.2, NixOS/nixpkgs#577387)
# corrupts the main executable: after relocating .rela.dyn to the end of the
# file, its 2nd entry is garbage (R_X86_64_RELATIVE -> PLT32, offset 0x24), so
# ld.so aborts with "elf_machine_rela_relative: Assertion ... failed".
# nativeBuildInputs precede stdenv's own patchelf on PATH, so autoPatchelf
# uses 0.19.2 (same mechanism as firefox-bin, cf, ...).
# Remove once nixpkgs' default patchelf is >= 0.19 again.
final: prev: {
  github-copilot-app = prev.github-copilot-app.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.patchelfUnstable ];

    appendRunpaths = (old.appendRunpaths or [ ]) ++ [
      "$ORIGIN"
      "${final.lib.getLib final.openssl_3_5}/lib"
    ];
  });
}
