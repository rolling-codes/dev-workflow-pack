# Issues

Model: `fast`.

```bash
gh issue create --title "..." --label "bug"
gh issue list --label "bug" --state open
gh issue close {n} --comment "Fixed in PR #{pr}"
```

Link commits: `git commit -m "fix: ...\n\nCloses #{n}"`
