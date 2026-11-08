# ahmed on every host. Per-host additions: users/ahmed/<host>/default.nix.
{ inputs }:
{ config, lib, ... }:

let

  aiApiKeysSopsFile = ./ai-keys.yaml;

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
    ssh.enable = true;
  };

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Default flake for nh (NH_FLAKE) and the justfile recipes.
  programs.nh.flake = "${config.home.homeDirectory}/Projects/nix-config";

  sops = {
    # or ${config.home.homeDirectory}/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      # AI API keys
      "gemini_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "deepseek_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "groq_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "openrouter_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "openai_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "mistral_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
      "cerebras_api_key" = {
        sopsFile = aiApiKeysSopsFile;
      };
    };

    templates."ai-env" = {
      content = ''
        GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key}
        DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek_api_key}
        GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
        OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key}
        OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
        MISTRAL_API_KEY=${config.sops.placeholder.mistral_api_key}
        CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
      '';
    };

  };

  home.sessionVariables.AI_ENV_FILE = config.sops.templates."ai-env".path;

  # Host profiles decrypt their SSH keys into ~/.ssh (users/ahmed/<host>/ssh-keys.yaml).
  home.activation.ensureSshPermissions = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ssh"
    $DRY_RUN_CMD chmod 0700 "${config.home.homeDirectory}/.ssh"
  '';
}
