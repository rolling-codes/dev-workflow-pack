# Coding Tasks

**Before writing any code:**
1. Model `fast` — plan which files are involved (grep, don't browse)
2. Switch to `standard` — read relevant sections and implement
3. Upgrade to `deep` only for complex logic or architecture decisions
4. Run lint/tests scoped to changed files only

```bash
grep -rl "functionName" src/             # find without loading
npx jest --findRelatedTests src/auth.ts  # test only what changed
```

**Development principles:**
- Interfaces before implementations — read the contract first
- Tests before source — they reveal intent cheaply
- Write the smallest change that satisfies the requirement
- Validate assumptions with a grep before writing code that depends on them
- Never modify files outside the task scope

> **Scope creep watch:** if the user adds a new requirement mid-task ("oh, and also
> make it do X"), the **scope-creep** skill fires automatically before continuing.
