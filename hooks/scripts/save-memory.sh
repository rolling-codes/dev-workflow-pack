#!/bin/sh
# PreCompact hook. Fires before manual /compact and before auto-compaction.
# Writes a mechanical snapshot to .claude/memory-auto.json so the
# SessionStart compact hook can reload it after compaction finishes.
# Must exit 0 no matter what: a memory hook should never block compaction.

set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

mkdir -p "$ROOT/.claude" 2>/dev/null || exit 0
OUT="$ROOT/.claude/memory-auto.json"

# Pull the trigger field (manual or auto) from the stdin JSON without
# requiring jq. Falls back to unknown if the field is absent.
INPUT=$(cat 2>/dev/null || true)
TRIGGER=$(printf '%s' "$INPUT" | tr -d ' "' | grep -o 'trigger:[a-z]*' | cut -d: -f2)
[ -n "${TRIGGER:-}" ] || TRIGGER="unknown"

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
STAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

# Last five commits, one per line, escaped for JSON.
COMMITS=$(git log -5 --oneline --no-merges 2>/dev/null \
  | sed 's/\\/\\\\/g; s/"/\\"/g' \
  | awk '{printf "%s\"%s\"", sep, $0; sep=","}')
[ -n "$COMMITS" ] || COMMITS='"no commits"'

cat > "$OUT" << EOF
{
  "written_by": "dev-workflow-pack PreCompact hook",
  "compaction_trigger": "$TRIGGER",
  "saved_at": "$STAMP",
  "branch": "$BRANCH",
  "uncommitted_files": $DIRTY,
  "recent_commits": [$COMMITS],
  "note": "Mechanical snapshot only. Narrative state (decisions, open work, session summary) lives in .claude/memory.json, written by the dev-workflow skill."
}
EOF

exit 0
