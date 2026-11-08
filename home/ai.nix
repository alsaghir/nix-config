{ lib, config, ... }:
{
  options.nixConfig.ai.enable = lib.mkEnableOption "AI coding/chat CLIs (Claude Code, Codex, Antigravity, aichat, aider)";

  config = lib.mkIf config.nixConfig.ai.enable {
    programs.antigravity-cli.enable = true;
    programs.claude-code.enable = true;
    programs.codex.enable = true;

    programs.aichat = {
      enable = true;
      settings = {
        model = "gemini:gemini-2.5-flash";
        stream = true;
        save = true;
        highlight = true;
        keybindings = "vi";
        clients = [
          {
            type = "gemini";
            api_base = "https://generativelanguage.googleapis.com/v1beta";
          }
          {
            type = "openai-compatible";
            name = "deepseek";
            api_base = "https://api.deepseek.com";
          }
          {
            type = "openai-compatible";
            name = "groq";
            api_base = "https://api.groq.com/openai/v1";
          }
          {
            type = "openai-compatible";
            name = "openrouter";
            api_base = "https://openrouter.ai/api/v1";
          }
          {
            type = "openai";
            api_base = "https://api.openai.com/v1";
          }
          {
            type = "openai-compatible";
            name = "mistral";
            api_base = "https://api.mistral.ai/v1";
          }
        ];
      };
    };
    programs.aider-chat = {
      enable = true;
      settings = {
        model = "deepseek/deepseek-chat";
        git = true;
        auto-commits = true;
        dark-mode = true;
      };
    };
  };
}
