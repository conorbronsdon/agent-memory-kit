#!/usr/bin/env sh
# Supply-chain guard for GitHub Actions. Run: sh tests/workflow_pins_test.sh
# Every third-party `uses:` under .github/workflows and .github/actions is pinned to
# a full 40-character commit SHA with its tag in a trailing `# vX.Y.Z` comment, every workflow sets
# top-level `permissions:` and grants no write scope (no `write-all`, no `<scope>: write`),
# and Dependabot watches github-actions. The write-scope check reads `<scope>: write` on one
# line; a value on the next line or behind a YAML tag or anchor is not caught. The test does not check that a SHA is the commit
# its version comment names; Dependabot maintains that pairing.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "not ok - $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "$3 (got '$1', want '$2')"; }

# Reads YAML on stdin; prints every `uses:` ref that is not exactly
# owner/repo@<40-hex SHA> with a trailing `# vX.Y.Z` comment. Local ./ actions are
# skipped; a docker:// image must be pinned to an @sha256 digest. Pins that only end in a SHA (sha@sha) are flagged.
unpinned_uses() {
  tr -d '\r' \
    | sed -n -E "s/^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[\"']?([^[:space:]\"'#]+)[\"']?[[:space:]]*(#.*)?\$/\\2 \\3/p" \
    | while IFS=' ' read -r ref comment || [ -n "$ref" ]; do
        case $ref in
          ./*) continue ;;
          docker://*)
            printf '%s\n' "$ref" | grep -Eq '@sha256:[0-9a-f]{64}$' || echo "$ref (docker image not pinned to a digest)"
            continue ;;
        esac
        if ! printf '%s\n' "$ref" | grep -Eq '^[^@]+@[0-9a-f]{40}$'; then
          echo "$ref"
        elif ! printf '%s\n' "$comment" | grep -Eq '^#[[:space:]]*v?[0-9]'; then
          echo "$ref (no version comment)"
        fi
      done
}

# Reads YAML on stdin; prints every non-comment line that mentions a `uses:` key in a form
# unpinned_uses does not parse (flow mapping, quoted key, value on the next line), so an
# unparsed form fails the run instead of being skipped. A `uses:` inside other text (for
# example a run: line) is also printed: that fails closed.
unparsed_uses() {
  tr -d '\r' | grep -v -E '^[[:space:]]*#' \
    | grep -E "[\"']?uses[\"']?[[:space:]]*:" \
    | grep -v -E "^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[\"']?[^[:space:]\"'#]+[\"']?[[:space:]]*(#.*)?\$" || true
}

NL='
'
GOT=$(printf '%s\n' \
  '      - uses: actions/checkout@v4' \
  '      - uses: actions/setup-node@49933ea' \
  "        uses: 'owner/action@main'" | unpinned_uses)
assert_eq "$GOT" "actions/checkout@v4${NL}actions/setup-node@49933ea${NL}owner/action@main" "parser missed a tag, short SHA or branch ref"
echo "ok - parser flags a tag, a short SHA and a branch ref"

# A last line with no trailing newline is still read (`read` returns non-zero on it).
GOT=$(printf '%s' '      - uses: actions/setup-node@v4' | unpinned_uses)
assert_eq "$GOT" "actions/setup-node@v4" "parser skipped an unpinned uses: on a last line with no newline"
echo "ok - parser flags an unpinned uses: on a last line with no trailing newline"

SHA=11d5960a326750d5838078e36cf38b85af677262
GOT=$(printf '%s\n' \
  "      - uses: actions/checkout@$SHA" \
  "      - uses: actions/checkout@$SHA@$SHA # v4.4.0" \
  "      - uses: actions/checkout@v1+$SHA # v4.4.0" | unpinned_uses)
assert_eq "$GOT" "actions/checkout@$SHA (no version comment)${NL}actions/checkout@$SHA@$SHA${NL}actions/checkout@v1+$SHA" "parser missed a comment-less pin or a ref that only ends in a SHA"
echo "ok - parser flags a pin with no version comment and refs that only end in a SHA"

GOT=$(printf '%s\n' \
  '      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0' \
  '        uses: ./' \
  '        uses: ./.github/actions/setup' \
  '        uses: docker://alpine@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  '      # uses: actions/checkout@v4 (a comment, not a step)' | unpinned_uses)
assert_eq "$GOT" "" "parser flagged a full SHA, local action, digest-pinned docker image or comment"
echo "ok - parser accepts a full SHA pin, local actions and digest-pinned docker images"

GOT=$(printf '%s\n' '        uses: docker://alpine:3.20' '        uses: docker://alpine' | unpinned_uses)
assert_eq "$GOT" "docker://alpine:3.20 (docker image not pinned to a digest)${NL}docker://alpine (docker image not pinned to a digest)" "parser accepted a docker image by tag"
echo "ok - parser flags a docker image pinned by tag or not at all"

GOT=$(printf '%s\n' \
  '      - { uses: actions/checkout@v4 }' \
  '      - "uses": actions/checkout@v4' \
  '      - uses:' \
  '          actions/checkout@v4' | unparsed_uses)
assert_eq "$GOT" "      - { uses: actions/checkout@v4 }${NL}      - \"uses\": actions/checkout@v4${NL}      - uses:" "missed a flow-mapping, quoted-key or next-line uses:"
echo "ok - forms the parser can't read are flagged, not skipped"

GOT=$(printf '%s\n' \
  '      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0' \
  "        uses: 'owner/action@main'" \
  '      # uses: { a: b } (a comment)' | unparsed_uses)
assert_eq "$GOT" "" "flagged a uses: form the parser reads, or a comment"
echo "ok - forms the parser reads are not flagged as unparsed"

FILES=$(find "$ROOT/.github/workflows" "$ROOT/.github/actions" -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort)
[ -n "$FILES" ] || fail "no workflow files found under .github/"
BAD=""
for f in $FILES; do
  refs=$(unpinned_uses <"$f")
  [ -z "$refs" ] || BAD="$BAD${f#"$ROOT"/}: $refs$NL"
  odd=$(unparsed_uses <"$f")
  [ -z "$odd" ] || BAD="$BAD${f#"$ROOT"/}: unparsed uses: form: $odd$NL"
done
[ -z "$BAD" ] || fail "pin these to a full commit SHA with a version comment:$NL$BAD"
echo "ok - every uses: is pinned to a full commit SHA"

# Reads a workflow on stdin; prints each line that grants a write scope (`write-all`, or
# `<scope>: write` at any level). Comment lines are ignored.
write_grants() {
  tr -d '\r' | grep -v -E '^[[:space:]]*#' \
    | grep -E "(^|[[:space:]:{,])[\"']?write-all|:[[:space:]]*[\"']?write[\"']?[[:space:]]*(#.*)?([,}]|\$)" || true
}

GOT=$(printf '%s
' 'permissions: write-all' | write_grants)
assert_eq "$GOT" "permissions: write-all" "missed a top-level write-all"
GOT=$(printf '%s
' '    permissions:' '      contents: write' | write_grants)
assert_eq "$GOT" "      contents: write" "missed a job-level contents: write"
GOT=$(printf '%s
' 'permissions: { contents: read, packages: write }' | write_grants)
assert_eq "$GOT" "permissions: { contents: read, packages: write }" "missed a write scope in a flow mapping"
echo "ok - write-scope check flags write-all and <scope>: write"

GOT=$(printf '%s
' 'permissions:' '  contents: read' '  # contents: write (a comment)' '      run: echo write' 'permissions: {}' | write_grants)
assert_eq "$GOT" "" "write-scope check flagged read-only permissions, a comment or a run line"
echo "ok - write-scope check accepts read-only permissions"

# Reads a workflow on stdin; succeeds when it has a top-level (unindented) permissions: key.
has_top_permissions() { grep -q '^permissions:'; }

printf '%s\n' 'on: push' 'jobs:' '  t:' '    permissions:' '      contents: read' | has_top_permissions \
  && fail "accepted a workflow whose only permissions: is job-level"
printf '%s\n' 'on: push' '# permissions:' | has_top_permissions && fail "accepted a commented-out permissions:"
printf '%s\n' 'on: push' 'permissions:' '  contents: read' | has_top_permissions || fail "rejected a top-level permissions:"
echo "ok - top-level permissions check flags a missing or job-level-only block"

for f in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
  [ -f "$f" ] || continue
  tr -d '\r' <"$f" | has_top_permissions || fail "${f#"$ROOT"/} has no top-level permissions:"
  grants=$(write_grants <"$f")
  [ -z "$grants" ] || fail "${f#"$ROOT"/} grants a write scope:$NL$grants"
done
echo "ok - every workflow sets top-level permissions and grants no write scope"

test -f "$ROOT/.github/dependabot.yml" || fail ".github/dependabot.yml is missing"
# Reads dependabot.yml on stdin; succeeds when an uncommented update entry watches github-actions.
watches_actions() {
  tr -d '\r' | grep -v -E '^[[:space:]]*#' \
    | grep -Eq "^[[:space:]]*(-[[:space:]]+)?package-ecosystem:[[:space:]]*[\"']?github-actions[\"']?[[:space:]]*(#.*)?\$"
}

printf '%s\n' 'version: 2' 'updates:' '  # - package-ecosystem: github-actions' | watches_actions \
  && fail "accepted a commented-out github-actions entry"
printf '%s\n' 'version: 2' 'updates:' '  - package-ecosystem: npm' | watches_actions && fail "accepted an npm-only config"
printf '%s\n' 'version: 2' 'updates:' '  - package-ecosystem: "github-actions"' | watches_actions \
  || fail "rejected a quoted github-actions entry"
echo "ok - dependabot check flags a commented-out or missing github-actions entry"

watches_actions <"$ROOT/.github/dependabot.yml" || fail "dependabot does not watch github-actions"
echo "ok - dependabot watches github-actions"
