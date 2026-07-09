# Upgrades and self-install guide

This file lists the parts of dev-workflow-pack that public projects do better, and gives an agent the exact steps to install the pack itself. Read the "Trust" section before running anything, because every item here executes with your permissions.

## What other projects do better

Three features in this pack have stronger public versions. Each entry says what to read, what it replaces, and the honest limit. None of these are bundled, because importing another author's scripts is a trust decision only you should make.

### Context compression

The strategic-compact skill in ECC suggests compacting at logical breakpoints instead of at a fixed percentage. That is a smarter trigger than this pack's fixed fifty percent, because a breakpoint is a natural place to summarize while a percentage can land mid-thought. Read skills/strategic-compact/SKILL.md in the repository at github.com/affaan-m/everything-claude-code. The limit is that its trigger claim comes mainly from its own README, so treat it as a lead to verify, not a proven number.

### Session memory

The claude-mem project compresses session history with a model and fetches only the entries it needs, using a search then fetch pattern. That is stronger than this pack's load-memory hook, which greps a single JSON file and cannot rank relevance. Read the repository at github.com/thedotmack/claude-mem. The limit is that it runs a background worker service and is a full plugin, so it is a reference to study rather than a drop-in replacement, and a worker that captures everything is a larger attack surface than a grep.

### Code reviewer agent

This pack's code-reviewer agent already restricts itself to Read, Grep, Glob, and Bash, which is the safe pattern other packs recommend, so no change is needed here. Multi-perspective review panels exist in public toolkits if you ever want several reviewer viewpoints at once, but they cost several context windows, so the single reviewer here is more token-efficient for normal work.

## How the plugin installs itself

An agent with shell access can install this pack from a local copy. These steps assume the pack folder is named dev-workflow-pack and sits in the current directory.

First, verify the pack is internally consistent by running the validator, which is the shell command: sh dev-workflow-pack/tools/validate-pack.sh. A zero exit means the files agree with each other. This does not test live behavior, only structure.

Second, register the pack as a local marketplace with the command: claude plugin marketplace add ./dev-workflow-pack. The add subcommand reads the marketplace file at .claude-plugin/marketplace.json and makes the catalog known to Claude Code.

Third, install the plugin from that marketplace with the command: claude plugin install dev-workflow-pack@rollingcodes-plugins. The name before the at sign is the plugin, and the name after it is the marketplace, which is the name field inside marketplace.json.

Fourth, confirm it loaded by running the command: claude plugin list. The pack should appear with its skills, its one agent, and its hooks. If hooks do not register, restart Claude Code or run the reload command, which is: /reload-plugins.

If you host the pack on GitHub instead of a local folder, replace the local path in step two with the owner and repository shorthand, for example: claude plugin marketplace add RollingCodes/dev-workflow-pack. Relative paths in the marketplace file only resolve when the marketplace is added through Git or a local path, not through a direct link to the file itself.

## Trust

Hooks and skills in this pack run shell commands as you. The scripts are short on purpose so you can read them in a few minutes, and they live in hooks/scripts. Before importing anything from the projects named above, read their scripts the same way, because a skill is instructions plus code that runs with your account, and provenance is the real filter. The safest changes are the ones you can verify by eye.

## Verify these claims yourself

The install commands come from Anthropic's plugin and marketplace documentation at code.claude.com, which is the primary source and the one to trust over this file if they ever disagree. Confirm the current command names by running claude plugin with no arguments, which prints the available subcommands, since command names can change between versions.
