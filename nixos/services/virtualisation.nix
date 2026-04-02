{ pkgs, ... }:
{
  # systemd.services."user@".serviceConfig.Delegate = "yes";
  virtualisation = {
    containers.enable = false;
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
      enable = false;
      dockerSocket.enable = false;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = false; # Required for containers under podman-compose to be able to talk to each other.
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

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    32997 # BiglyBT DLNA
    40275 # BiglyBT DLNA Content
  ];
  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    1900 # BiglyBT DLNA
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--debug" # Optionally add additional args to k3s
     "--write-kubeconfig-mode=644"
  ];

}
