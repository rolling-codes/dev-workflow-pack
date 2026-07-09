#!/bin/sh
# PreToolUse hook on the Bash tool. Blocks git commit and git push while the
# working tree is on a protected branch, turning the dev-workflow skill's
# branch protection rule into a guarantee. Exit 2 blocks the tool call and
# feeds stderr back to Claude; exit 0 lets it run.
# Known tradeoff: matching is a plain text scan of the command, so a command
# that merely mentions "git commit" inside a string can false positive.
#
# Policy is external (hooks/config/branch-policy.json), not hardcoded here.
# This script is a thin executor: hook -> policy layer -> decision.
#
# Fail-safe rule: missing config -> use built-in defaults (expected on a
# fresh install). Present-but-unparseable config -> fail LOUD and block,
# never silently fall back to defaults, since that would mask a config bug
# behind what looks like normal protection.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
POLICY_FILE="${DEV_WORKFLOW_BRANCH_POLICY:-$SCRIPT_DIR/../config/branch-policy.json}"
DEFAULT_PATTERNS="main
master
develop
release/*
hotfix/*"

INPUT=$(cat 2>/dev/null || true)

# Only care about commands that create or publish commits.
printf '%s' "$INPUT" | grep -Eq 'git[[:space:]]+(commit|push)' || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
[ -n "$BRANCH" ] || exit 0

if [ -f "$POLICY_FILE" ]; then
  if command -v jq >/dev/null 2>&1; then
    if ! jq -e . "$POLICY_FILE" >/dev/null 2>&1; then
      echo "Blocked by dev-workflow-pack: $POLICY_FILE exists but is not valid JSON. Fix or remove it — refusing to silently fall back to default branch protection while a broken policy file is present." >&2
      exit 2
    fi
    PATTERNS=$(jq -r '.protected_branches[]?' "$POLICY_FILE" 2>/dev/null)
    if [ -z "$PATTERNS" ] && ! jq -e '.protected_branches' "$POLICY_FILE" >/dev/null 2>&1; then
      echo "Blocked by dev-workflow-pack: $POLICY_FILE is valid JSON but has no 'protected_branches' array. Fix the file — refusing to silently fall back to defaults." >&2
      exit 2
    fi
  else
    # Extract the array body between "protected_branches": [ and the matching ].
    ARRAY_SECTION=$(awk '
      /"protected_branches"/ { f=1 }
      f { print }
      f && /\]/ { exit }
    ' "$POLICY_FILE")

    if [ -z "$ARRAY_SECTION" ]; then
      echo "Blocked by dev-workflow-pack: $POLICY_FILE exists but no 'protected_branches' key could be found (no jq available, fallback parser found nothing). Install jq, fix the file, or remove it to use built-in defaults — refusing to silently fall back while a config file is present but unreadable." >&2
      exit 2
    fi

    PATTERNS=$(printf '%s\n' "$ARRAY_SECTION" | grep -o '"[^"]*"' | sed 's/"//g' | grep -v '^protected_branches$')
    # An empty PATTERNS here is valid if the array body itself is genuinely
    # empty (just "[]" or "[ ]") — that means "protect nothing", not a parse
    # failure. Only treat it as a parse failure if the key was found but the
    # body contains something other than whitespace/brackets we couldn't read.
    if [ -z "$PATTERNS" ]; then
      BODY_STRIPPED=$(printf '%s\n' "$ARRAY_SECTION" | tr -d ' \t\n' | sed 's/.*\[//; s/\].*//')
      if [ -n "$BODY_STRIPPED" ]; then
        echo "Blocked by dev-workflow-pack: $POLICY_FILE's protected_branches array could not be parsed (no jq available, fallback parser found unrecognized content). Install jq or fix the file — refusing to silently fall back while a config file is present but unreadable." >&2
        exit 2
      fi
      # Genuinely empty array: intentional "protect nothing" config.
    fi
  fi
else
  # No policy file at all: expected pre-setup state, use built-in defaults quietly.
  PATTERNS="$DEFAULT_PATTERNS"
fi

MATCHED=""
OLD_IFS=$IFS
IFS='
'
for PATTERN in $PATTERNS; do
  case "$BRANCH" in
    $PATTERN)
      MATCHED="$PATTERN"
      break
      ;;
  esac
done
IFS=$OLD_IFS

if [ -n "$MATCHED" ]; then
  echo "Blocked by dev-workflow-pack: you are on protected branch '$BRANCH' (matches policy pattern '$MATCHED'). Create a feature branch first (git checkout -b feat/short-name), then commit and open a PR. To change policy, edit $POLICY_FILE — not this script." >&2
  exit 2
fi
exit 0
