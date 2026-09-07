#!/usr/bin/env sh
# init.sh - scaffold a context repo wired for agent-memory-kit.
#
# Installs the slash commands, the curator prompts, a starter context tree,
# and git-inits the memory dir (the load-bearing step you don't want to forget).
# Idempotent: existing files are left alone unless you pass --force.
#
# Usage:
#   ./init.sh [--path DIR] [--memory-dir DIR] [--commands global|local]
#             [--force] [--help]
#
#   --path DIR         Where to scaffold the context (default: current dir).
#   --memory-dir DIR   Where the memory repo lives (default: <path>/memory).
#                      Point this at Claude Code's per-project store if you
#                      prefer that over an in-repo memory dir.
#   --commands local   Install commands to <path>/.claude/commands (default).
#   --commands global  Install commands to ~/.claude/commands instead.
#   --force            Overwrite existing scaffold files.
#
# POSIX sh. Works on macOS, Linux, and Git Bash on Windows.

set -eu

# --- resolve the kit's own location, so copies work from anywhere ----------
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# --- defaults --------------------------------------------------------------
TARGET="."
MEMORY_DIR=""
COMMANDS_SCOPE="local"
FORCE=0

# --- args ------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --path)        TARGET="$2"; shift 2 ;;
    --memory-dir)  MEMORY_DIR="$2"; shift 2 ;;
    --commands)    COMMANDS_SCOPE="$2"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    --help|-h)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "init.sh: unknown argument '$1' (try --help)" >&2
      exit 2 ;;
  esac
done

mkdir -p "$TARGET"
TARGET=$(CDPATH= cd -- "$TARGET" && pwd)
[ -n "$MEMORY_DIR" ] || MEMORY_DIR="$TARGET/memory"

echo "agent-memory-kit: scaffolding into $TARGET"

# --- helper: copy a file only if missing (or --force) ----------------------
place() {
  src="$1"; dst="$2"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
    echo "  skip (exists): ${dst#$TARGET/}"
  else
    mkdir -p "$(dirname -- "$dst")"
    cp "$src" "$dst"
    echo "  wrote: ${dst#$TARGET/}"
  fi
}

# --- 1. context scaffold ---------------------------------------------------
place "$SCRIPT_DIR/context-starter/CONTEXT.md"       "$TARGET/CONTEXT.md"
place "$SCRIPT_DIR/context-starter/state/current.md" "$TARGET/state/current.md"
mkdir -p "$TARGET/sessions"
[ -e "$TARGET/sessions/.gitkeep" ] || : > "$TARGET/sessions/.gitkeep"

# --- 2. commands -----------------------------------------------------------
if [ "$COMMANDS_SCOPE" = "global" ]; then
  CMD_DIR="$HOME/.claude/commands"
else
  CMD_DIR="$TARGET/.claude/commands"
fi
mkdir -p "$CMD_DIR"
for c in start end update dream dream-apply; do
  place "$SCRIPT_DIR/commands/$c.md" "$CMD_DIR/$c.md"
done
echo "  commands installed to: $CMD_DIR"

# --- 3. curator prompts (read by /dream relative to cwd) -------------------
for p in rot lint; do
  place "$SCRIPT_DIR/prompts/$p.md" "$TARGET/prompts/$p.md"
done

# --- 4. memory dir: scaffold + git init (local-only) -----------------------
mkdir -p "$MEMORY_DIR"
place "$SCRIPT_DIR/context-starter/memory/MEMORY.md" "$MEMORY_DIR/MEMORY.md"

# ARCHIVE.md is generated, not copied, so it can't go through place(). Mirror
# place()'s idempotency: skip if it exists (unless --force), and always print.
ARCHIVE_DST="$MEMORY_DIR/ARCHIVE.md"
if [ -e "$ARCHIVE_DST" ] && [ "$FORCE" -eq 0 ]; then
  echo "  skip (exists): ${ARCHIVE_DST#$TARGET/}"
else
  printf '# Archive\n\nTombstone rows for retired memories. The files themselves live in `archive/`,\neach stamped `archived: YYYY-MM-DD`. A row on its own is not an archive — without\nthe stamp and the move, the file stays in the memory root and reads as live.\n\n| date | memory | reason |\n|---|---|---|\n' > "$ARCHIVE_DST"
  echo "  wrote: ${ARCHIVE_DST#$TARGET/}"
fi

# archive/ must exist before the first retirement: `git mv x.md archive/x.md`
# does NOT create it and dies at exit 128 mid-procedure. .gitkeep because git
# does not track empty directories, and the seed commit below would drop it.
mkdir -p "$MEMORY_DIR/archive"
if [ -e "$MEMORY_DIR/archive/.gitkeep" ]; then
  echo "  skip (exists): ${MEMORY_DIR#$TARGET/}/archive/.gitkeep"
else
  : > "$MEMORY_DIR/archive/.gitkeep"
  echo "  wrote: ${MEMORY_DIR#$TARGET/}/archive/.gitkeep"
fi

memory_repo_prefix() {
  ( cd "$MEMORY_DIR" && git rev-parse --show-prefix 2>/dev/null ) || return 1
}

REPO_PREFIX=$(memory_repo_prefix || printf '__not_a_repo__')
if [ -z "$REPO_PREFIX" ]; then
  if ( cd "$MEMORY_DIR" && git rev-parse --verify HEAD >/dev/null 2>&1 ); then
    echo "  memory git: already a repo (left alone)"
  else
    echo "init.sh: memory git repository exists but has no seed commit" >&2
    echo "         Review its staged files and create the initial commit manually." >&2
    exit 1
  fi
else
  # A surrounding context repository does not make memory/ its own repository.
  # Stage only files owned by this installer: pre-existing user files and any
  # unrelated staged paths must never leak into the seed commit.
  if [ -e "$MEMORY_DIR/.git" ] || [ -L "$MEMORY_DIR/.git" ]; then
    echo "init.sh: $MEMORY_DIR/.git exists but is not a usable repository" >&2
    echo "         Fix or remove it, then rerun init.sh." >&2
    exit 1
  fi
  ( cd "$MEMORY_DIR" && git init -q ) || {
    echo "init.sh: could not initialize the memory repository" >&2
    exit 1
  }
  (
    cd "$MEMORY_DIR"
    git add -- MEMORY.md ARCHIVE.md archive/.gitkeep
    git commit -q -m "seed memory" -- MEMORY.md ARCHIVE.md archive/.gitkeep
  ) || {
    echo "init.sh: memory repo was initialized, but the seed commit failed" >&2
    echo "         The repository and staged scaffold were preserved for review." >&2
    echo "         Fix the reported git error and create the seed commit manually." >&2
    exit 1
  }
  echo "  memory git: initialized + seeded (local-only, no remote)"
fi

# guard: memory holds durable, possibly-private facts. Keep it local.
if ( cd "$MEMORY_DIR" && git remote 2>/dev/null | grep -q . ); then
  echo "  WARNING: memory repo has a remote configured." >&2
  echo "           If this memory is private, remove it: git -C '$MEMORY_DIR' remote remove <name>" >&2
fi

# --- next steps ------------------------------------------------------------
cat <<EOF

Done. Next:
  1. Fill in CONTEXT.md (who you are + routing) and state/current.md.
  2. If memory lives outside this repo, export AGENT_MEMORY_DIR=$MEMORY_DIR
  3. Open your agent here and run /start. Close with /end. Curate with /dream.

Try it now: run /dream against the seeded memory to see an empty-but-valid pass.

Memory dir: $MEMORY_DIR  (keep it local if it holds anything private)
EOF
