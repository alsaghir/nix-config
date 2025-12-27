{
  config,
  pkgs,
  lib,
  ...
}:
let
  sopsFile = ./asus-laptop-ssh-keys.yaml;

  # Import user registry to get paths
  registry = import ../users/registry.nix;
  hostname = config.networking.hostName;
  primaryUsername = registry.hosts.${hostname};
  userConfig = registry.users.${primaryUsername};

  # Get SSH key secret name for this host
  sshKeySecret = userConfig.sshKeys.${hostname};
in
{

  sops = {
    defaultSopsFile = sopsFile;
    
    # age.keyFile is inherited from roles/common.nix
    # DO NOT set it here - /home is not mounted during early boot!

    # Personal SSH keys
    secrets.ssh_private_key = {
      key = "ssh_private_key";
      path = "${userConfig.homeDirectory}/.ssh/id_ed25519";
      owner = userConfig.username;
      mode = "0600";
    };

    secrets.ssh_public_key = {
      key = "ssh_public_key";
      path = "${userConfig.homeDirectory}/.ssh/id_ed25519.pub";
      owner = userConfig.username;
      mode = "0644";
    };

    # Breadfast SSH keys
    secrets.breadfast_ssh_private_key = {
      key = "breadfast_ssh_private_key";
      path = "${userConfig.homeDirectory}/.ssh/breadfast_id_rsa";
      owner = userConfig.username;
      mode = "0600";
    };

    secrets.breadfast_ssh_public_key = {
      key = "breadfast_ssh_public_key";
      path = "${userConfig.homeDirectory}/.ssh/breadfast_id_rsa.pub";
      owner = userConfig.username;
      mode = "0644";
    };
  };

}
