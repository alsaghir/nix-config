# Every NixOS host: NetworkManager, DNS (resolved, DNSSEC), mDNS (avahi), GitHub host key.
{
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
  # DHCP on every interface (nixos-generate-config's default).
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

  # GitHub's published host key (docs.github.com: "GitHub's SSH key fingerprints"), so a
  # first SSH connection to github.com never stops at a host-key prompt.
  programs.ssh.knownHosts.github = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };
}
