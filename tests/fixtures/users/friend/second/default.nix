{ hostname, ... }:
{
  nixConfig.theme = "dark";
  home.homeDirectory = "/srv/friend";
  home.sessionVariables.PROFILE_HOST = hostname;
}
