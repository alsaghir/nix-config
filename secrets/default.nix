{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:
let

  userLib = import ../lib { inherit lib; };
  hostname = config.networking.hostName;
  primaryUsername = userLib.getPrimaryUser hostname;
  userConfig = userLib.getPrimaryUserConfig hostname;

  sshKeysSopsFile = ../users/${userConfig.username}/${hostname}/ssh-keys.yaml;
  aiApiKeysSopsFile = ../users/${userConfig.username}/ai-keys.yaml;

in
{

  

}
