{ pkgs, lib, ... }:

{
  # Ensure OpenSSH client is available
  environment.systemPackages = [ pkgs.openssh ];

  # System-wide SSH client config
  environment.etc."ssh/ssh_config".text = ''
    Host github
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519
      AddKeysToAgent yes
      IdentitiesOnly yes
      PreferredAuthentications publickey

    Host ssh.dev.azure.com
      HostName ssh.dev.azure.com
      User git
      IdentityFile ~/.ssh/id_rsa
      AddKeysToAgent no
      IdentitiesOnly yes
      PreferredAuthentications publickey

    Host bfgithub
      HostName github.com
      User git
      IdentityFile ~/.ssh/breadfast_id_rsa
      AddKeysToAgent no
      IdentitiesOnly yes
      IdentityAgent none
      PreferredAuthentications publickey

    Host !bfgithub !github *
      IdentityFile ~/.ssh/id_ed25519
      AddKeysToAgent yes
      IdentitiesOnly yes
      User git
  '';
}
