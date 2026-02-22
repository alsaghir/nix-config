# Central registry for all users across all hosts.
# This is the single source of truth for user definitions.
{
  # User definitions - each user has a unique identifier
  users = {
    ahmed = {
      username = "ahmed";
      fullName = "Ahmed";
      homeDirectory = "/home/ahmed";
      shell = "zsh"; # Preferred shell (can be overridden per-host)
      
      # System groups this user belongs to
      extraGroups = [
        "networkmanager"
        "wheel"
        "i2c"
        "video"
        "render"
        "input"
        "podman"
      ];
      
      # User preferences (can be overridden per-host)
      preferences = {
        theme = "dark"; # "dark" or "light"
      };
      
    };
    
    # Future users can be added here:
    # john = {
    #   username = "john";
    #   fullName = "John Doe";
    #   homeDirectory = "/home/john";
    #   shell = "bash";
    #   extraGroups = [ "wheel" ];
    #   preferences.theme = "light";
    # };
  };
  
  # Per-host primary user assignments
  # This determines which user is the "main" user on each host
  hosts = {
    asus-laptop = "ahmed";
    # Future hosts:
    # desktop = "ahmed";
    # server = "john";
  };
}