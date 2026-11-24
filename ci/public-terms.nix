# `nix run .#public-terms [-- <rev> | --stdin]`: fail if a denylisted term appears in this
# public repository: file contents and paths of <rev> (default: the working tree, untracked
# files included), or the text on stdin (commit messages); whole words, case-insensitive. sops-encrypted files are skipped (random
# ciphertext). The denylist is itself private: one term per line in the `terms` key of
# ci/public-terms.yaml (sops; recipients in .sops.yaml). Run by `ci` and by .githooks/pre-push.
{
  writeShellApplication,
  git,
  gnugrep,
  gnused,
  sops,
}:
writeShellApplication {
  name = "public-terms";
  runtimeInputs = [
    git
    gnugrep
    gnused
    sops
  ];
  text = ''
    rev=''${1:-}
    cd "$(git rev-parse --show-toplevel)"

    terms=$(mktemp)
    trap 'rm -f "$terms"' EXIT
    sops decrypt --extract '["terms"]' ci/public-terms.yaml | sed '/^[[:space:]]*$/d' >"$terms"
    [ -s "$terms" ] || { echo "public-terms: empty denylist" >&2; exit 1; }

    # grep status: 0 = match, 1 = none, other = error (abort rather than report clean).
    found=0
    check() {
      local status=0
      "$@" || status=$?
      case $status in
        0) found=1 ;;
        1) ;;
        *) exit "$status" ;;
      esac
    }

    if [ "$rev" = --stdin ]; then
      check grep -i -w -F -f "$terms"
    else
      if [ -n "$rev" ]; then
        opts=()
        revs=("$rev")
        all_paths=$(git ls-tree -r --name-only "$rev")
      else
        opts=(--untracked)
        revs=()
        all_paths=$(git ls-files --cached --others --exclude-standard)
      fi

      excludes=()
      sops_files=$(git grep "''${opts[@]}" -l -E '^sops:' "''${revs[@]}" -- '*.yaml' '*.yml' '*.json' || [ $? = 1 ])
      while IFS= read -r f; do
        [ -n "$f" ] && excludes+=(":(exclude)''${f#"$rev:"}")
      done <<<"$sops_files"

      check git grep "''${opts[@]}" -n -I -i -w -F -f "$terms" "''${revs[@]}" -- . "''${excludes[@]}"
      check grep -i -w -F -f "$terms" <<<"$all_paths"
    fi

    if [ "$found" = 1 ]; then
      echo "public-terms: denylisted terms above" >&2
      exit 1
    fi
    echo "public-terms: clean"
  '';
}
