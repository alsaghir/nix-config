# Ahmed's recipes on every host. nh finds the flake via NH_FLAKE (programs.nh.flake in
# ./default.nix) and the configuration via the current hostname / user@hostname.
{ config, ... }:
let
  flake = config.programs.nh.flake;
  jetbrains = "${config.home.homeDirectory}/.local/share/JetBrains/Toolbox/apps";
in
{
  justfile.recipes = ''
    # === nix-config ===
    rebuild:
        nh os switch

    rebuild-verbose:
        nh os switch -v

    rebuild-test:
        nh os test -v

    rebuild-debug:
        nh os test -vv

    rebuild-direct:
        sudo nixos-rebuild switch --flake ${flake} --no-reexec

    home-switch:
        nh home switch

    clean:
        nh clean all --keep 3

    generations:
        nix-env --list-generations --profile /nix/var/nix/profiles/system

    disk-usage:
        nix-store --gc --print-dead | du -ch

    # flake.lock is updated by CI (.github/workflows/build.yml), which also fills the binary cache
    update:
        cd ${flake} && git pull --ff-only

    # Local lock bump: whatever CI has not built yet is built on this machine
    update-local:
        cd ${flake} && nix flake update

    # Update and rebuild
    update-rebuild: update rebuild

    flake-info:
        cd ${flake} && nix flake show

    flake-check:
        cd ${flake} && nix flake check

    # === IDEs ===
    [no-cd]
    idea:
        ${jetbrains}/intellij-idea/bin/idea "{{invocation_directory()}}" > /dev/null 2>&1 & disown

    idea-path path:
        ${jetbrains}/intellij-idea/bin/idea "{{path}}" > /dev/null 2>&1 & disown

    [no-cd]
    rustrover:
        ${jetbrains}/rustrover/bin/rustrover "{{invocation_directory()}}" > /dev/null 2>&1 & disown
  '';
}
