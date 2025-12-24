{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
          PreferredAuthentications = "publickey";
        };
      };
      "bfgithub" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/breadfast_id_rsa";
        extraOptions = {
          AddKeysToAgent = "no";
          IdentitiesOnly = "yes";
          IdentityAgent = "none";
          PreferredAuthentications = "publickey";
        };
      };
      "!bfgithub !github *" = {
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
        user = "git";
      };
    };
  };

  services.ssh-agent.enable = true;
  home.file.".ssh/config".force = true;

  # After HM writes symlinks, replace ~/.ssh/config with a real file and set 600
  # https://github.com/nix-community/home-manager/issues/322
  home.activation.fixSshConfigPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"

    # Home Manager creates the config at ~/.ssh/config as a symlink
    # We need to find where it points and copy the content
    sshConfig="$HOME/.ssh/config"

    if [ -L "$sshConfig" ]; then
      # It's a symlink - resolve it and copy
      target=$(readlink -f "$sshConfig")
      run rm "$sshConfig"
      run install -m600 "$target" "$sshConfig"
    elif [ -f "$sshConfig" ]; then
      # It's already a regular file - just fix permissions
      run chmod 600 "$sshConfig"
    fi
  '';

}
