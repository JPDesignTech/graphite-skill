---
name: graphite
description: Manage Graphite stacked PRs. USE THIS SKILL when the user invokes "/graphite", "/gt", "/stack", says "debug my stack", "get stack comments", "resolve restack conflicts", "create a stack", "submit stack", "sync graphite", "restack", "debug PR", "PR comments", or "stack status". Provides four workflows for stack debugging, comment aggregation, conflict resolution, and general Graphite operations.
triggers:
  - "/graphite"
  - "/gt"
  - "/stack"
  - "debug my stack"
  - "get stack comments"
  - "resolve restack conflicts"
  - "create a stack"
  - "submit stack"
  - "sync graphite"
  - "restack"
  - "debug PR"
  - "PR comments"
  - "stack status"
---

# Graphite Stack Manager

Manage stacked PRs using Graphite CLI.

---

## Prerequisites

This skill only applies to Graphite-managed repositories. Verify by checking for `.git/.graphite_repo_config`.

- **If file exists**: Use `gt` commands (this skill applies)
- **If file does not exist**: Use standard `git` commands (this skill does NOT apply)

## Tool Preferences

1. **Primary**: Use `mcp__graphite__run_gt_cmd` for all `gt` commands (if Graphite MCP is connected)
2. **Fallback**: Use `Bash(gt ...)` if MCP tool is unavailable or errors
3. **GitHub API**: Use `gh` CLI for PR comments, CI status, reviews (not covered by Graphite MCP)
4. **Learn**: Use `mcp__graphite__learn_gt` when unsure about a command's syntax or flags
5. **Non-interactive**: Always pass `--no-interactive` to `gt submit` and other interactive commands

## Repo Detection

At the start of any workflow, detect the repo context:

```bash
# Get trunk branch name
gt trunk 2>/dev/null || echo "main"

# Get GitHub repo (owner/name)
gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null
```

Store these as `TRUNK` and `REPO` for use in all subsequent commands.

---

## Workflow Router

When the skill triggers, identify which workflow the user needs from context. If ambiguous, ask with `AskUserQuestion`:

| Workflow | When to use |
|----------|-------------|
| **1. Debug Stack** | User mentions CI failures, PR issues, review blockers, stack status |
| **2. Stack Comments** | User wants PR review comments, feedback, or unresolved threads |
| **3. Resolve Conflicts** | User mentions restack conflicts, merge conflicts, sync issues |
| **4. General Workflow** | Creating stacks, submitting, syncing, navigating, reorganizing |

---

## Workflow 1: Debug Stack Issues

Diagnose CI failures, review blockers, and PR status across the entire stack.

### Step 1: Get the Stack

Run `gt log short` to get the ordered list of branches in the current stack.

### Step 2: Gather PR Status for Each Branch

For each branch in the stack, run in parallel where possible:

```bash
gh pr list --repo $REPO --head <branch> --json number,title,state,statusCheckRollup,reviewDecision,mergeable,isDraft
```

### Step 3: Drill into Failures

For PRs with failing checks:

```bash
gh pr checks <number> --repo $REPO
```

For specific failed runs, get the failure log:

```bash
gh run view <run_id> --repo $REPO --log-failed
```

### Step 4: Present the Report

Format a structured table:

```
| # | Branch | PR | CI | Reviews | Blockers |
|---|--------|----|----|---------|----------|
| 1 | branch-name | #123 | passing/failing | approved/changes_requested/pending | list blockers |
```

### Step 5: Recommend Fix Order

Always fix from the **bottom of the stack up** -- fixes in lower branches cascade to upper branches after restack. Explain which PRs are blocked by which failures.

---

## Workflow 2: Get All Stack Comments

Aggregate all PR review comments across the entire stack into one view.

### Step 1: Get the Stack

Run `gt log short` to get the ordered branch list.

### Step 2: Get PR Numbers

For each branch:

```bash
gh pr list --repo $REPO --head <branch> --json number,title
```

### Step 3: Fetch Comments

For each PR, fetch both types of comments:

**Inline code review comments** (file-specific):
```bash
gh api repos/$REPO/pulls/<number>/comments --jq '.[] | {path: .path, line: .line, body: .body, user: .user.login, created_at: .created_at, in_reply_to_id: .in_reply_to_id}'
```

**General review comments** (PR-level):
```bash
gh api repos/$REPO/pulls/<number>/reviews --jq '.[] | {state: .state, body: .body, user: .user.login, submitted_at: .submitted_at}'
```

**Issue comments** (conversation):
```bash
gh pr view <number> --repo $REPO --json comments --jq '.comments[] | {body: .body, author: .author.login, createdAt: .createdAt}'
```

### Step 4: Present Grouped by PR

Present comments in **bottom-up stack order** (matches fix priority):

```
## PR #123: feat: add fog layer (branch: feat_fog_layer)

### Inline Comments
- **file.tsx:42** (@reviewer): "Consider using useCallback here"
- **store.ts:15** (@reviewer): "This should be derived state"

### Review Comments
- @reviewer (CHANGES_REQUESTED): "Needs error handling for the disconnect case"

### Conversation
- @reviewer: "Can we add a loading state?"
```

### Step 5: Offer Filters

After presenting, ask if the user wants to filter:
- **Unresolved only** -- exclude resolved/dismissed threads
- **By reviewer** -- show only comments from a specific person
- **By file path** -- show only comments on specific files

---

## Workflow 3: Resolve Restack Conflicts

Guide the user through resolving conflicts during `gt restack` or `gt sync`.

### Step 1: Trigger the Restack

Run the command the user requested:
- `gt restack` -- rebase current stack onto parents
- `gt sync` -- pull trunk, rebase all stacks, clean merged

### Step 2: Detect Conflicts

If the output contains "CONFLICT" or the command exits with an error:

1. Parse the conflicted file paths from the output
2. Run `git diff --name-only --diff-filter=U` to get the full list of unmerged files

### Step 3: Resolve Each File

For each conflicted file:

1. **Read the file** with the Read tool to see conflict markers
2. **Classify the conflict** using `references/conflict-resolution.md`:
   - **Auto-resolvable**: Import ordering, whitespace, non-overlapping additions
   - **Needs user input**: Same code modified differently, delete vs modify, semantic changes
3. **For auto-resolvable conflicts**:
   - Show the proposed resolution to the user
   - On approval, edit the file using the Edit tool to remove markers and apply the fix
4. **For manual conflicts**:
   - Show both sides with surrounding context
   - Explain what each branch was trying to do
   - Ask the user which version to keep or how to merge
   - Apply the user's decision
5. **Stage the resolved file**: `git add <file>`

### Step 4: Continue the Restack

After all files in the current step are resolved:

```bash
gt continue
```

If more conflicts appear (next branch in the stack), repeat from Step 3.

### Step 5: Post-Resolution Verification

After the full restack completes, suggest running the project's type checker and linter to catch incomplete resolutions.

### Step 6: Push Updates

Suggest pushing the restacked branches:

```bash
gt submit --no-interactive
```

### Emergency Exit

If conflicts are too complex or the user wants to stop:

```bash
gt abort
```

This returns to the state before the restack started. No work is lost.

---

## Workflow 4: General Graphite Operations

### 4a. Planning a Stack (Before Coding)

**Always plan the stack structure before writing code.**

Break the feature into logical, sequential PRs. Each PR should represent one logical concern.

Present the planned stack to the user:

```
Stack Plan for [Feature]:
1. PR 1: [branch-name] - [description] (~X lines)
2. PR 2: [branch-name] - [description] (~X lines)
3. PR 3: [branch-name] - [description] (~X lines)
```

**Each PR must**:
- Be < 250 lines changed
- Pass CI independently
- Focus on one logical concern
- Be reviewable on its own

Ask for confirmation before creating any branches.

### 4b. Creating Branches

Stage the relevant files, then create:

```bash
gt create <branch-name> -m "<conventional-commit-message>"
```

Or stage all and create in one step:

```bash
gt create <branch-name> -am "<conventional-commit-message>"
```

**Commit message format**: conventional commits, casual and concise
- `feat: add fog layer state management`
- `fix: resolve token position reset on map change`
- `refactor: extract service from router`
- `chore: update schema for new table`

### 4c. Modifying an Existing Branch

To amend the current branch (e.g., addressing review feedback):

```bash
gt modify -a
```

This stages all changes, amends the commit, and auto-restacks all descendant branches.

For adding a separate commit (not amending):

```bash
gt modify -c
```

### 4d. Submitting PRs

**Current branch + all downstack** (recommended default):
```bash
gt submit --no-interactive
```

**Entire stack including descendants**:
```bash
gt submit --stack --no-interactive
```

**PR descriptions** should explain:
1. What changed
2. Why it changed
3. The benefit

Keep it casual and concise. No LLM fluff, no em dashes.

After submitting, return the **Graphite PR URL** (e.g., `https://app.graphite.dev/github/pr/...`) when available.

### 4e. Syncing

Pull latest trunk, rebase all stacks, clean merged branches:

```bash
gt sync
```

Run this:
- At the start of each work session
- After PRs are merged into trunk
- Before starting new work on an existing stack

If conflicts arise during sync, switch to **Workflow 3** (Resolve Conflicts).

### 4f. Navigation

```bash
gt log           # Full stack visualization with PR status
gt log short     # Compact view
gt up            # Move up one branch
gt down          # Move down one branch
gt top           # Jump to top of stack
gt bottom        # Jump to bottom of stack
gt checkout X    # Switch to specific branch
```

### 4g. Reorganizing Stacks

```bash
gt move --onto <branch>    # Reparent current branch
gt fold                    # Merge current branch into parent
gt split                   # Split current branch into multiple
gt reorder                 # Reorder branches in stack
gt absorb                  # Distribute staged changes to correct downstack branch
```

### 4h. Branch Cleanup

```bash
gt delete <branch>         # Delete a branch
gt rename <new-name>       # Rename current branch
```

---

## Key Principles

1. **Tool priority**: `mcp__graphite__run_gt_cmd` > `Bash(gt ...)` > ask user to run manually
2. **Learn first**: Use `mcp__graphite__learn_gt` when unsure about command syntax
3. **Never force-push**: Let `gt submit` handle all pushes
4. **Plan first, code second**: Always present stack structure before creating branches
5. **Small PRs**: Each branch < 250 lines, one concern
6. **CI independence**: Each PR must pass CI on its own
7. **Bottom-up fixes**: Fix lower branches first; changes cascade up after restack
8. **Non-interactive**: Always use `--no-interactive` for automated commands
9. **Commit style**: Conventional commits (`feat:`, `fix:`, etc.), casual and concise, no LLM fluff

## Quick Reference

See `references/cheatsheet.md` for the full gt command reference.
See `references/conflict-resolution.md` for detailed conflict resolution patterns.
