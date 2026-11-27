# Single source of truth for who and what exists: users, hosts, and who uses which host.
# Read only by lib/default.nix, which builds every flake output from it.
#
# Adding a host:
#   1. an entry under `hosts` below
#   2. hosts/<host>/default.nix              NixOS entry point (omit for Home-Manager-only hosts)
#   3. users/<user>/<host>/default.nix       optional per-host Home Manager profile
{
  users = {
    ahmed = {
      username = "ahmed";
      fullName = "Ahmed";
      homeDirectory = "/home/ahmed";
      shell = "zsh"; # attribute name in pkgs
      extraGroups = [
        "networkmanager"
        "wheel"
        "i2c"
        "video"
        "render"
        "input"
        "podman"
      ];
      # Public (not secret): the laptop's ~/.ssh/id_ed25519.pub, whose private half is in sops.
      sshAuthorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnRRZqnglLzE+UpigRoVjIIvtNCUHv2EpEA7d97UaoH ahmedalsaghirxyz@gmail.com"
      ];
    };
  };

  hosts = {
    asus-laptop = {
      system = "x86_64-linux";
      primaryUser = "ahmed";
      # Users with an account on this host. Each gets a Home Manager configuration from
      # users/<user> + optional users/<user>/<host>, plus the extra modules listed here.
      userModules = {
        ahmed = [ ];
      };
      # Overlays for this host only, on top of the global overlays/default.nix.
      # Applied to both its NixOS and Home Manager package sets.
      extraOverlays = [ ./overlays/github-copilot-app-igpu ];
      # Monitor layout (schema: lib/displays.nix), injected into NixOS and Home Manager;
      # niri, kanshi, DMS and the greeter are generated from it.
      displays = import ./hosts/asus-laptop/displays.nix;
    };

    # Always-on LAN box: media (Jellyfin), GNOME over RDP. No displays: GNOME
    # manages its own monitors, and nothing here is generated from a layout.
    home-server = {
      system = "x86_64-linux";
      primaryUser = "ahmed";
      userModules = {
        ahmed = [ ];
      };
    };
  };
}
