# Binary cache filled by CI (.github/workflows/build.yml): paths CI built that are not on
# cache.nixos.org (overlays, kernel modules, generated configs). The bucket is private, so
# the nix-daemon (which substitutes) gets a read-only Backblaze B2 key as AWS_* variables
# from ./binary-cache.yaml. Without the secret the substituter fails and Nix builds locally.
{ config, ... }:
let
  # Same bucket as the workflow's push step.
  bucket = "nixosstorage";
  endpoint = "s3.us-east-005.backblazeb2.com";
  region = "us-east-005";
  # Public half of the CI signing key (private half: .github/secrets.yaml cache_signing_key).
  publicKey = "nixosstorage-1:G6XSw2yUEHJScdABPIm0DGXwLmKLpVOrr1G/KbOlkMQ=";
in
{
  nix.settings = {
    # Priority 60 (cache.nixos.org is 40): only paths missing upstream are looked up here,
    # which keeps B2 transactions within the free daily allowance.
    substituters = [ "s3://${bucket}?endpoint=${endpoint}&region=${region}&priority=60" ];
    trusted-public-keys = [ publicKey ];
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
