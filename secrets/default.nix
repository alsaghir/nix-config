{
  config,
  ...
}:
let
  primaryUser = builtins.head (builtins.attrNames config.home-manager.users);
  sopsFile = ./asus-laptop-ssh-keys.yaml;
in
{
  sops.secrets.ssh_private_key = {
    inherit sopsFile;
    key = "ssh_private_key";
    path = "/home/${primaryUser}/.ssh/id_ed25519";
    owner = primaryUser;
    mode = "0600";
  };

  sops.secrets.breadfast_ssh_private_key = {
    sopsFile = sopsFile;
    key = "breadfast_ssh_private_key";
    path = "/home/${primaryUser}/.ssh/breadfast_id_rsa";
    owner = primaryUser;
    mode = "0600";
  };

  sops.secrets.ssh_public_key = {
    sopsFile = sopsFile;
    key = "ssh_public_key";
    path = "/home/${primaryUser}/.ssh/id_ed25519.pub";
    owner = primaryUser;
    mode = "0644";
  };

  sops.secrets.breadfast_ssh_public_key = {
    sopsFile = sopsFile;
    key = "breadfast_ssh_public_key";
    path = "/home/${primaryUser}/.ssh/breadfast_id_rsa.pub";
    owner = primaryUser;
    mode = "0644";
  };

}
