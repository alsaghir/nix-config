# nixpkgs marks posthog `broken` when mcp >= 2, but mcp is only a
# nativeCheckInput (its test suite is incompatible with mcp 2); runtime deps are
# unaffected. aider-chat depends on posthog, so skip the tests and unmark it.
# Remove once nixpkgs drops the `broken` condition.
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      posthog = pyPrev.posthog.overridePythonAttrs (old: {
        doCheck = false;
        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];
}
