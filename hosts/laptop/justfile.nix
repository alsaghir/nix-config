{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = "asus-laptop";
in
{
  justfile.host = ''
    # Host-specific recipes for ${hostname}

    rebuild:
        nh os switch ~/nix-config --hostname ${hostname}

    rebuild-verbose:
        nh os switch ~/nix-config --hostname ${hostname} -v --impure

    rebuild-debug:
        nh os test ~/nix-config --hostname ${hostname} -vv --impure

    rebuild-test:
        nh os test ~/nix-config --hostname ${hostname} -v --impure

    rebuild-direct:
        sudo nixos-rebuild switch --flake ~/nix-config#${hostname} --impure --no-reexec

    clean:
        nh clean all --keep 3

    generations:
        nix-env --list-generations --profile /nix/var/nix/profiles/system

    disk-usage:
        nix-store --gc --print-dead | du -ch

    update:
        cd ~/nix-config && nix flake update

    # Update and rebuild
    update-rebuild: update rebuild

    flake-info:
        cd ~/nix-config && nix flake show

    flake-check:
        cd ~/nix-config && nix flake check

    # === ASUS-Specific Commands ===
    gpu-mode:
        supergfxctl --status

    gpu-offload:
        __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'

    profile:
        asusctl profile --profile-get

    profile-balanced:
        asusctl profile --profile-set Balanced

    profile-performance:
        asusctl profile --profile-set Performance

    profile-quiet:
        asusctl profile --profile-set Quiet
  '';
}
