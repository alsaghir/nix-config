{
  config,
  pkgs,
  lib,
  ...
}:

let
  userLib = import ../lib { inherit lib; };
  hostname = config.networking.hostName;
  primaryUsername = userLib.getPrimaryUser hostname;
  userConfig = userLib.getPrimaryUserConfig hostname;
in

{
  imports = [ ./justfile.nix ];

  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.fullName;
    home = userConfig.homeDirectory;
    shell = pkgs.${userConfig.shell}; # Dynamically resolve shell package
    extraGroups = userConfig.extraGroups;
  };
}
