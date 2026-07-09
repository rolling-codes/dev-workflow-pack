# GitHub Patterns (advanced)

Load this only if the main SKILL.md commands don't cover what you need.

## API calls gh CLI can't do

```bash
# Get file at a specific commit without cloning the whole repo
gh api /repos/{owner}/{repo}/contents/{path}?ref={sha} --jq '.content' | base64 -d

# List workflows
gh api /repos/{owner}/{repo}/actions/workflows --jq '[.workflows[] | {id, name, state}]'

# Trigger a workflow manually
gh api /repos/{owner}/{repo}/actions/workflows/{id}/dispatches \
  --method POST -f ref=main

# Get CODEOWNERS (only if routing a review)
gh api /repos/{owner}/{repo}/contents/.github/CODEOWNERS --jq '.content' | base64 -d
```

## Re-run / CI
```bash
gh run list --limit 5
gh run watch
gh run rerun --failed
```

## Bulk operations
```bash
# Close all issues with a label
gh issue list --label "wontfix" --json number --jq '.[].number' \
  | xargs -I{} gh issue close {}
```
