# nixConfig.users / nixConfig.primaryUser: the accounts registry.nix assigns to this host
# (hosts.<host>.userModules keys → users.<user>), injected by lib/default.nix into NixOS.
# Pure option declaration. Consumers: nixos/core/users.nix (accounts) and host modules
# that need a user's home, via config.nixConfig.users.${config.nixConfig.primaryUser}.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.nixConfig = {
    users = mkOption {
      default = { };
      description = "Accounts on this host, keyed by registry user id.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              username = mkOption {
                type = types.str;
                default = name;
              };
              fullName = mkOption {
                type = types.str;
                default = name;
              };
              homeDirectory = mkOption {
                type = types.str;
                default = "/home/${name}";
              };
              shell = mkOption {
                type = types.str;
                default = "bash";
                description = "Attribute name of the shell package in pkgs.";
              };
              extraGroups = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              sshAuthorizedKeys = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Public keys allowed to log in as this user (used when the host runs sshd).";
              };
            };
          }
        )
      );
    };
    primaryUser = mkOption {
      type = types.str;
      description = "Key into nixConfig.users of the host's main user.";
    };
  };
}
