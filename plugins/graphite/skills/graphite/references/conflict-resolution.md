# Conflict Resolution in Graphite Stacks

## Why Restack Conflicts Happen

Branches in a stack share a base. When a lower branch changes (amended, rebased, or synced), upper branches may conflict during `gt restack` or `gt sync`. Graphite uses `git rebase` under the hood.

## Essential Commands

```bash
gt continue -a    # Stage all resolved files and continue restack
gt continue       # Continue (files must already be staged)
gt abort          # Abandon restack, return to previous state
```

## Conflict Classification

### Auto-Resolvable (safe to fix without asking)

| Pattern | Resolution |
|---------|------------|
| Import ordering | Keep all imports from both sides, deduplicate, sort |
| Whitespace/formatting | Accept the version matching project style |
| Non-overlapping additions | Keep both additions in logical order |
| Version bumps | Take the higher version |
| Both sides make identical changes | Already resolved, remove markers |
| Adjacent line additions | Keep both, order logically |

### Needs User Decision (always ask)

| Pattern | Why |
|---------|-----|
| Same code modified differently | Need to understand intended behavior |
| Delete vs modify | One side deleted code the other modified |
| Semantic/logic conflicts | Changes may break behavior |
| Test expectation changes | Need to determine correct expected values |
| Schema conflicts that interact | Column additions may have dependencies |
| Type definition conflicts | Shape changes affect multiple consumers |

## Lock File Conflicts

For lock files (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, etc.):

```bash
git checkout --theirs <lockfile>
# Regenerate with your package manager (npm install, pnpm install, etc.)
git add <lockfile>
```

## Step-by-Step Resolution Process

1. **Read the conflicted file** using the Read tool to see conflict markers
2. **Identify all conflict markers**: `<<<<<<<`, `=======`, `>>>>>>>`
3. **For each conflict block**:
   - `<<<<<<< HEAD` = current branch (being rebased onto)
   - `=======` = separator
   - `>>>>>>> <branch>` = incoming changes from the branch being restacked
4. **Classify** each block as auto-resolvable or needs-user-input
5. **Resolve**: edit the file to remove markers and keep correct code
6. **Stage**: `git add <file>`
7. **Continue**: `gt continue` (or `gt continue -a` to stage + continue)

## When to Abort

Stop and use `gt abort` when:
- Conflicts span 5+ files with semantic overlaps
- Business logic implications are unclear
- The lower branch hasn't been reviewed yet (resolve issues there first)
- You're unsure and the user isn't available to decide

After aborting, inform the user and suggest resolving the root cause in the lower branch first.

## Post-Resolution Checklist

After all conflicts are resolved and restack completes:

- [ ] Project type checker passes
- [ ] Project linter passes
- [ ] No unintended type changes introduced during merge
- [ ] Import paths are correct
- [ ] `gt submit --no-interactive` to push updated branches
