#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix gnused

# Exit immediately if a command exits with a non-zero status.
set -e

# The path to the overlay file, relative to this script's location.
OVERLAY_FILE="$(dirname "$0")/default.nix"

echo "Checking for JetBrains Toolbox updates..."

# Fetch the latest product data from JetBrains' API.
PRODUCT_INFO=$(curl -s "https://data.services.jetbrains.com/products?code=TBA&release.type=release")

# Extract the latest build version using jq.
LATEST_BUILD=$(echo "$PRODUCT_INFO" | jq -r '.[0].releases[0].build')
# Extract the download link for the x86_64 Linux version.
DOWNLOAD_URL=$(echo "$PRODUCT_INFO" | jq -r '.[0].releases[0].downloads.linux.link')

# Extract the current version from the overlay file for comparison.
CURRENT_BUILD=$(grep 'version = "' "$OVERLAY_FILE" | sed -E 's/.*"([^"]+)".*/\1/')

echo "-> Latest version available: $LATEST_BUILD"
echo "-> Your current version:     $CURRENT_BUILD"

# If the versions match, there is nothing to do.
if [ "$LATEST_BUILD" == "$CURRENT_BUILD" ]; then
  echo "You are already on the latest version. Exiting."
  exit 0
fi

echo "✅ New version found! Proceeding with update..."

# Use nix-prefetch-url to download the tarball and get its hash.
echo "Fetching hash for $DOWNLOAD_URL"

url=$(nix-instantiate --eval --json -E "with import ./. { system = \"x86_64-linux\"; }; $DOWNLOAD_URL" | jq -r)
if [[ $url == *.tar.gz ]]; then
    unpack="--unpack"
else
    unpack=""
fi

HASH_RAW=$(nix-prefetch-url $unpack "$DOWNLOAD_URL")

# Convert the hash to the SRI format that Nix requires.
HASH_SRI=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$HASH_RAW")

echo "   New version: $LATEST_BUILD"
echo "   New hash:    $HASH_SRI"

# Use 'sed' to replace the version and sha256 lines in the overlay file.
sed -i "s/version = \".*\"/version = \"$LATEST_BUILD\"/" "$OVERLAY_FILE"
sed -i "s|sha256 = \".*\"|sha256 = \"$HASH_SRI\"|" "$OVERLAY_FILE"

echo "✅ Successfully updated '$OVERLAY_FILE'."
echo "   Run 'git diff' to review the changes, then apply with 'nixos-rebuild switch --flake .#laptop'."
