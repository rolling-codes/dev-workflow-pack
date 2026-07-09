# Code Review (reviewing someone else's PR)

> **Reviewing your own changes before merge?** Use the **code-review** skill — its
> self-review mode (§A) runs the five-question checklist, line-by-line pass, and test
> coverage check; its delegated mode (§B) dispatches a reviewer subagent for larger work.

For reviewing *someone else's* PR. Model: `standard`.

```bash
gh pr diff {number}
git diff main..HEAD
```

Feedback format:
- 🔴 **Blocking** — must fix before merge
- 🟡 **Suggestion** — worth discussing
- 🟢 **Nit** — optional

Read surrounding file context only if a diff line is ambiguous. Use `sed -n`, not full loads.
