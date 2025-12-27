{ config, lib, pkgs, ... }:

let
  registry = import ./registry.nix;
  hostname = config.networking.hostName;
  primaryUsername = registry.hosts.${hostname};
  userConfig = registry.users.${primaryUsername};
  
  # Get the host-specific justfile content if it exists
  hostJustfile = config.justfile.host or "";
  
  # Create the global justfile content
  globalJustfileContent = ''
    # Global justfile for ${userConfig.username}
    # This file is managed by NixOS configuration
    
    default:
      @just --list

    [no-cd]
    idea:
      ${userConfig.homeDirectory}/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea . > /dev/null 2>&1 & disown
    
    idea-path path:
      ${userConfig.homeDirectory}/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea "{{path}}" > /dev/null 2>&1 & disown
    
    ${hostJustfile}
  '';
  
  # Write the justfile to a file in the Nix store
  justfileFile = pkgs.writeText "justfile" globalJustfileContent;
in
{
  options.justfile = {
    host = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Host-specific justfile recipes";
    };
  };

  config = {
    # Create the .config/just directory and justfile using systemd-tmpfiles
    systemd.tmpfiles.rules = [
      "d ${userConfig.homeDirectory}/.config 0755 ${userConfig.username} users -"
      "d ${userConfig.homeDirectory}/.config/just 0755 ${userConfig.username} users -"
      "L+ ${userConfig.homeDirectory}/.config/just/justfile - - - - ${justfileFile}"
    ];
  };
}
