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
# cache.nixos.org. Re-running resumes: paths already in the bucket are skipped.
{
  writeShellApplication,
  coreutils,
  curl,
  findutils,
  git,
  gnused,
  jq,
  rclone,
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
    curl
    findutils
    git
    gnused
    jq
    rclone
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

    # Command substitutions (not <(...)) so a failing command aborts the script.
    closure=$(xargs nix path-info --recursive --json --json-format 1 <<<"$outputs")
    mapfile -t candidates < <(jq -r 'to_entries[] | select(.value.ca == null) | .key' <<<"$closure")
    # One narinfo lookup per path, 32 in parallel (`nix path-info --store` asks one at a
    # time); 200 = upstream has it, 404 = upload it, anything else aborts.
    # shellcheck disable=SC2016 # $1 etc. belong to the inner sh
    missing=$(printf '%s\n' "''${candidates[@]}" | xargs -P 32 -n 1 sh -c '
      hash=$(basename "$1" | cut -d- -f1)
      code=$(curl -s -o /dev/null -w "%{http_code}" --retry 3 "https://cache.nixos.org/$hash.narinfo")
      case "$code" in
        200) ;;
        404) echo "$1" ;;
        *) echo "ci: cache.nixos.org answered $code for $1" >&2; exit 255 ;;
      esac' _)
    mapfile -t upload < <(sort <<<"$missing" | sed '/^$/d')
    echo "ci: uploading ''${#upload[@]} of ''${#candidates[@]} closure paths (the rest are on cache.nixos.org)"

    if [ "''${#upload[@]}" -gt 0 ]; then
      secrets=$(sops decrypt --output-type json .github/secrets.yaml)
      work=$(umask 077 && mktemp -d)
      trap 'rm -rf "$work"' EXIT
      jq -j .cache_signing_key <<<"$secrets" >"$work/key"
      AWS_ACCESS_KEY_ID=$(jq -r .b2_key_id <<<"$secrets")
      AWS_SECRET_ACCESS_KEY=$(jq -r .b2_application_key <<<"$secrets")
      export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
      export RCLONE_CONFIG_B2_TYPE=s3 RCLONE_CONFIG_B2_PROVIDER=Other \
        RCLONE_CONFIG_B2_ENV_AUTH=true RCLONE_CONFIG_B2_NO_CHECK_BUCKET=true \
        RCLONE_CONFIG_B2_ENDPOINT=${cache.endpoint} RCLONE_CONFIG_B2_REGION=${cache.region}
      bucket=b2:${cache.bucket}

      # Resume: drop paths whose narinfo is already in the bucket.
      have=$(rclone lsf --files-only --include '*.narinfo' "$bucket")
      mapfile -t upload < <(printf '%s\n' "''${upload[@]}" |
        grep -v -F -f <(sed -n 's|^\(.*\)\.narinfo$|/nix/store/\1-|p' <<<"$have") || true)
      echo "ci: ''${#upload[@]} of them are not in the bucket yet"
    fi

    if [ "''${#upload[@]}" -gt 0 ]; then
      # A binary cache only accepts a path whose references it already holds, but the
      # references here mostly live on cache.nixos.org (hosts fetch them from there). So
      # sign into a local cache seeded with stub narinfos for every other closure path,
      # then upload only the real files.
      mkdir "$work/cache"
      # shellcheck disable=SC2016 # $ARGS is jq's
      jq -r '
        ($ARGS.positional | map({(.): true}) | add) as $up
        | to_entries[] | select($up[.key] | not)
        | [(.key | ltrimstr("/nix/store/") | .[0:32]), .key, .value.narHash, .value.narSize]
        | @tsv' --args "''${upload[@]}" <<<"$closure" |
        while IFS=$'\t' read -r hash path narHash narSize; do
          printf 'StorePath: %s\nURL: stub\nNarHash: %s\nNarSize: %s\n' \
            "$path" "$narHash" "$narSize" >"$work/cache/$hash.narinfo"
        done
      nix copy --no-recursive \
        --to "file://$work/cache?compression=zstd&secret-key=$work/key" "''${upload[@]}"

      # NARs before narinfos, so the bucket never advertises a missing NAR. Few parallel
      # transfers: B2 answers bursts with 503 SlowDown.
      rclone copy --ignore-existing --transfers 4 "$work/cache/nar" "$bucket/nar"
      { echo nix-cache-info; for p in "''${upload[@]}"; do
        echo "$(basename "$p" | cut -c1-32).narinfo"; done; } >"$work/files"
      rclone copy --ignore-existing --transfers 4 --files-from "$work/files" \
        "$work/cache" "$bucket"
    fi

    if $update_lock; then
      git push origin HEAD:main
    fi
  '';
}
