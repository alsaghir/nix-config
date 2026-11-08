# Login accounts for every user registry.nix assigns to this host (schema: lib/users.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.nixConfig) users primaryUser;
in
{
  assertions = [
    {
      assertion = users ? ${primaryUser};
      message = "nixConfig.primaryUser \"${primaryUser}\" is not one of this host's users.";
    }
  ];

  users.users = lib.mapAttrs' (
    _: u:
    lib.nameValuePair u.username {
      isNormalUser = true;
      description = u.fullName;
      home = u.homeDirectory;
      shell = pkgs.${u.shell};
      inherit (u) extraGroups;
      openssh.authorizedKeys.keys = u.sshAuthorizedKeys;
    }
  ) users;
}
