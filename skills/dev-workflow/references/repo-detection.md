# Repo Detection

Run at session start. Goal: understand the repo structure with minimal token cost.

## Detection Steps

### 1. Identify repo type
```bash
# Check for monorepo signals
ls -1 | grep -E "^(packages|apps|libs|services|modules)$"
cat package.json 2>/dev/null | grep -E '"workspaces"'
cat pnpm-workspace.yaml 2>/dev/null
cat lerna.json 2>/dev/null

# Check for multi-repo signals (if in a parent dir)
ls -d */ | head -20
```

### 2. Identify stack
```bash
# Detect language/framework
ls package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle 2>/dev/null
# Read only the first 30 lines of the top-level manifest
head -30 package.json 2>/dev/null || head -30 pyproject.toml 2>/dev/null
```

### 3. Read repo conventions
```bash
# Check for contributing guide, PR templates, lint config
ls .github/ 2>/dev/null
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
cat .github/CONTRIBUTING.md 2>/dev/null | head -60
```

### 4. Identify protected branches
```bash
# Via gh CLI
gh api repos/{owner}/{repo}/branches --jq '[.[] | select(.protected) | .name]' 2>/dev/null
# Or parse .github/ config
ls .github/workflows/ 2>/dev/null | grep -i "branch\|protect"
```

### 5. Check for .gitignore / exclusions
```bash
# Quickly scan for patterns relevant to Claude's work
grep -E "^(node_modules|dist|build|\.env|secrets)" .gitignore 2>/dev/null
```

## Adaptation Strategy

| Signal | Adaptation |
|---|---|
| `packages/` or `apps/` dir | Monorepo: scope file reads per-package |
| Multiple top-level repos | Multi-repo: track which repo each task belongs to |
| `CODEOWNERS` file | Route review tasks to correct owners |
| `.github/PULL_REQUEST_TEMPLATE.md` | Pre-fill PR bodies with template |
| Strict lint/format config | Apply format rules before committing |

## Output
After detection, store a compact repo summary in working memory:
```
repo_type: monorepo|multi-repo|single
stack: [list]
protected_branches: [list]
pr_template: yes|no
conventions: [any notable ones found]
```
