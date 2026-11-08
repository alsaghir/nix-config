# GNOME (GDM + GNOME Shell) with desktop/fonts.nix; optional headless RDP login.
#
# Remote desktop (remoteDesktop.enable): GDM's system-level RDP server on port 3389, which
# shows the login screen and starts a GNOME session per connection (no monitor or local login
# needed). Credentials and TLS certificate are runtime state, kept out of Nix (public repo).
# One-time setup on the host:
#   d=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop
#   sudo -u gnome-remote-desktop mkdir -p $d
#   sudo -u gnome-remote-desktop openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
#     -subj "/CN=$(hostname)" -keyout $d/rdp-tls.key -out $d/rdp-tls.crt
#   sudo grdctl --system rdp set-tls-key  $d/rdp-tls.key
#   sudo grdctl --system rdp set-tls-cert $d/rdp-tls.crt
#   sudo grdctl --system rdp set-credentials <rdp-user> <rdp-password>   # RDP gate, not a login
#   sudo grdctl --system rdp enable
#   sudo systemctl restart gnome-remote-desktop
#   sudo grdctl --system status
# Client: RDP to <host>:3389 (Remmina / Windows mstsc), pass the RDP gate, then log in at GDM.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.desktop.gnome;
in
{
  options.nixConfig.desktop.gnome = {
    enable = lib.mkEnableOption "the GNOME desktop with GDM";
    remoteDesktop.enable = lib.mkEnableOption "headless RDP login to GNOME (gnome-remote-desktop, system mode)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # GNOME brings its own input method, gvfs, udisks2 and fonts; skip the niri-oriented
        # desktop/common.nix base (Flatpak, JACK low-latency audio). Add our font picks only.
        nixConfig.desktop.fonts.enable = lib.mkDefault true;

        services.displayManager.gdm.enable = true;
        services.desktopManager.gnome.enable = true;
      }
      (lib.mkIf cfg.remoteDesktop.enable {
        services.gnome.gnome-remote-desktop.enable = true;
        # System-mode daemon (RDP at the GDM login screen) is not started by default.
        systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];
        networking.firewall.allowedTCPPorts = [ 3389 ];
        environment.systemPackages = [ pkgs.openssl ]; # one-time TLS certificate (header)
      })
    ]
  );
}
