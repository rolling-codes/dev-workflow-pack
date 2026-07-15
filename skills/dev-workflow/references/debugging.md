# Debugging

> If a dedicated debugging skill is installed (e.g. systematic-debugging), prefer
> it for the full reproduce, hypothesis, root-cause discipline. This section only
> covers model selection for debugging you're already doing inline.

Follow the error — don't preload.

```bash
# error message → file:line → read only that section
sed -n '{start},{end}p' {file}

# trace the call chain minimally
grep -n "functionName" src/**/*.ts | head -20
```

When a graph is available (per `references/graph-tools.md`), query it for the
callers of the failing function instead of grepping the call chain by hand —
grep is the fallback, not the first move.

Use `deep` for bugs where reasoning across multiple files is needed.
Drop back to `standard` once the cause is identified and you're writing the fix.
