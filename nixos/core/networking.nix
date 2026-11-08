{
  config,
  pkgs,
  lib,
  ...
}:
{
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "false";
      DNSSEC = "true";
      Domains = [ "~." ];
      FallbackDNS = [
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
  };
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings = {
      publish = {
        disable-publishing = false;
        publish-addresses = true;
      };
    };

  };
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  # GitHub's published host key (docs.github.com: "GitHub's SSH key fingerprints"), so the
  # first git+ssh flake fetch (private ai-rules input) never stops at a host-key prompt.
  programs.ssh.knownHosts.github = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
