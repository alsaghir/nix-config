# Shorter XDG_DATA_DIRS for the Plasma session: https://github.com/NixOS/nixpkgs/issues/126590
#
# The KDE setup hooks give every plasma-workspace binary one `--prefix XDG_DATA_DIRS` per
# dependency. Everything in the session descends from those binaries and inherits the list, so
# every app searches all of those paths (reported: slow tray applets/popups and app startup,
# tools failing on the over-long environment).
#
# This rebuilds plasma-workspace (from source, on every nixpkgs bump that changes it) with
# those prefixes replaced by one merged tree in an extra `xdgdata` output:
# - The list is taken from the real build's qtWrapperArgs, so nothing is guessed. Rebuilding it
#   in a separate derivation (`buildInputs = [ plasma-workspace ]`) would see `.dev`'s
#   propagated deps only and miss the non-propagated ones.
# - An output of the same build, not a copy of the cached package: the session files, units and
#   wrappers refer to this rebuilt `$out`. Not in `$out/share`, which would land in the profile.
# - `//`, not `overrideScope`: only plasma-workspace's own wrappers start the session, and
#   overrideScope would also rebuild every package that depends on it, with no gain here.
#
# Check inside the session: `echo "$XDG_DATA_DIRS" | tr : '\n' | wc -l`.
# Remove this overlay once the issue is fixed upstream.
{ ... }:
_final: prev: {
  kdePackages = prev.kdePackages // {
    plasma-workspace = prev.kdePackages.plasma-workspace.overrideAttrs (old: {
      outputs = old.outputs ++ [ "xdgdata" ];
      nativeBuildInputs = old.nativeBuildInputs ++ [ prev.buildPackages.lndir ];

      # Runs after qtOwnPathsHook (preFixupPhases) and before wrapQtAppsHook (fixupOutputHooks),
      # so qtWrapperArgs holds every prefix and no wrapper exists yet.
      preFixup = (old.preFixup or "") + ''
        xdgDataDirs=()
        keptArgs=()
        for ((i = 0; i < ''${#qtWrapperArgs[@]}; i++)); do
          if [[ ''${qtWrapperArgs[i]} == --prefix && ''${qtWrapperArgs[i + 1]-} == XDG_DATA_DIRS ]]; then
            if [[ ''${qtWrapperArgs[i + 3]} != "''${!outputBin}/share" ]]; then
              xdgDataDirs+=("''${qtWrapperArgs[i + 3]}")
            fi
            i=$((i + 3))
          else
            keptArgs+=("''${qtWrapperArgs[i]}")
          fi
        done
        # Each --prefix goes in front, so the package's own share stays first in the search.
        qtWrapperArgs=(
          "''${keptArgs[@]}"
          --prefix XDG_DATA_DIRS : "$xdgdata/share"
          --prefix XDG_DATA_DIRS : "''${!outputBin}/share"
        )
        # Empty until postFixup; exists so the per-output fixup hooks see a normal output.
        mkdir -p "$xdgdata/share"
      '';

      # After the original postFixup: moveToOutput scans every output, so the merged tree must
      # stay empty until it has run. lndir keeps the first link on a clash; walking the list
      # backwards keeps the original precedence (the last --prefix was searched first).
      postFixup = (old.postFixup or "") + ''
        for ((i = ''${#xdgDataDirs[@]} - 1; i >= 0; i--)); do
          lndir -silent "''${xdgDataDirs[i]}" "$xdgdata/share"
        done
      '';
    });
  };
}
