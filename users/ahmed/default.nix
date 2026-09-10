{
  userConfig,
  inputs,
  pkgs,
  config,
  ...
}:

let

  aiApiKeysSopsFile = ./ai-keys.yaml;

in
{
  imports = [
    ./justfile.nix
    inputs.sops-nix.homeManagerModules.sops
    inputs.lazyvim.homeManagerModules.default
    ../../home/cli.nix
    ../../home/gnome.nix
    ../../home/gui-commons.nix
    ../../home/justfile.nix
    ../../home/ssh.nix
    ../../home/flatpak.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

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
}
