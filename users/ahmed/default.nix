# ahmed on every host. Per-host additions: users/ahmed/<host>/default.nix.
{ inputs }:
{ config, lib, ... }:

let
  # Secret names in ai-keys.yaml; each is exported as its upper-case name (gemini_api_key → GEMINI_API_KEY).
  aiApiKeys = [
    "gemini_api_key"
    "deepseek_api_key"
    "groq_api_key"
    "openrouter_api_key"
    "openai_api_key"
    "mistral_api_key"
    "cerebras_api_key"
  ];
in
{
  imports = [
    ./justfile.nix
    inputs.sops-nix.homeManagerModules.sops
    inputs.ai-rules.homeManagerModules.default
  ];

  # Features on every host (modules: home/, imported for every user@host by flake.nix).
  nixConfig = {
    cli.enable = true;
    dev.enable = true;
    lazyvim.enable = true;
    ssh.enable = true;
  };

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Default flake for nh (NH_FLAKE) and the justfile recipes.
  programs.nh.flake = "${config.home.homeDirectory}/Projects/nix-config";

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = lib.genAttrs aiApiKeys (_: {
      sopsFile = ./ai-keys.yaml;
    });

    # KEY_NAME=value per line; sourced by zsh (home/cli.nix) via AI_ENV_FILE.
    templates."ai-env".content = lib.concatMapStrings (
      key: "${lib.toUpper key}=${config.sops.placeholder.${key}}\n"
    ) aiApiKeys;
  };

  home.sessionVariables.AI_ENV_FILE = config.sops.templates."ai-env".path;

  # Host profiles decrypt their SSH keys into ~/.ssh (users/ahmed/<host>/ssh-keys.yaml).
  home.activation.ensureSshPermissions = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ssh"
    $DRY_RUN_CMD chmod 0700 "${config.home.homeDirectory}/.ssh"
  '';
}
