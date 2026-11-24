# SSH keys decrypted from one sops file into ~/.ssh (sops-nix's Home Manager module must be
# imported by the profile). Off until `files` is non-empty.
{ config, lib, ... }:
let
  cfg = config.nixConfig.ssh-keys;
  sshDir = "${config.home.homeDirectory}/.ssh";
in
{
  options.nixConfig.ssh-keys = {
    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "sops file holding every key in `files`.";
    };

    files = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              key = lib.mkOption {
                type = lib.types.str;
                description = "Key in `sopsFile`; also the sops-nix secret name.";
              };
              mode = lib.mkOption {
                type = lib.types.str;
                default = if lib.hasSuffix ".pub" name then "0644" else "0600";
                defaultText = lib.literalMD "`0644` for `*.pub`, else `0600`";
                description = "File mode.";
              };
            };
          }
        )
      );
      default = { };
      example = {
        id_ed25519.key = "ssh_private_key";
        "id_ed25519.pub".key = "ssh_public_key";
      };
      description = "File names under ~/.ssh, each decrypted from a key in `sopsFile`.";
    };
  };

  config = lib.mkIf (cfg.files != { }) {
    sops.secrets = lib.mapAttrs' (
      file: f:
      lib.nameValuePair f.key {
        inherit (cfg) sopsFile;
        inherit (f) mode;
        path = "${sshDir}/${file}";
      }
    ) cfg.files;

    # ~/.ssh exists, private, before sops-nix writes keys into it.
    home.activation.ensureSshDir = lib.hm.dag.entryBefore [ "sops-nix" ] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${sshDir}"
      $DRY_RUN_CMD chmod 0700 "${sshDir}"
    '';
  };
}
