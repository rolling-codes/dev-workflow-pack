#!/bin/sh
# Static validation for the dev-workflow-pack plugin. Run before every release
# (release-prep should call this). Catches the class of bug that's easy to
# introduce by hand: a skill added without a routing-table entry, a config
# file that doesn't parse, a hook script with broken syntax.
#
# This is a static check only — it does not exercise skill triggering or
# hook firing inside an actual Claude Code session. Passing this script means
# "the files are internally consistent," not "this has been run end to end."

set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FAILFILE=$(mktemp)
trap 'rm -f "$FAILFILE"' EXIT

fail() { echo "FAIL: $1" >&2; echo x >> "$FAILFILE"; }
ok()   { echo "ok:   $1"; }

# 1. Every skills/<dir>/SKILL.md exists and its frontmatter name: matches the dir name.
for dir in "$ROOT"/skills/*/; do
  name=$(basename "$dir")
  skill_file="$dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    fail "skills/$name has no SKILL.md"
    continue
  fi
  fm_name=$(awk -F': *' '/^name:/{print $2; exit}' "$skill_file" | tr -d '\r')
  if [ "$fm_name" != "$name" ]; then
    fail "skills/$name/SKILL.md frontmatter name '$fm_name' does not match directory name"
  else
    ok "skills/$name frontmatter matches directory"
  fi
done

# 2. Every skill except dev-workflow itself must be mentioned in dev-workflow's
#    SKILL.md (the routing table). Catches "added a skill, forgot to route to it."
ROUTER="$ROOT/skills/dev-workflow/SKILL.md"
if [ -f "$ROUTER" ]; then
  for dir in "$ROOT"/skills/*/; do
    name=$(basename "$dir")
    [ "$name" = "dev-workflow" ] && continue
    if ! grep -q "$name" "$ROUTER"; then
      fail "skill '$name' is not referenced anywhere in dev-workflow/SKILL.md — routing table is missing an entry"
    else
      ok "skill '$name' is referenced in the router"
    fi
  done
else
  fail "dev-workflow/SKILL.md not found — cannot check routing table coverage"
fi

# 3. All JSON files parse.
JSON_TOOL="python3"
command -v "$JSON_TOOL" >/dev/null 2>&1 || JSON_TOOL=""
find "$ROOT" -name "*.json" -not -path "*/node_modules/*" | while read -r f; do
  if [ -n "$JSON_TOOL" ]; then
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" >/dev/null 2>&1; then
      echo "FAIL: $f is not valid JSON" >&2
      echo x >> "$FAILFILE"
    fi
  elif command -v jq >/dev/null 2>&1; then
    jq -e . "$f" >/dev/null 2>&1 || { echo "FAIL: $f is not valid JSON" >&2; echo x >> "$FAILFILE"; }
  fi
done

# 4. All shell scripts parse (sh -n).
find "$ROOT" -name "*.sh" | while read -r f; do
  if ! sh -n "$f" 2>/dev/null; then
    echo "FAIL: $f has a shell syntax error" >&2
    echo x >> "$FAILFILE"
  fi
done

# 5. hooks.json references scripts that actually exist.
HOOKS_JSON="$ROOT/hooks/hooks.json"
if [ -f "$HOOKS_JSON" ]; then
  grep -o 'hooks/scripts/[a-zA-Z0-9_.-]*\.sh' "$HOOKS_JSON" | sort -u | while read -r rel; do
    if [ ! -f "$ROOT/$rel" ]; then
      echo "FAIL: hooks.json references $rel which does not exist" >&2
      echo x >> "$FAILFILE"
    fi
  done
fi

if [ -s "$FAILFILE" ]; then
  echo "" >&2
  echo "Validation failed. This checks internal consistency only — passing" >&2
  echo "this does not mean the pack has been exercised in a live Claude Code" >&2
  echo "session. Manual smoke-test each new/changed skill before release." >&2
  exit 1
fi

echo ""
echo "All static checks passed. Reminder: this is a consistency check, not an"
echo "end-to-end test — skill triggering and hook firing still need manual"
echo "verification in an actual Claude Code session before release."
exit 0
