{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixConfig.dev.enable = lib.mkEnableOption "developer tooling (Kubernetes, GitHub Copilot CLI)";

  config = lib.mkIf config.nixConfig.dev.enable {
    programs.github-copilot-cli.enable = true;
    programs.k9s.enable = true;

    home.packages = with pkgs; [
      kubectl
      # Helm with the commonly-needed plugins baked in (see NixOS wiki: Helm_and_Helmfile).
      # helm-diff: preview release changes; helm-secrets: manage encrypted values;
      # helm-git: install charts straight from git refs.
      (wrapHelm kubernetes-helm {
        plugins = with kubernetes-helmPlugins; [
          helm-diff
          helm-secrets
          helm-git
        ];
      })
    ];
  };
}
