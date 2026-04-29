{
  config,
  pkgs,
  lib,
  self,
  hostname,
  ...
}:
let
  userLib = import ../../lib { inherit lib; };
  primaryUsername = userLib.getPrimaryUser hostname;
  userConfig = userLib.getPrimaryUserConfig hostname;
in
{
  imports = [
    ../../roles/core.nix
    ../../nixos/services/nix-ld.nix
    ../../users/user.nix
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  wsl.enable = true;
  wsl.defaultUser = primaryUsername;
  wsl.useWindowsDriver = true;
  wsl.startMenuLaunchers = true;
  wsl.wslConf.automount.enabled = true;
  wsl.wslConf.automount.mountFsTab = false;  # Let systemd handle fstab
  wsl.wslConf.networking.generateHosts = true;
  wsl.wslConf.networking.generateResolvConf = true;
  wsl.wslConf.interop.enabled = true;
  wsl.wslConf.interop.appendWindowsPath = true;

  # Host-specific settings
  networking.hostName = hostname;
  system.stateVersion = "25.11";
}
