{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

{
  justfile.recipes = ''
    # User based justfile recipes
    [no-cd]
    idea:
        ${userConfig.homeDirectory}/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea "{{invocation_directory()}}" > /dev/null 2>&1 & disown

    idea-path path:
          ${userConfig.homeDirectory}/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea "{{path}}" > /dev/null 2>&1 & disown

    [no-cd]
    rustrover:
        ${userConfig.homeDirectory}/.local/share/JetBrains/Toolbox/apps/rustrover/bin/rustrover "{{invocation_directory()}}" > /dev/null 2>&1 & disown
  '';
}
