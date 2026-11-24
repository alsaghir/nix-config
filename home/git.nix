# Git identities and GitHub over HTTPS, with every value from sops (sops-nix's Home Manager
# module must be imported by the profile).
#
# - `github.tokenFile`: a sops file whose `github_token` (a fine-grained PAT) a credential
#   helper serves for https://github.com, and github.com SSH URLs are rewritten to HTTPS.
#   This covers git and Nix's `git+https` flake inputs (fetched through the git CLI).
# - `identities.<name>`: a sops file with `git_name`/`git_email`, rendered at activation
#   into an include file; `condition` (an includeIf condition) scopes it, null is global.
{ config, lib, ... }:
let
  cfg = config.nixConfig.git;
  tokenSecret = "github_token";
  identitySecret = name: field: "git-identity-${name}-${field}";
in
{
  options.nixConfig.git = {
    enable = lib.mkEnableOption "git with sops-provided identities and GitHub token";

    github.tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "sops file holding `github_token`; null leaves GitHub authentication alone.";
    };

    identities = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            sopsFile = lib.mkOption {
              type = lib.types.path;
              description = "sops file holding `git_name` and `git_email`.";
            };
            condition = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "gitdir:~/Projects/";
              description = "includeIf condition; null applies the identity everywhere.";
            };
          };
        }
      );
      default = { };
      description = "Commit identities. A scoped identity overrides a global one inside its scope.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { programs.git.enable = true; }

      (lib.mkIf (cfg.github.tokenFile != null) {
        sops.secrets.${tokenSecret}.sopsFile = cfg.github.tokenFile;

        # gh's helper would answer for github.com too, with whatever account gh is logged in as.
        programs.gh.gitCredentialHelper.enable = lib.mkDefault false;

        programs.git.settings = {
          # The empty entry drops helpers set before this file (e.g. gh's), so this one answers.
          credential."https://github.com".helper = [
            ""
            "!f() { test \"$1\" = get && printf 'username=x-access-token\\npassword=%s\\n' \"$(cat ${
              config.sops.secrets.${tokenSecret}.path
            })\"; }; f"
          ];
          url."https://github.com/".insteadOf = [
            "git@github.com:"
            "ssh://git@github.com/"
          ];
        };
      })

      {
        sops.secrets = lib.mkMerge (
          lib.mapAttrsToList (
            name: id:
            lib.listToAttrs (
              map
                (field: {
                  name = identitySecret name field;
                  value = {
                    inherit (id) sopsFile;
                    key = "git_${field}";
                  };
                })
                [
                  "name"
                  "email"
                ]
            )
          ) cfg.identities
        );

        sops.templates = lib.mapAttrs' (
          name: _:
          lib.nameValuePair "git-identity-${name}" {
            content = ''
              [user]
                name = ${config.sops.placeholder.${identitySecret name "name"}}
                email = ${config.sops.placeholder.${identitySecret name "email"}}
            '';
          }
        ) cfg.identities;

        # Unscoped identities first: a later include wins, so scoped ones override them.
        programs.git.includes = lib.sortOn (inc: if inc.condition == null then 0 else 1) (
          lib.mapAttrsToList (name: id: {
            path = config.sops.templates."git-identity-${name}".path;
            inherit (id) condition;
          }) cfg.identities
        );
      }
    ]
  );
}
