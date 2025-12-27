{
  config,
  pkgs,
  lib,
  ...
}:

let
  registry = import ./registry.nix;
  hostname = config.networking.hostName;
  primaryUsername = registry.hosts.${hostname};
  userConfig = registry.users.${primaryUsername};
in

{
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.fullName;
    home = userConfig.homeDirectory;
    shell = pkgs.${userConfig.shell}; # Dynamically resolve shell package
    extraGroups = userConfig.extraGroups;
  };
}
