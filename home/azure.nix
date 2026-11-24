# Azure CLI with extensions from nixpkgs (no runtime `az extension add`), and one isolated
# AZURE_CONFIG_DIR per profile: `az-<profile>` switches, so a command can never silently
# run against another tenant's login.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.azure;

  switcher = name: profile: ''
    az-${name}() {
      export AZURE_CONFIG_DIR=${lib.escapeShellArg "${cfg.profilesDir}/azure-${name}"}
      echo "AZURE_CONFIG_DIR -> $AZURE_CONFIG_DIR"
      az account show --query "{Sub:name, User:user.name}" -o yaml 2>/dev/null \
        || echo ${
          lib.escapeShellArg (
            "not logged in; run: az login"
            + lib.optionalString (profile.tenant != null) " --tenant ${profile.tenant}"
          )
        }
    }
  '';

  switchers = lib.concatStrings (lib.mapAttrsToList switcher cfg.profiles);
in
{
  options.nixConfig.azure = {
    enable = lib.mkEnableOption "the Azure CLI";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.azure-cli-extensions.log-analytics ]";
      description = "Extensions built into the CLI (pkgs.azure-cli-extensions).";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.tenant = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Tenant suggested for `az login` when the profile is not logged in.";
          };
        }
      );
      default = { };
      description = "One `az-<name>` shell function per profile, each with its own AZURE_CONFIG_DIR.";
    };

    profilesDir = lib.mkOption {
      type = lib.types.str;
      default = config.xdg.configHome;
      defaultText = lib.literalExpression "config.xdg.configHome";
      description = "Parent of the per-profile `azure-<name>` config directories.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (pkgs.azure-cli.withExtensions cfg.extensions) ];
    programs.bash.initExtra = switchers;
    programs.zsh.initContent = switchers;
  };
}
