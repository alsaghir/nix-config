# Binary cache filled by `nix run .#ci` (ci/default.nix): paths not on cache.nixos.org
# (overlays, kernel modules, generated configs). The bucket is private, so the nix-daemon
# (which substitutes) gets a read-only Backblaze B2 key as AWS_* variables from
# ./binary-cache.yaml. Without the secret the substituter fails and Nix builds locally.
{ config, ... }:
let
  cache = import ../../lib/binary-cache.nix;
in
{
  nix.settings = {
    # Priority 60 (cache.nixos.org is 40): only paths missing upstream are looked up here,
    # which keeps B2 transactions within the free daily allowance.
    substituters = [ "${cache.url}&priority=60" ];
    trusted-public-keys = [ cache.publicKey ];
  };

  sops.secrets = {
    b2_key_id.sopsFile = ./binary-cache.yaml;
    b2_application_key.sopsFile = ./binary-cache.yaml;
  };

  sops.templates."nix-daemon-b2.env" = {
    content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder.b2_key_id}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.b2_application_key}
    '';
    restartUnits = [ "nix-daemon.service" ];
  };

  # "-": optional, so the daemon still starts before the secret exists (e.g. first install).
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
    "-${config.sops.templates."nix-daemon-b2.env".path}";
}
