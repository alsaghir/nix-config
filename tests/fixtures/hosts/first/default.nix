{
  nixConfig.services.jellyfin = {
    enable = true;
    mediaDirs.movies = "/srv/movies";
  };
  system.stateVersion = "25.05";
}
