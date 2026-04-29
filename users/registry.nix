# Central registry for all users across all hosts.
# This is the single source of truth for user definitions.
{
  # User definitions - each user has a unique identifier
  users = {
    ahmed = {
      username = "ahmed";
      fullName = "Ahmed";
      homeDirectory = "/home/ahmed";
      shell = "zsh";
      extraGroups = [
        "networkmanager"
        "wheel"
        "i2c"
        "video"
        "render"
        "input"
        "podman"
      ];

      preferences = {
        theme = "dark"; # "dark" or "light"
      };

    };

    nixos = {
    username = "nixos";
    fullName = "NixOS";
    homeDirectory = "/home/nixos";
    shell = "zsh";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  };

  # Per-host primary user assignments
  # This determines which user is the "main" user on each host
  hosts = {
    asus-laptop = {
      system = "x86_64-linux";
      primaryUser = "ahmed";
      # per user@host pluggable HM modules on top of users/<name>/home.nix
      userModules = {
        ahmed = [
          # host-specific additions for ahmed on this machine
          # e.g. ../../home/profiles/gaming.nix
        ];
      };
    };

    wsl-lenovo-laptop = {
    system = "x86_64-linux";
    primaryUser = "nixos";
    userModules = {
      nixos = [ ];
    };
  };
    # desktop = {
    #   system      = "x86_64-linux";
    #   primaryUser = "john";
    #   userModules = {
    #     john = [];
    #   };
    # };
  };
}
