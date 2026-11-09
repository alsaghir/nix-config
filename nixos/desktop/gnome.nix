# GNOME (GDM + GNOME Shell) with desktop/fonts.nix; optional headless RDP login.
#
# Remote desktop (remoteDesktop.enable): GDM's system-level RDP server on port 3389, which
# shows the login screen and starts a GNOME session per connection (no monitor or local login
# needed). Fully declarative (gnome-remote-desktop 50.x, read from its source):
#   settings     /etc/gnome-remote-desktop/grd.conf, [RDP] enabled/port/tls-cert/tls-key
#   credentials  without a TPM (the TPM backend is tried first) the daemon reads
#                ~gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini:
#                [RDP] credentials=<GVariant a{sv} with 'username' and 'password'>
# Both come from remoteDesktop.sopsFile (decrypted with the host SSH key), keys:
#   rdp_username, rdp_password  RDP gate, not a login (GDM asks for the account afterwards);
#                               no ' or \ in them (they are quoted into a GVariant string)
#   rdp_tls_cert, rdp_tls_key   self-signed; stable across reinstalls, so clients trust it once
# grdctl --system changes don't persist: grd.conf is read-only, credentials are re-rendered.
# Client: RDP to <host>:3389 (Remmina / Windows mstsc), pass the RDP gate, then log in at GDM.
# Closing the client keeps the session for reconnecting, but if the daemon restarts meanwhile
# (a switch that changes its unit) the session can't be reclaimed (grd 50: the handover runs as
# a user service, outside the session): GDM accepts the password and returns to the login
# screen. Log out before such a switch, or end the orphan: `loginctl list-sessions`, then
# `loginctl terminate-session <id>` for your session without a TTY.
# one line per ahmed session: id, service, type
# loginctl list-sessions --no-legend | while read s u n rest; do [ "$n" = ahmed ] && echo "$s $(loginctl show-session $s -p Service -p Type --value | tr '\n' ' ')"; done
{
  config,
  lib,
  ...
}:
let
  cfg = config.nixConfig.desktop.gnome;
  grdHome = config.users.users.gnome-remote-desktop.home;
  grdData = "${grdHome}/.local/share/gnome-remote-desktop";
  restartUnits = [ "gnome-remote-desktop.service" ];
  grdSecret = {
    inherit (cfg.remoteDesktop) sopsFile;
    owner = "gnome-remote-desktop";
    inherit restartUnits;
  };
in
{
  options.nixConfig.desktop.gnome = {
    enable = lib.mkEnableOption "the GNOME desktop with GDM";
    remoteDesktop = {
      enable = lib.mkEnableOption "headless RDP login to GNOME (gnome-remote-desktop, system mode)";
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file with rdp_username, rdp_password, rdp_tls_cert, rdp_tls_key (see header).";
      };
    };
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
        systemd.services.gnome-remote-desktop = {
          # System-mode daemon (RDP at the GDM login screen) is not started by default.
          wantedBy = [ "graphical.target" ];
          # The daemon only watches config files that existed at startup, and sops-nix skips
          # restartUnits on the first activation that creates /run/secrets: restart on change.
          restartTriggers = [ config.environment.etc."gnome-remote-desktop/grd.conf".source ];
        };
        networking.firewall.allowedTCPPorts = [ 3389 ];

        sops.secrets = {
          rdp_username.sopsFile = cfg.remoteDesktop.sopsFile;
          rdp_password.sopsFile = cfg.remoteDesktop.sopsFile;
          rdp_tls_cert = grdSecret;
          rdp_tls_key = grdSecret;
        };

        sops.templates."grd-credentials.ini" = {
          owner = "gnome-remote-desktop";
          path = "${grdData}/credentials.ini";
          inherit restartUnits;
          content = ''
            [RDP]
            credentials={'username': <'${config.sops.placeholder.rdp_username}'>, 'password': <'${config.sops.placeholder.rdp_password}'>}
          '';
        };

        environment.etc."gnome-remote-desktop/grd.conf".text = ''
          [RDP]
          enabled=true
          port=3389
          tls-cert=${config.sops.secrets.rdp_tls_cert.path}
          tls-key=${config.sops.secrets.rdp_tls_key.path}
        '';

        # sops-nix creates the template's parent directories as root; hand them to the daemon.
        systemd.tmpfiles.settings."10-gnome-remote-desktop" = {
          "${grdHome}/.local".d = {
            user = "gnome-remote-desktop";
            group = "gnome-remote-desktop";
            mode = "0700";
          };
          "${grdHome}/.local/share".d = {
            user = "gnome-remote-desktop";
            group = "gnome-remote-desktop";
            mode = "0700";
          };
          "${grdData}".d = {
            user = "gnome-remote-desktop";
            group = "gnome-remote-desktop";
            mode = "0700";
          };
        };
      })
    ]
  );
}
