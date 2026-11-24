# Every NixOS host: NetworkManager, DNS (resolved, DNSSEC), mDNS (avahi).
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
}
