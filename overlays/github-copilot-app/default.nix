# Microsoft.AI.Foundry.Local.Core.so dlopen()s libssl at runtime. Its RUNPATH is
# only $ORIGIN, so the app aborts with "No usable version of libssl was found".
# appendRunpaths (unlike runtimeDependencies, which only touches executables)
# is applied by autoPatchelfHook to every ELF, including shared libraries.
# getLib: openssl's default output is `bin`, which has no lib/.
# autoPatchelfHook *replaces* the RUNPATH, so $ORIGIN must be re-added or the
# bundled sibling libonnxruntime.so is no longer found.
# Remove once fixed upstream.
final: prev: {
  github-copilot-app = prev.github-copilot-app.overrideAttrs (old: {
    appendRunpaths = (old.appendRunpaths or [ ]) ++ [
      "$ORIGIN"
      "${final.lib.getLib final.openssl_3_5}/lib"
    ];
  });
}
