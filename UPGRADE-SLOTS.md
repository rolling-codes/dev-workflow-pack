# Upgrade slots

These upgrades are placeholders, not working code, and this file explains why and how to fill them.

## Why they are placeholders

The real source for these upgrades was never copied in, so nothing here runs yet. The two projects live on GitHub, and their actual script and skill files could not be pulled into this pack, so writing them from memory would risk shipping invented code that only looks right. An empty slot you fill from the real source is safer than a plausible guess.

Trust the primary repo over anything described here. Each project's own README is the source for its behavior, and where this file and the repo disagree, the repo wins.

## The two slots

The first slot replaces the context-compression skill. The stronger version is strategic-compact from the ECC project, which compacts at logical breakpoints instead of at a fixed percentage. Its repository is github.com/affaan-m/everything-claude-code, and the file to copy is skills/strategic-compact/SKILL.md.

The second slot is session memory. The stronger version is claude-mem, which compresses session history with a model and fetches only what it needs. Its repository is github.com/thedotmack/claude-mem. This one does not slot into the pack as a file, it installs as its own separate plugin with a background worker, so treat it as a companion, not a replacement file.

## How to fill the first slot

Get the real skill file first. Open the ECC repo, read skills/strategic-compact/SKILL.md with your own eyes, and confirm it does what you want before trusting it.

Copy it into this pack. Place it at skills/strategic-compact/SKILL.md inside dev-workflow-pack, keeping the folder name and the frontmatter name identical, because the validator checks that they match.

Rewire the router. Open skills/dev-workflow/SKILL.md and add a line naming strategic-compact in the routing table, because the validator fails if a skill exists with no routing entry. That failure is intentional, it forces every addition to be deliberate.

Decide the old skill's fate. Either delete the context-compression folder if strategic-compact fully replaces it, or keep both and note in the router which one wins, since two skills that do the same job will compete.

Prove it holds. Run the validator, which is the shell command: sh tools/validate-pack.sh. A zero exit means the files agree. Then smoke-test the skill in a real session, because the validator checks structure, not live behavior.

## How to set up the second slot

Do not copy claude-mem into this pack. Install it on its own by following its repo's install steps, because it runs a worker service and is a full plugin, not a drop-in file.

Read its scripts before you trust it. A memory tool that captures everything and talks to a worker is a larger attack surface than this pack's simple grep hook, so provenance is the real filter here.

Avoid double memory. If you run claude-mem, consider disabling this pack's load-memory and save-memory hooks in /hooks, so two memory systems do not fight over the same session.

## The honest limit

No token savings number is given here on purpose, because neither project publishes a measured one, and any figure would be invented. Both tools also add their own always-on context cost, so the net gain shows up only on long sessions and could be negative on short ones. Measure it against your own transcripts if you want a real number.
