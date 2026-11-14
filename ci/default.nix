# The CI pipeline as one command, so it runs the same on GitHub Actions
# (.github/workflows/build.yml) and on any machine with this repo (e.g. during a GitHub
# outage). Run from the repository:
#
#   nix run .#ci                    check + build every host and user@host (nothing uploaded)
#   nix run .#ci -- --push          ... then upload to the binary cache
#   nix run .#ci -- --update-lock   update flake.lock, check, build, upload, then commit the
#                                   lock and push it to main (the weekly job)
#
# Uploads decrypt .github/secrets.yaml with sops (locally: your age key
# ~/.config/sops/age/keys.txt; CI: SOPS_AGE_KEY). The private ai-rules input needs git+ssh
# access (locally: your SSH key; CI: its deploy key).
#
# Upload filter: closure paths that are neither content-addressed (sources and other
# fixed-output downloads; hosts substitute the built package instead) nor on
# cache.nixos.org. Re-running resumes: nix copy skips paths already in the bucket.
{
  writeShellApplication,
  coreutils,
  git,
  jq,
  sops,
}:
let
  cache = import ../lib/binary-cache.nix;
in
writeShellApplication {
  name = "ci";
  # nix and ssh are the caller's (installed Nix, system ssh), not pinned here.
  runtimeInputs = [
    coreutils
    git
    jq
    sops
  ];
  text = ''
    usage() {
      echo "usage: nix run .#ci [-- --push | --update-lock]  (see ci/default.nix)"
    }

    push=false
    update_lock=false
    for arg in "$@"; do
      case "$arg" in
        --push) push=true ;;
        --update-lock) update_lock=true push=true ;;
        -h | --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
      esac
    done

    cd "$(git rev-parse --show-toplevel)"

    if $update_lock; then
      # The lock commit must hold only the lock, and the build must match that commit.
      if [ -n "$(git status --porcelain)" ]; then
        echo "ci: working tree is not clean" >&2
        exit 1
      fi
      nix flake update --commit-lock-file
    fi

    nix flake check

    # Every registry host and user@host; nothing to edit here when one is added.
    targets=()
    for host in $(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]'); do
      targets+=(".#nixosConfigurations.$host.config.system.build.toplevel")
    done
    for home in $(nix eval --json .#homeConfigurations --apply builtins.attrNames | jq -r '.[]'); do
      targets+=(".#homeConfigurations.\"$home\".activationPackage")
    done
    outputs=$(nix build --no-link --print-out-paths "''${targets[@]}")

    $push || exit 0

    # Command substitutions (not <(...)) so a failing nix aborts the script.
    closure=$(xargs nix path-info --recursive --json --json-format 1 <<<"$outputs")
    mapfile -t candidates < <(jq -r 'to_entries[] | select(.value.ca == null) | .key' <<<"$closure")
    # Paths missing upstream are null; stderr lists them as "don't know how to build".
    upstream=$(nix path-info --json --json-format 1 --store https://cache.nixos.org "''${candidates[@]}" 2>/dev/null)
    mapfile -t upload < <(jq -r 'to_entries[] | select(.value == null) | .key' <<<"$upstream")
    echo "ci: uploading ''${#upload[@]} of ''${#candidates[@]} closure paths (the rest are on cache.nixos.org)"

    if [ "''${#upload[@]}" -gt 0 ]; then
      secrets=$(sops decrypt --output-type json .github/secrets.yaml)
      key=$(umask 077 && mktemp)
      trap 'rm -f "$key"' EXIT
      jq -j .cache_signing_key <<<"$secrets" >"$key"
      # Few parallel uploads, patient retries: B2 answers bursts with 503 SlowDown.
      AWS_ACCESS_KEY_ID=$(jq -r .b2_key_id <<<"$secrets") \
      AWS_SECRET_ACCESS_KEY=$(jq -r .b2_application_key <<<"$secrets") \
        nix copy --no-recursive \
          --option http-connections 4 \
          --option download-attempts 10 \
          --to "${cache.url}&compression=zstd&secret-key=$key" \
          "''${upload[@]}"
    fi

    if $update_lock; then
      git push origin HEAD:main
    fi
  '';
}
