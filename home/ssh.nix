{ ... }:
{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = {
      "github" = {
        hostname                = "github.com";
        user                    = "git";
        identityFile            = "~/.ssh/id_ed25519";
        identitiesOnly          = true;
        addKeysToAgent          = "yes";
        PreferredAuthentications = "publickey";
      };

      "ssh.dev.azure.com" = {
        hostname                = "ssh.dev.azure.com";
        user                    = "git";
        identityFile            = "~/.ssh/id_rsa";
        addKeysToAgent          = "no";
        identitiesOnly          = true;
        PreferredAuthentications = "publickey";
      };

      "bfgithub" = {
        hostname                = "github.com";
        user                    = "git";
        identityFile            = "~/.ssh/breadfast_id_rsa";
        addKeysToAgent          = "no";
        identitiesOnly          = true;
        PreferredAuthentications = "publickey";
        IdentityAgent            = "none";
      };

      # catch-all — must be last
      "* !bfgithub !github" = {
        identityFile            = "~/.ssh/id_ed25519";
        addKeysToAgent          = "yes";
        identitiesOnly          = true;
        user                    = "git";
      };
    };
  };
}