{ lib, ... }:
{
  options.nixConfig.theme = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
    default = "dark";
    description = "Desktop color preference, defaulted from the user registry.";
  };
}
