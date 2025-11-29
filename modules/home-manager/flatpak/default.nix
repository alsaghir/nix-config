{ lib, pkgs, ... }:

{

  # journalctl --user --identifier=hm-activate-ahmed --since "30 minutes ago"
  # This is the Home Manager equivalent of system.activationScripts.
  # It will run as your user every time you run `home-manager switch`.
  home.activation.helloFlatpakUser = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run echo "Patching BiglyBT Home Manager ..." >&2
    echo "Patching BiglyBT Home Manager ..." >&2
  '';

  # You can also manage user-installed flatpaks declaratively here.
  # For example:
  #
  # services.flatpak.packages = [
  #   {
  #     appId = "org.onlyoffice.desktopeditors";
  #     origin = "flathub";
  #   }
  # ];
}
