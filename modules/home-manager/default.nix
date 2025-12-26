{
  pkgsUnstable,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    ../../modules/home-manager/cli
    ../../modules/home-manager/gnome.nix
    ../../modules/home-manager/packages.nix
    ../../modules/home-manager/biglybt.nix
  ];

  programs.vscode = {
    enable = true;
    package = pkgsUnstable.vscode;
  };

  # journalctl --user --identifier=hm-activate-ahmed --since "30 minutes ago"
  # This is the Home Manager equivalent of system.activationScripts.
  # It will run as your user every time you run `home-manager switch`.
  home.activation.someScriptUsingHomeManager = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run echo "Running some script using Home Manager ..." >&2
  '';

}
