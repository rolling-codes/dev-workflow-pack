# Graph Tools — Canonical Availability Check

Every graph-first instruction in this pack resolves through this check, because
naming a specific tool inline goes stale the moment the toolchain changes — nine
copies of "query graphify" is nine files to patch when the answer becomes "query
codegraph".

## The check (run in order, stop at first hit)

1. **`graphify-out/graph.json` exists** → use graphify:
   ```bash
   graphify query "<question>"     # BFS traversal — broad context
   graphify path "NodeA" "NodeB"   # shortest path between two concepts
   graphify explain "NodeName"     # plain-language node summary
   ```
   Or `query_graph("<question>", budget=500)` via the Graphify MCP.

2. **Else, codegraph MCP connected** (server `codegraph` in `~/.claude/mcp.json`,
   `@optave/codegraph`) → query it for function-level dependencies: callers of a
   symbol, blast radius of a change, dead code, entry-point classification.

3. **Neither** → say "no graph available" explicitly — a silent fallback hides
   that the answer is now an estimate — then bound the read with `grep -rl` /
   `git diff` before opening any file.

## Which tool for which question

| Question type | Tool |
|---|---|
| Fan-out / blast radius of a change | codegraph or graphify (either) |
| Callers of a specific function | codegraph preferred |
| Dead code / entry-point classification | codegraph |
| Semantic "how do these modules relate?" | graphify only |
| Bug history / decisions / cross-cutting concepts | graphify only |

## Rule

Querying a graph costs one tool call; reading the equivalent context from files
costs thousands of tokens. Never hand-count fan-out, hand-trace call chains, or
estimate blast radius when step 1 or 2 hits — open files only to verify edges the
graph flagged.
