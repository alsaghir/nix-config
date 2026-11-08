# OpenSSH server, key-only. Keys come from registry.nix (users.<user>.sshAuthorizedKeys).
# root accepts the primary user's keys (as in nixos-anywhere's examples): remote deploys
# (`nixos-rebuild --target-host root@<host>`) and first-boot admin (`ssh root@<host> passwd <user>`).
{ config, lib, ... }:
let
  cfg = config.nixConfig.services.openssh;
  primaryUser = config.nixConfig.users.${config.nixConfig.primaryUser};
in
{
  options.nixConfig.services.openssh.enable =
    lib.mkEnableOption "the OpenSSH server (key-only logins)";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true; # also opens port 22
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    users.users.root.openssh.authorizedKeys.keys = primaryUser.sshAuthorizedKeys;
  };
}
