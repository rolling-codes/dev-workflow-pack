# Context & Token Management

**The best solution reaches a correct conclusion using the smallest amount of necessary context.**

---

## Decision Rule

Before reading any file, loading any output, or expanding investigation:

> "Will this information materially improve my ability to complete the task?"

If the answer is not clearly **yes** — do not load it.

---

## Investigation Depth by Task Type

| Task | Depth |
|---|---|
| Routine change (typo, config tweak, minor fix) | Shallow — target file only |
| Feature work | Moderate — interface + relevant files |
| Architecture change, security work, debugging, high-risk mod | Deep — full chain |

Default to shallow. Only go deeper when uncertainty remains after the current depth.

---

## Information Hierarchy (load in this order, stop when sufficient)

1. Task instructions
2. Project documentation (`README`, `CONTRIBUTING`, `docs/`)
3. Architecture documentation
4. Existing plans / tickets
5. Tests (reveal intent without loading implementation)
6. Relevant source files
7. Adjacent source files
8. Repository-wide exploration

**Never reverse this order without explicit justification.**

---

## Targeted Discovery Before Reading

Before opening any file, run discovery:

```bash
# Find the symbol — don't guess the file
grep -rn "functionName\|ClassName" src/ --include="*.ts" -l

# Find definition specifically
grep -rn "^export function\|^export class" src/ --include="*.ts" | grep "targetName"

# Check if tests already document the behavior
find . -name "*.test.*" | xargs grep -l "targetName" 2>/dev/null

# Check docs first
ls docs/ README* ARCHITECTURE* 2>/dev/null
```

Only open a file after discovery confirms it's the right one.

---

## Read the Smallest Useful Amount

```bash
# 1. How big is it?
wc -l src/auth.ts

# 2. What's its structure?
grep -n "^export\|^function\|^class\|^const\|^type\|^interface" src/auth.ts

# 3. Read only the relevant section
sed -n '45,80p' src/auth.ts
```

Priority order for any file:
- **Interfaces before implementations**
- **Documentation before source**
- **Tests before source** (tests reveal intent cheaply)
- **Entry points before internals**

---

## Working Context (maintain actively)

Track this mentally / in a scratchpad, not by re-reading files:

```
objective:    [what I'm trying to do]
assumptions:  [what I'm treating as true]
files:        [only files confirmed relevant]
findings:     [what I've learned so far]
questions:    [what's still uncertain]
next:         [immediate next action]
```

When a finding is no longer relevant to the current task — **discard it**.

---

## Compress After Investigation

After completing any non-trivial investigation, create a one-paragraph summary:
- What was discovered
- Why it matters
- Files involved
- Decisions made
- Remaining uncertainties

Then **reference the summary** instead of re-reading the source. Never restate:
- Previously established requirements
- Earlier findings
- Existing architectural decisions
- Plans already agreed on

---

## Stop Expanding When Ready to Proceed

When you have enough to act:
1. Stop researching
2. Create a plan
3. Execute

Continuous exploration beyond "sufficient to proceed" wastes context and increases
hallucination risk. Scope does not expand automatically — it requires a new uncertainty
to justify it.

---

## Preserve High-Signal, Drop Low-Signal

**Keep:**
- Requirements and constraints
- Architecture decisions
- API contracts
- Security considerations
- Test expectations

**Drop / summarize:**
- Boilerplate and generated code
- Repetitive implementation details
- Irrelevant file contents
- Verbose command output (keep only the signal — errors, key values)

---

## Periodic Re-Evaluation

At natural pause points (between subtasks, before a new file read), ask:
- Is this still relevant to the current task?
- Can it be summarized?
- Can it be discarded?

Continuously optimize context quality — don't let stale information accumulate.

---

# Token Budget

## Estimating Context Budget

There's no direct token counter available, but estimate from:
- Number of files loaded (avg ~500–2000 tokens per file)
- Length of conversation so far
- Sub-agent spawning reduces main context load

### Mental Budget Model

| Situation | Est. Token Cost |
|---|---|
| Reading a small file (<100 lines) | ~300–600 tokens |
| Reading a medium file (100–500 lines) | 600–3000 tokens |
| Reading a large file (500+ lines) | 3000–10,000+ tokens |
| Full PR diff (medium PR) | 2000–8000 tokens |
| Running and reading test output | 500–3000 tokens |

## Load Strategy by Budget Level

### Green Zone (<40% estimated budget used)
- Load files freely
- Read full diffs
- Keep full conversation history in context

### Yellow Zone (40–60%)
- Read only specific sections of files (use line ranges)
- Summarize large outputs before keeping them
- Avoid loading reference docs unless actively needed
- Start delegating parallelizable work to sub-agents

### Orange Zone (60–80%)
- Stop loading new files speculatively
- Compress earlier context: summarize resolved threads into one paragraph
- Delegate any remaining independent subtasks to sub-agents immediately
- Write current state to memory in case context needs to be reset

### Red Zone (>80%)
- STOP. Do not load anything new.
- Write memory checkpoint now
- Summarize current state for the user
- Offer to continue in a fresh context: "We're close to context limits — I've saved our progress. Want to continue in a new session?"

## Context Compression

When summarizing older context to free up budget:
1. Identify resolved threads (completed tasks, answered questions)
2. Replace them with a 1–2 sentence summary
3. Keep: current task state, open decisions, file paths modified
4. Discard: verbose error logs (keep just the key error), full file dumps already processed

## Sub-Agent Offloading

When a subtask would consume >1000 tokens of context (e.g., a large code review, running
tests, or reading a folder of files), evaluate delegating it. The sub-agent returns only
the relevant result, keeping the main context lean. See `sub-agents.md`.
