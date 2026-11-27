# KDE Plasma 6 desktop, system side (the session itself: home/desktop/plasma.nix).
#
# Secrets: KWallet, not gnome-keyring. The plasma6 module enables pam_kwallet on `login`, which
# the plasmalogin PAM stack includes, so the wallet unlocks with the login password. KWallet
# also serves org.freedesktop.secrets, so libsecret clients (VS Code, Electron) work unchanged.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixConfig.desktop.plasma.enable =
    lib.mkEnableOption "the KDE Plasma 6 desktop (with Plasma Login Manager)";

  config = lib.mkIf config.nixConfig.desktop.plasma.enable {
    nixConfig.desktop.common.enable = lib.mkDefault true;

    services.desktopManager.plasma6.enable = true;
    services.displayManager.plasma-login-manager.enable = true;

    # Music player; mpv/VLC/Haruna cover media.
    environment.plasma6.excludePackages = [ pkgs.kdePackages.elisa ];

    # Unlike the Home Manager service, this also opens KDE Connect's firewall ports.
    programs.kdeconnect.enable = true;
  };
}
