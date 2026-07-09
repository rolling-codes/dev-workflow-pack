# Memory Management

Claude has no memory between sessions by default. This reference defines how to persist
and reload state so dev workflows feel continuous.

## Storage Location

Three files inside the repo, with a clean split of ownership:

- `.claude/memory.json` — narrative state (conventions, decisions, open work,
  session summary). Written by this skill using the schema below. Rewritten
  often; kept short and truncated by the SessionStart hook.
- `.claude/memory-auto.json` — mechanical snapshot (branch, dirty count, recent
  commits). Written automatically by the plugin's PreCompact hook. Never write
  this file yourself.
- `.claude/architecture.json` — optional, long-lived component/dependency map
  (see § Architecture Log below). Written rarely, only when structure actually
  changes. Not truncated, not auto-loaded in full — the digest only points at it.

`memory.json` and `memory-auto.json` are injected into context by the plugin's
SessionStart hook on startup, resume, and after compaction. `architecture.json`
is only pointed to, never injected in full — read it deliberately when a task
needs the component map (e.g. "where does this module fit"). Commit all three
for shared memory, or add `.claude/*.json` to `.gitignore` to keep it local.

## Memory Schema

```json
{
  "repo": "owner/repo-name",
  "last_updated": "ISO timestamp",
  "conventions": {
    "branch_prefix": "feat/ | fix/ | chore/",
    "commit_format": "conventional | custom | none",
    "pr_template": true,
    "test_command": "npm test",
    "lint_command": "npm run lint",
    "notes": ["any freeform rules discovered"]
  },
  "decisions": [
    { "date": "...", "decision": "...", "rationale": "..." }
  ],
  "open_work": [
    { "id": "issue/PR number or task name", "status": "in-progress|blocked|done", "notes": "..." }
  ],
  "dont_do": [
    "Never squash commits on this repo",
    "Don't touch packages/legacy without asking"
  ],
  "session_summary": "One paragraph summary of the last session"
}
```

## Architecture Log (`.claude/architecture.json`, optional)

For repos where "how is this thing structured" is a recurring question. Write it
once structure stabilizes, update only on real structural change — not per session.

```json
{
  "last_updated": "ISO timestamp",
  "components": [
    { "name": "PluginConfigManager", "path": "src/plugins/config.ts", "role": "..." }
  ],
  "dependencies": [
    { "from": "PluginConfigManager", "to": "EventBus", "kind": "runtime" }
  ],
  "decisions": [
    { "date": "...", "decision": "...", "reason": "...", "supersedes": null }
  ]
}
```

`decisions` here is structural/architectural (why the system is shaped this way);
`memory.json`'s `decisions` array stays session-scoped (why *this change* was made).
Don't duplicate an entry into both — file it once, in whichever scope it belongs to.

## Knowledge Base Layer (Graphify)

The memory files above are the *mechanical* layer: session-scoped, truncated,
rewritten often. Durable knowledge lives in the knowledge graph, fed through the
**graphify** skill (`/graphify` — routes any input to the knowledge graph).

**What flows to the graph** (at the same moments as the Write Protocol below,
when graphify is installed):
- Decisions with their rationale — once they're stable, not per-session churn
- Architecture changes (the same events that update `architecture.json`)
- Lessons: real failures, root causes, and fixes worth keeping across projects

**What stays out of the graph:**
- Mechanical state (branch, dirty counts, open-work status) — that's `memory.json`'s job
- Anything transient, and never secrets/tokens/credentials

**If graphify is not installed:** `memory.json` is the only persistence layer.
Say so once ("knowledge-graph handoff skipped — graphify not installed") rather
than failing or silently dropping the durable items; they stay in `memory.json`
until the graph is available.

## Load Protocol (session start)

Handled by the plugin's SessionStart hook — the memory files arrive in context
automatically. When they do:
- Briefly acknowledge it to the user: "Picking up where we left off — [one line summary]"
- Pre-load conventions into working context
- Surface any open work items that are in-progress

Manual fallback if hooks are disabled:

```bash
cat .claude/memory.json .claude/memory-auto.json 2>/dev/null
```

If no memory exists: start fresh, begin accumulating as work proceeds.

## Write Protocol (session end or context switch)

Write `.claude/memory.json` after:
- Completing a PR or issue
- Discovering a new repo convention
- A user corrects Claude or states a preference
- Context budget hits 70%+ (write before losing state)
- End of conversation

```bash
mkdir -p .claude
cat > .claude/memory.json << 'EOF'
{ ...updated JSON using the schema above... }
EOF
```

The mechanical snapshot (`.claude/memory-auto.json`) is the PreCompact hook's
job — never write it from the skill.

## What NOT to store
- Full file contents (use the repo for that)
- Verbose logs or diffs
- Anything the user marked as temporary
- Secrets, tokens, credentials — never
