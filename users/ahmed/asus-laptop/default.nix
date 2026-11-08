# ahmed on asus-laptop: graphical desktop, Flatpak, personal SSH keys.
{ ... }:
{
  config,
  lib,
  ...
}:
let
  sshKeysSopsFile = ./ssh-keys.yaml;

in
{

  imports = [
    ./justfile.nix
  ];

  nixConfig = {
    desktop.niri.enable = true;
    flatpak.enable = true;
  };

  home.activation.ensureSshPermissions = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ssh"
    $DRY_RUN_CMD chmod 0700 "${config.home.homeDirectory}/.ssh"
  '';

  # Personal SSH keys (age key: sops.age.keyFile in ../default.nix)
  sops.secrets = {
    ssh_private_key = {
      key = "ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
      sopsFile = sshKeysSopsFile;

    };

    ssh_public_key = {
      key = "ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      mode = "0644";
      sopsFile = sshKeysSopsFile;

    };

    rsa_ssh_private_key = {
      key = "rsa_ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa";
      mode = "0600";
      sopsFile = sshKeysSopsFile;

    };

    rsa_ssh_public_key = {
      key = "rsa_ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
      mode = "0644";
      sopsFile = sshKeysSopsFile;

    };
  };
}
