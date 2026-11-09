# ahmed on home-server: GNOME over RDP (Firefox is system-wide, hosts/home-server/default.nix),
# the server's own SSH key (read-only deploy key on ai-rules; not the laptop's personal keys).
{ ... }:
{ config, ... }:
let
  sshKeysSopsFile = ./ssh-keys.yaml;
in
{
  nixConfig.desktop.gnome.enable = true;

  programs.vscode.enable = true;

  # Age key: sops.age.keyFile in ../default.nix
  sops.secrets = {
    ssh_private_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
      sopsFile = sshKeysSopsFile;
    };
    ssh_public_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      mode = "0644";
      sopsFile = sshKeysSopsFile;
    };
  };
}
