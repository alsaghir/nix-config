# Reusable kernel specializations for gaming/performance testing.
# Provides multiple kernel options at boot time.
{ lib, pkgs, ... }:

{
  specialisation = {
    kernel-66.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
    };
    
    kernel-zen.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    };
    
    kernel-lqx.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_lqx;
    };
    
    kernel-xanmod-stable.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod_stable;
    };
    
    kernel-xanmod-latest.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod_latest;
    };
  };
}