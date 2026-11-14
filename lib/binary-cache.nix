# The Backblaze B2 binary cache: hosts read it (nixos/core/binary-cache.nix), `nix run .#ci`
# writes it (ci/default.nix).
rec {
  bucket = "nixosstorage";
  endpoint = "s3.us-east-005.backblazeb2.com";
  region = "us-east-005";
  url = "s3://${bucket}?endpoint=${endpoint}&region=${region}";
  # Public half of the signing key (private half: .github/secrets.yaml cache_signing_key).
  publicKey = "nixosstorage-1:G6XSw2yUEHJScdABPIm0DGXwLmKLpVOrr1G/KbOlkMQ=";
}
