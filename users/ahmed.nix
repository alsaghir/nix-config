# Home Manager configuration for ahmed.
# Consumes the user registry for user-specific settings.
{ config, lib, ... }:

let
  # Import the user registry
  registry = import ./registry.nix;
  userConfig = registry.users.ahmed;
in
{
  imports = userConfig.homeModules;

  # Set username and home directory from registry
  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  
  # Home Manager state version
  home.stateVersion = "25.05";
}