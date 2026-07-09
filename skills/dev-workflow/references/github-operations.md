# GitHub Operations

Use `gh` CLI first; GitHub API only if `gh` can't do it. Model: `standard`.

```bash
gh pr list --head $(git branch --show-current)   # check before creating
gh pr create --fill                              # uses template automatically
gh pr merge --squash --delete-branch
gh pr checks
gh api repos/{owner}/{repo}/branches --jq '[.[] | select(.protected) | .name]'
gh release create vX.Y.Z --generate-notes       # publish a GitHub release
```

**For a full PR description:** invoke the **pr-description** skill — it reads the diff,
commit history, and applies the right template. Don't write PR copy inline here.

Only read `.github/PULL_REQUEST_TEMPLATE.md` if `--fill` fails or user wants to customize.

For advanced API usage beyond the above → `github-patterns.md`.
