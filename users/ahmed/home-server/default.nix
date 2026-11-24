# ahmed on home-server: GNOME over RDP (Firefox is system-wide, hosts/home-server/default.nix),
# the server's own SSH key (not the laptop's personal keys).
{ ... }:
{ ... }:
{
  nixConfig = {
    desktop.gnome.enable = true;

    # Age key: sops.age.keyFile in ../default.nix.
    ssh-keys = {
      sopsFile = ./ssh-keys.yaml;
      files = {
        id_ed25519.key = "ssh_private_key";
        "id_ed25519.pub".key = "ssh_public_key";
      };
    };
  };

  programs.vscode.enable = true;
}
