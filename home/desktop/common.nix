# Compositor-agnostic GUI base: browser, terminal, editor, GTK and browser MIME defaults.
# Personal app picks live in the user profiles (users/<user>/<host>/default.nix).
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixConfig.desktop.common.enable =
    lib.mkEnableOption "compositor-agnostic GUI base (browser, terminal, editor, theming)";

  config = lib.mkIf config.nixConfig.desktop.common.enable {
    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
      nativeMessagingHosts = [
        pkgs.firefoxpwa
      ];
    };

    programs.ghostty = {
      enable = true;
      settings = {
        font-family = "Hack Nerd Font";
        font-size = 12;
      };
    };

    programs.vscode = {
      enable = true;
      # VS Code picks the keyring from XDG_CURRENT_DESKTOP and doesn't know "niri"; name it explicitly.
      argvSettings = {
        password-store = "gnome-libsecret";
        enable-crash-reporter = false;
      };
    };

    gtk.enable = true;

    # ~/.config/mimeapps.list is now Nix-owned (read-only). Only list types claimed by several apps;
    # a type with a single claimant already resolves on its own. More defaults (merged) in
    # home/desktop/dms.nix and the user profiles.
    # Find claimants:  grep -l '<mime>' ~/.nix-profile/share/applications/*.desktop
    # Current default: xdg-mime query default <mime>
    # If an app fails to register a handler at runtime, add its line here.
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
      };
    };

    home.packages = with pkgs; [
      adwaita-icon-theme
      adwaita-fonts
    ];
  };
}
