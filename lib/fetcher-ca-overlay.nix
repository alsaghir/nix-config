# Overlay adding CA certificates to Nix's fetchers only (fetchurl, fetchgit and everything
# built on them, plus buildGoModule's fixed-output `goModules` download), for hosts behind a
# TLS-intercepting network.
#
# Not a global `cacert` override: cacert is an input of curl, git, python and many more,
# so overriding it changes their hashes and they fall out of the binary cache. Fetcher
# outputs are fixed-output, so this overlay changes no output path.
certFiles: _final: prev:
let
  cacert = prev.cacert.override { extraCertificateFiles = certFiles; };
in
{
  fetchurl = prev.fetchurl.override { inherit cacert; };
  fetchgit = prev.fetchgit.override { inherit cacert; };
  # cacert is used only by the goModules derivation, so built Go packages keep their paths.
  buildGoModule = prev.buildGoModule.override { inherit cacert; };
}
