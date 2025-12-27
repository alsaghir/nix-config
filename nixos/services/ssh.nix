{ pkgs, lib, ... }:

{
  # Ensure OpenSSH client is available
  environment.systemPackages = [ pkgs.openssh ];

  # Use GNOME Keyring as ssh-agent (recommended on GNOME; avoids custom user services)
  services.gnome.gnome-keyring.enable = true;

  # System-wide SSH client config
  environment.etc."ssh/ssh_config".text = ''
    Host github
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519
      AddKeysToAgent yes
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
