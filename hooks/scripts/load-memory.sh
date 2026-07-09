#!/bin/sh
# SessionStart hook. Stdout is added to Claude's context on startup, resume,
# and after compaction. Emits a short digest plus a pointer, not the full
# files, so the recurring per-session context cost stays near zero.

set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
MANUAL="$ROOT/.claude/memory.json"
AUTO="$ROOT/.claude/memory-auto.json"
ARCH="$ROOT/.claude/architecture.json"

[ -f "$MANUAL" ] || [ -f "$AUTO" ] || [ -f "$ARCH" ] || exit 0

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "dev-workflow-pack memory digest. Branch: $BRANCH. Uncommitted changes: $DIRTY files."

if [ -f "$MANUAL" ]; then
  # Pull just the one-paragraph session summary. The schema keeps it on one line.
  SUMMARY=$(grep -o '"session_summary"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANUAL" \
    | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')
  if [ -n "${SUMMARY:-}" ]; then
    echo "Last session: $SUMMARY"
  else
    # Malformed or nonstandard file: fall back to a small bounded excerpt.
    head -5 "$MANUAL"
  fi
fi

if [ -f "$AUTO" ]; then
  SAVED=$(grep -o '"saved_at"[[:space:]]*:[[:space:]]*"[^"]*"' "$AUTO" \
    | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  echo "Auto snapshot from last compaction saved at ${SAVED:-unknown time}."
fi

if [ -f "$ARCH" ]; then
  echo "Architecture map available at .claude/architecture.json (not injected — read it only if the task needs the component/dependency layout)."
fi

echo "Full memory lives in .claude/memory.json and .claude/memory-auto.json. Read them only if this digest is not enough for the current task."
exit 0
