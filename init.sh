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
  printf '# Archive\n\nSuperseded memories. Kept for history, not loaded each session.\n\n| date | memory | reason |\n|---|---|---|\n' > "$ARCHIVE_DST"
  echo "  wrote: ${ARCHIVE_DST#$TARGET/}"
fi

if [ -d "$MEMORY_DIR/.git" ]; then
  echo "  memory git: already a repo (left alone)"
else
  ( cd "$MEMORY_DIR" && git init -q && git add -A >/dev/null 2>&1 \
    && git commit -q -m "seed memory" >/dev/null 2>&1 || true )
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
