{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  sshKeysSopsFile = ./ssh-keys.yaml;

in
{

  imports = [
    #inputs.plasma-manager.homeModules.plasma-manager
    #inputs.dms.homeModules.dank-material-shell
    #inputs.dms.homeModules.niri
    #inputs.niri.homeModules.niri
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  home.activation.ensureSshPermissions = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ssh"
    $DRY_RUN_CMD chmod 0700 "${config.home.homeDirectory}/.ssh"
  '';

  sops = {
    # or ${config.home.homeDirectory}/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Personal SSH keys
    secrets = {
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

      # Breadfast SSH keys
      breadfast_ssh_private_key = {
        key = "breadfast_ssh_private_key";
        path = "${config.home.homeDirectory}/.ssh/breadfast_id_rsa";
        mode = "0600";
        sopsFile = sshKeysSopsFile;

      };

      breadfast_ssh_public_key = {
        key = "breadfast_ssh_public_key";
        path = "${config.home.homeDirectory}/.ssh/breadfast_id_rsa.pub";
        mode = "0644";
        sopsFile = sshKeysSopsFile;

      };
    };

  };

}
