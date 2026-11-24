# TLS trust for interactive tools behind a TLS-intercepting network or for local CAs.
#
# The bundle is layered: an immutable Nix-built base (nixpkgs' public roots plus
# `extraCertificateFiles`) and, on top, `runtimeCertificateFiles`: mutable PEM files outside
# the store (e.g. a CA a local cluster generates at install time). Every TLS variable
# points at the derived file, rewritten whole on activation and by `ca-bundle-rebuild`
# (run it after changing a runtime file), so it always exists and is never half-written.
#
# Nix build sandboxes use nixpkgs' `cacert`, not this bundle; for fetchers use the
# flake's `lib.mkFetcherCaOverlay`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.certs;

  # Interpolated, not toString'ed, so the PEM files are copied into the store.
  baseBundle = pkgs.runCommand "ca-bundle.crt" { } ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${
      lib.concatMapStringsSep " " (f: "${f}") cfg.extraCertificateFiles
    } > $out
  '';

  rebuild = pkgs.writeShellApplication {
    name = "ca-bundle-rebuild";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      bundle=${lib.escapeShellArg cfg.bundlePath}
      mkdir -p "$(dirname "$bundle")"
      tmp="$(mktemp "$bundle.XXXXXX")"
      cat ${baseBundle} > "$tmp"
      runtime=(${lib.escapeShellArgs cfg.runtimeCertificateFiles})
      for f in "''${runtime[@]}"; do
        if [ -s "$f" ]; then cat "$f" >> "$tmp"; fi
      done
      chmod 0644 "$tmp"
      mv -f "$tmp" "$bundle"
    '';
  };
in
{
  options.nixConfig.certs = {
    enable = lib.mkEnableOption "a user CA bundle behind SSL_CERT_FILE and the other TLS variables";

    extraCertificateFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "PEM files added to the base bundle at build time.";
    };

    runtimeCertificateFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/home/alice/.config/cluster/ca.pem" ];
      description = "Absolute paths of mutable PEM files appended by `ca-bundle-rebuild` when present.";
    };

    bundlePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/ca-bundle.pem";
      defaultText = lib.literalExpression ''"''${config.xdg.stateHome}/ca-bundle.pem"'';
      description = "The derived bundle every TLS variable points at.";
    };

    rebuildPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = rebuild;
      description = "`ca-bundle-rebuild`, for scripts that update a runtime certificate file.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ rebuild ];

    home.sessionVariables = lib.genAttrs [
      "SSL_CERT_FILE"
      "NIX_SSL_CERT_FILE"
      "CURL_CA_BUNDLE"
      "GIT_SSL_CAINFO"
      "REQUESTS_CA_BUNDLE"
      "NODE_EXTRA_CA_CERTS"
    ] (_: cfg.bundlePath);

    home.activation.caBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe rebuild}
    '';
  };
}
