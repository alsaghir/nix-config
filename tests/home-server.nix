# home-server booted in a VM (README "VM test"): its real modules, not a copy, so the test
# breaks when the configuration does. A second VM plays a LAN client.
#
# Not covered: anything behind sops secrets. They are encrypted to the real host's SSH key,
# which the VM does not have, so sops-nix fails to decrypt and RDP stays down. The disks
# (disko.nix, storage.nix) are replaced by the VM's own (qemu-vm.nix).
{
  pkgs,
  nixosConfiguration,
}:
pkgs.testers.runNixOSTest {
  name = "home-server";

  # home-server brings its own package set (the host's overlays), so nodes set nixpkgs.pkgs.
  node.pkgsReadOnly = false;

  nodes = {
    home-server = {
      # nixosSystem's user modules and package set: the configuration minus its evaluation.
      imports = nixosConfiguration._module.args.modules;
      nixpkgs.pkgs = nixosConfiguration.pkgs;
      virtualisation = {
        memorySize = 4096;
        cores = 2;
      };
    };
    client = {
      nixpkgs.pkgs = pkgs;
      environment.systemPackages = [ pkgs.curl ];
    };
  };

  testScript = ''
    start_all()

    with subtest("SSH offers public-key authentication only"):
        home_server.wait_for_unit("sshd.service")
        for user in ["ahmed", "root"]:
            out = client.fail(
                f"ssh -o BatchMode=yes -o StrictHostKeyChecking=no {user}@home-server true 2>&1"
            )
            assert "Permission denied (publickey)." in out, out

    with subtest("Jellyfin answers on the LAN"):
        # Starting at all proves the media bind mounts resolved (a missing source fails the unit).
        home_server.wait_for_unit("jellyfin.service")
        client.wait_until_succeeds(
            "curl -sf http://home-server:8096/health | grep -qx Healthy", timeout=300
        )

    with subtest("nix-daemon starts without the binary cache secret"):
        home_server.succeed("systemctl start nix-daemon.service")

    with subtest("GDM shows the login screen"):
        home_server.wait_for_unit("display-manager.service")
        home_server.wait_until_succeeds("pgrep -u gdm gnome-shell", timeout=300)
        home_server.sleep(10)
        home_server.screenshot("gdm")
  '';
}
