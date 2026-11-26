#!/usr/bin/env sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-memory-kit-init.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
fail() { echo "not ok - $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "$3 (got '$1', want '$2')"; }
git_env() { config=$1; shift; env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$config" "$@"; }
run_init() { fixture=$1; git_env "$fixture/gitconfig" sh "$ROOT/init.sh" --path "$fixture/context"; }
configure_identity() { git config --file "$1/gitconfig" user.name "Test User"; git config --file "$1/gitconfig" user.email "test@local.invalid"; }

mkdir -p "$TMP_ROOT/no-identity"
git config --file "$TMP_ROOT/no-identity/gitconfig" user.useConfigOnly true
if run_init "$TMP_ROOT/no-identity" >"$TMP_ROOT/no-identity/output" 2>"$TMP_ROOT/no-identity/error"; then fail "fresh install succeeded without git identity"; fi
grep -q 'seed commit failed' "$TMP_ROOT/no-identity/error" || fail "missing identity did not report seed failure"
if grep -q 'initialized + seeded' "$TMP_ROOT/no-identity/output"; then fail "missing identity printed seeded success"; fi
test -d "$TMP_ROOT/no-identity/context/memory/.git" || fail "failed seed did not preserve repository metadata"
git_env "$TMP_ROOT/no-identity/gitconfig" git -C "$TMP_ROOT/no-identity/context/memory" rev-parse --verify HEAD >/dev/null 2>&1 && fail "missing identity created a commit"
git_env "$TMP_ROOT/no-identity/gitconfig" git -C "$TMP_ROOT/no-identity/context/memory" diff --cached --quiet -- MEMORY.md && fail "failed seed did not preserve staged scaffold"
echo "ok - missing identity fails without a seeded claim"

if run_init "$TMP_ROOT/no-identity" >"$TMP_ROOT/no-identity/retry-output" 2>"$TMP_ROOT/no-identity/retry-error"; then fail "rerun silently accepted an existing unborn repository"; fi
grep -q 'has no seed commit' "$TMP_ROOT/no-identity/retry-error" || fail "unborn rerun did not report recovery state"
echo "ok - existing unborn repository requires manual recovery"

mkdir -p "$TMP_ROOT/success"; configure_identity "$TMP_ROOT/success"
run_init "$TMP_ROOT/success" >"$TMP_ROOT/success/output"
test "$(git_env "$TMP_ROOT/success/gitconfig" git -C "$TMP_ROOT/success/context/memory" rev-list --count HEAD)" = 1 || fail "configured install did not create one seed commit"
assert_eq "$(git_env "$TMP_ROOT/success/gitconfig" git -C "$TMP_ROOT/success/context/memory" show -s --format=%an HEAD)" "Test User" "seed did not use configured identity"
grep -q 'initialized + seeded' "$TMP_ROOT/success/output" || fail "configured install did not report seeded success"
echo "ok - configured identity seeds successfully"

FIRST=$(git_env "$TMP_ROOT/success/gitconfig" git -C "$TMP_ROOT/success/context/memory" rev-parse HEAD)
run_init "$TMP_ROOT/success" >"$TMP_ROOT/success/rerun-output"
assert_eq "$(git_env "$TMP_ROOT/success/gitconfig" git -C "$TMP_ROOT/success/context/memory" rev-parse HEAD)" "$FIRST" "idempotent rerun changed HEAD"
grep -q 'already a repo (left alone)' "$TMP_ROOT/success/rerun-output" || fail "idempotent rerun did not identify existing repo"
echo "ok - seeded rerun is idempotent"

mkdir -p "$TMP_ROOT/hook/hooks"; configure_identity "$TMP_ROOT/hook"
printf '#!/usr/bin/env sh\nexit 9\n' >"$TMP_ROOT/hook/hooks/pre-commit"; chmod +x "$TMP_ROOT/hook/hooks/pre-commit"
git config --file "$TMP_ROOT/hook/gitconfig" core.hooksPath "$TMP_ROOT/hook/hooks"
if run_init "$TMP_ROOT/hook" >"$TMP_ROOT/hook/output" 2>"$TMP_ROOT/hook/error"; then fail "failing commit hook was masked"; fi
grep -q 'seed commit failed' "$TMP_ROOT/hook/error" || fail "failing hook did not report seed failure"
if grep -q 'initialized + seeded' "$TMP_ROOT/hook/output"; then fail "failing hook printed seeded success"; fi
test -d "$TMP_ROOT/hook/context/memory/.git" || fail "failing hook did not preserve repository metadata"
git_env "$TMP_ROOT/hook/gitconfig" git -C "$TMP_ROOT/hook/context/memory" diff --cached --quiet -- MEMORY.md && fail "failing hook did not preserve staged scaffold"
echo "ok - failing hook reports failure and preserves recovery state"

mkdir -p "$TMP_ROOT/unrelated/context/memory"; configure_identity "$TMP_ROOT/unrelated"
printf 'keep me\n' >"$TMP_ROOT/unrelated/context/memory/user-note.md"; run_init "$TMP_ROOT/unrelated" >/dev/null
if git_env "$TMP_ROOT/unrelated/gitconfig" git -C "$TMP_ROOT/unrelated/context/memory" ls-files --error-unmatch user-note.md >/dev/null 2>&1; then fail "seed captured a user file"; fi
test -f "$TMP_ROOT/unrelated/context/memory/user-note.md" || fail "installer removed a user file"
echo "ok - pre-existing user files are preserved and not committed"

mkdir -p "$TMP_ROOT/staged/context/memory"
git_env "$TMP_ROOT/staged/gitconfig" git -C "$TMP_ROOT/staged/context/memory" init -q
printf 'already staged\n' >"$TMP_ROOT/staged/context/memory/user-staged.md"
git_env "$TMP_ROOT/staged/gitconfig" git -C "$TMP_ROOT/staged/context/memory" add user-staged.md
if run_init "$TMP_ROOT/staged" >"$TMP_ROOT/staged/output" 2>"$TMP_ROOT/staged/error"; then fail "installer accepted an unborn repo"; fi
git_env "$TMP_ROOT/staged/gitconfig" git -C "$TMP_ROOT/staged/context/memory" rev-parse --verify HEAD >/dev/null 2>&1 && fail "installer committed staged content"
git_env "$TMP_ROOT/staged/gitconfig" git -C "$TMP_ROOT/staged/context/memory" diff --cached --quiet -- user-staged.md && fail "installer disturbed staged content"
echo "ok - unrelated staged files stay staged and uncommitted"

mkdir -p "$TMP_ROOT/nested/context"; configure_identity "$TMP_ROOT/nested"
git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context" init -q
printf 'outer\n' >"$TMP_ROOT/nested/context/outer.txt"
git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context" add outer.txt
git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context" commit -q -m outer
OUTER_HEAD=$(git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context" rev-parse HEAD)
run_init "$TMP_ROOT/nested" >"$TMP_ROOT/nested/output"
test -d "$TMP_ROOT/nested/context/memory/.git" || fail "nested memory did not get its own repository"
assert_eq "$(git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context/memory" rev-parse --show-prefix)" "" "memory resolves inside the outer repository"
test "$(git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context/memory" rev-list --count HEAD)" = 1 || fail "nested memory repository was not seeded"
assert_eq "$(git_env "$TMP_ROOT/nested/gitconfig" git -C "$TMP_ROOT/nested/context" rev-parse HEAD)" "$OUTER_HEAD" "installer changed the outer repository HEAD"
echo "ok - memory nested under a context repository gets its own repository"

mkdir -p "$TMP_ROOT/worktree/source"; configure_identity "$TMP_ROOT/worktree"
git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/source" init -q
printf 'base\n' >"$TMP_ROOT/worktree/source/base.txt"
git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/source" add base.txt
git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/source" commit -q -m base
git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/source" worktree add -q "$TMP_ROOT/worktree/context/memory"
WORKTREE_HEAD=$(git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/context/memory" rev-parse HEAD)
run_init "$TMP_ROOT/worktree" >"$TMP_ROOT/worktree/output"
assert_eq "$(git_env "$TMP_ROOT/worktree/gitconfig" git -C "$TMP_ROOT/worktree/context/memory" rev-parse HEAD)" "$WORKTREE_HEAD" "installer committed in worktree"
test -f "$TMP_ROOT/worktree/context/memory/.git" || fail "worktree .git file was replaced"
test ! -e "$TMP_ROOT/worktree/source/.git/hooks/pre-push" || fail "installer wrote pre-push hook into worktree parent repo"
grep -q 'already a repo (left alone)' "$TMP_ROOT/worktree/output" || fail "worktree was not recognized"
echo "ok - .git file worktrees are preserved"

# The README's install step runs ./init.sh directly, so the committed file must
# carry the executable bit; every other test above invokes it via `sh`.
[ -x "$ROOT/init.sh" ] || fail "init.sh is not executable; README's ./init.sh would fail with Permission denied"
mkdir -p "$TMP_ROOT/direct"; configure_identity "$TMP_ROOT/direct"
git_env "$TMP_ROOT/direct/gitconfig" "$ROOT/init.sh" --path "$TMP_ROOT/direct/context" >"$TMP_ROOT/direct/output" || fail "direct ./init.sh invocation failed"
grep -q 'initialized + seeded' "$TMP_ROOT/direct/output" || fail "direct invocation did not seed memory"
echo "ok - init.sh runs directly as the README documents"

# A relative --memory-dir resolves against the invoking directory, and the
# printed AGENT_MEMORY_DIR export must be absolute: the agent reads it from the
# context dir, where a relative value points somewhere else.
mkdir -p "$TMP_ROOT/relmem/run dir"; configure_identity "$TMP_ROOT/relmem"
RELMEM_RUN=$(CDPATH= cd -- "$TMP_ROOT/relmem/run dir" && pwd)
( cd "$RELMEM_RUN" && git_env "$TMP_ROOT/relmem/gitconfig" sh "$ROOT/init.sh" --path "$TMP_ROOT/relmem/my context" --memory-dir mem ) >"$TMP_ROOT/relmem/output"
test -f "$RELMEM_RUN/mem/MEMORY.md" || fail "relative --memory-dir did not resolve against the invoking directory"
assert_eq "$(grep -c 'export AGENT_MEMORY_DIR=' "$TMP_ROOT/relmem/output")" "1" "relative --memory-dir export line count"
assert_eq "$(sed -n 's/^  2\. If memory lives outside this repo, export AGENT_MEMORY_DIR=//p' "$TMP_ROOT/relmem/output")" "$RELMEM_RUN/mem" "relative --memory-dir printed a non-absolute export"
assert_eq "$(sed -n 's/^Memory dir: \(.*\)  (keep it local.*/\1/p' "$TMP_ROOT/relmem/output")" "$RELMEM_RUN/mem" "relative --memory-dir summary path"
echo "ok - relative --memory-dir is printed as an absolute path"

mkdir -p "$TMP_ROOT/absmem"; configure_identity "$TMP_ROOT/absmem"
ABSMEM="$(CDPATH= cd -- "$TMP_ROOT/absmem" && pwd)/memory store"
git_env "$TMP_ROOT/absmem/gitconfig" sh "$ROOT/init.sh" --path "$TMP_ROOT/absmem/context" --memory-dir "$ABSMEM" >"$TMP_ROOT/absmem/output"
assert_eq "$(sed -n 's/^  2\. If memory lives outside this repo, export AGENT_MEMORY_DIR=//p' "$TMP_ROOT/absmem/output")" "$ABSMEM" "absolute --memory-dir export changed"
test "$(git_env "$TMP_ROOT/absmem/gitconfig" git -C "$ABSMEM" rev-list --count HEAD)" = 1 || fail "absolute --memory-dir was not seeded"
echo "ok - absolute --memory-dir is printed unchanged"

mkdir -p "$TMP_ROOT/prepush"; configure_identity "$TMP_ROOT/prepush"
run_init "$TMP_ROOT/prepush" >"$TMP_ROOT/prepush/output"
HOOK="$TMP_ROOT/prepush/context/memory/.git/hooks/pre-push"
test -f "$HOOK" || fail "init.sh did not install memory pre-push hook"
test -x "$HOOK" || fail "memory pre-push hook is not executable"
grep -q 'wrote: memory/.git/hooks/pre-push' "$TMP_ROOT/prepush/output" || fail "init.sh did not report installing pre-push hook"
git_env "$TMP_ROOT/prepush/gitconfig" git init --bare -q "$TMP_ROOT/prepush/remote.git"
git_env "$TMP_ROOT/prepush/gitconfig" git -C "$TMP_ROOT/prepush/context/memory" remote add origin "$TMP_ROOT/prepush/remote.git"
if git_env "$TMP_ROOT/prepush/gitconfig" git -C "$TMP_ROOT/prepush/context/memory" push origin HEAD >"$TMP_ROOT/prepush/push-out" 2>"$TMP_ROOT/prepush/push-err"; then
  fail "git push succeeded despite installed pre-push hook"
fi
grep -q 'refusing to push' "$TMP_ROOT/prepush/push-err" || fail "pre-push hook did not explain refusal"
assert_eq "$(git_env "$TMP_ROOT/prepush/gitconfig" git -C "$TMP_ROOT/prepush/remote.git" for-each-ref)" "" "blocked push updated bare remote"
git_env "$TMP_ROOT/prepush/gitconfig" git -C "$TMP_ROOT/prepush/context/memory" push --no-verify origin HEAD >/dev/null 2>&1 || fail "git push --no-verify did not bypass pre-push hook"
test -n "$(git_env "$TMP_ROOT/prepush/gitconfig" git -C "$TMP_ROOT/prepush/remote.git" for-each-ref)" || fail "bypassed push did not update bare remote"
echo "ok - pre-push hook blocks push to a remote and allows --no-verify"

mkdir -p "$TMP_ROOT/keephook/context/memory"; configure_identity "$TMP_ROOT/keephook"
git_env "$TMP_ROOT/keephook/gitconfig" git -C "$TMP_ROOT/keephook/context/memory" init -q
printf 'seed\n' >"$TMP_ROOT/keephook/context/memory/note.md"
git_env "$TMP_ROOT/keephook/gitconfig" git -C "$TMP_ROOT/keephook/context/memory" add note.md
git_env "$TMP_ROOT/keephook/gitconfig" git -C "$TMP_ROOT/keephook/context/memory" commit -q -m seed
mkdir -p "$TMP_ROOT/keephook/context/memory/.git/hooks"
printf '#!/usr/bin/env sh\n# custom user hook\nexit 0\n' >"$TMP_ROOT/keephook/context/memory/.git/hooks/pre-push"
chmod +x "$TMP_ROOT/keephook/context/memory/.git/hooks/pre-push"
git_env "$TMP_ROOT/keephook/gitconfig" sh "$ROOT/init.sh" --path "$TMP_ROOT/keephook/context" --force >"$TMP_ROOT/keephook/output"
grep -q '# custom user hook' "$TMP_ROOT/keephook/context/memory/.git/hooks/pre-push" || fail "init.sh overwrote a pre-existing pre-push hook"
grep -q 'skip (exists): memory/.git/hooks/pre-push' "$TMP_ROOT/keephook/output" || fail "init.sh did not report skipping existing pre-push hook"
echo "ok - pre-existing user pre-push hook is preserved"
