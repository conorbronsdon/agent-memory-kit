#!/usr/bin/env sh
# Supply-chain guard for GitHub Actions. Run: sh tests/workflow_pins_test.sh
# Every third-party `uses:` under .github/workflows and .github/actions is pinned to
# a full 40-character commit SHA (tag in a trailing comment), every workflow sets
# top-level `permissions:`, and Dependabot watches github-actions.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "not ok - $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "$3 (got '$1', want '$2')"; }

# Reads YAML on stdin; prints every `uses:` ref that is not a full-SHA pin,
# a local ./ action or a docker:// image.
unpinned_uses() {
  tr -d '\r' \
    | sed -n -E "s/^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[\"']?([^[:space:]\"'#]+).*/\\2/p" \
    | grep -Ev '^(\./|docker://)' \
    | grep -Ev '@[0-9a-f]{40}$' || true
}

NL='
'
GOT=$(printf '%s\n' \
  '      - uses: actions/checkout@v4' \
  '      - uses: actions/setup-node@49933ea' \
  "        uses: 'owner/action@main'" | unpinned_uses)
assert_eq "$GOT" "actions/checkout@v4${NL}actions/setup-node@49933ea${NL}owner/action@main" "parser missed a tag, short SHA or branch ref"
echo "ok - parser flags a tag, a short SHA and a branch ref"

GOT=$(printf '%s\n' \
  '      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0' \
  '        uses: ./' \
  '        uses: ./.github/actions/setup' \
  '        uses: docker://alpine:3.20' \
  '      # uses: actions/checkout@v4 (a comment, not a step)' | unpinned_uses)
assert_eq "$GOT" "" "parser flagged a full SHA, local action, docker image or comment"
echo "ok - parser accepts a full SHA pin, local actions and docker images"

FILES=$(find "$ROOT/.github/workflows" "$ROOT/.github/actions" -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort)
[ -n "$FILES" ] || fail "no workflow files found under .github/"
BAD=""
for f in $FILES; do
  refs=$(unpinned_uses <"$f")
  [ -z "$refs" ] || BAD="$BAD${f#"$ROOT"/}: $refs$NL"
done
[ -z "$BAD" ] || fail "pin these to a full commit SHA with a version comment:$NL$BAD"
echo "ok - every uses: is pinned to a full commit SHA"

for f in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
  [ -f "$f" ] || continue
  grep -q '^permissions:' "$f" || fail "${f#"$ROOT"/} has no top-level permissions:"
done
echo "ok - every workflow sets top-level permissions"

test -f "$ROOT/.github/dependabot.yml" || fail ".github/dependabot.yml is missing"
grep -Eq "package-ecosystem:[[:space:]]*[\"']?github-actions" "$ROOT/.github/dependabot.yml" || fail "dependabot does not watch github-actions"
echo "ok - dependabot watches github-actions"
