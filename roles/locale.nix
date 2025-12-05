{ config, pkgs, ... }:
{
  i18n.inputMethod.enable = true;
  i18n.inputMethod.type = "ibus";
  time.timeZone = "Africa/Cairo";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  i18n.extraLocales = [
    "en_AG/UTF-8"
    "en_AU.UTF-8/UTF-8"
    "en_BW.UTF-8/UTF-8"
    "en_CA.UTF-8/UTF-8"
    "en_DK.UTF-8/UTF-8"
    "en_GB.UTF-8/UTF-8"
    "en_HK.UTF-8/UTF-8"
    "en_IE.UTF-8/UTF-8"
    "en_IL/UTF-8"
    "en_IN/UTF-8"
    "en_NG/UTF-8"
    "en_NZ.UTF-8/UTF-8"
    "en_PH.UTF-8/UTF-8"
    "en_SC.UTF-8/UTF-8"
    "en_SG.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "en_ZA.UTF-8/UTF-8"
    "en_ZM/UTF-8"
    "en_ZW.UTF-8/UTF-8"
  ];
}
