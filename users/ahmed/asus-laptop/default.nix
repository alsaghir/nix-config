{
  config,
  pkgs,
  lib,
  ...
}:
let
  sopsFile = ./ssh-keys.yaml;

in
{

  home.activation.ensureSshPermissions = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ssh"
    $DRY_RUN_CMD chmod 0700 "${config.home.homeDirectory}/.ssh"
  '';

  sops = {
    defaultSopsFile = sopsFile;
    # or ${config.home.homeDirectory}/.config/sops/age/keys.txt
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    # Personal SSH keys
    secrets.ssh_private_key = {
      key = "ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };

    secrets.ssh_public_key = {
      key = "ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      mode = "0644";
    };

    secrets.rsa_ssh_private_key = {
      key = "rsa_ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa";
      mode = "0600";
    };

    secrets.rsa_ssh_public_key = {
      key = "rsa_ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
      mode = "0644";
    };

    # Breadfast SSH keys
    secrets.breadfast_ssh_private_key = {
      key = "breadfast_ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/breadfast_id_rsa";
      mode = "0600";
    };

    secrets.breadfast_ssh_public_key = {
      key = "breadfast_ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/breadfast_id_rsa.pub";
      mode = "0644";
    };
  };

}
