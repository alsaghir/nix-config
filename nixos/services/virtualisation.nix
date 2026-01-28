{ pkgs, ... }:
{
  # systemd.services."user@".serviceConfig.Delegate = "yes";
  virtualisation = {
    containers.enable = true;
    containers.registries.search = [
      "docker.io"
      "quay.io"
    ];
    containers.containersConf.settings = {
      containers = {
        cgroup_manager = "systemd";
      };
    };

    podman = {
      enable = true;
      dockerSocket.enable = false;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
    };
  };

}
