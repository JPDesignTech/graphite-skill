# Graphite CLI Cheatsheet

## Core Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `gt create <name> -m "<msg>"` | `gt c` | Create branch + commit staged changes |
| `gt create -am "<msg>"` | | Stage all, create branch + commit |
| `gt modify` | `gt m` | Amend staged changes into current branch |
| `gt modify -a` | | Stage all and amend |
| `gt modify -c` | | Add new commit (don't amend) |
| `gt submit` | `gt s` | Push current + downstack, create/update PRs |
| `gt submit --stack` | `gt ss` | Push entire stack (current + descendants) |
| `gt submit --no-interactive` | | Submit without prompts (preferred for automation) |
| `gt submit --stack --update-only` | `gt ss -u` | Update existing PRs only |
| `gt sync` | | Pull trunk, rebase stacks, clean merged branches |

## Navigation

| Command | Alias | Description |
|---------|-------|-------------|
| `gt log` | | Full stack with PR info and status |
| `gt log short` | `gt ls` | Compact stack view |
| `gt up [N]` | `gt u` | Move N branches up in stack |
| `gt down [N]` | `gt d` | Move N branches down |
| `gt top` | `gt t` | Jump to top of stack |
| `gt bottom` | `gt b` | Jump to bottom of stack |
| `gt trunk` | | Jump to trunk branch |
| `gt checkout <branch>` | `gt co` | Switch to specific branch |

## Stack Manipulation

| Command | Alias | Description |
|---------|-------|-------------|
| `gt restack` | | Rebase all branches onto their parents |
| `gt move --onto <branch>` | | Reparent current branch |
| `gt fold` | | Merge current branch into parent |
| `gt split` | `gt sp` | Split current branch into multiple |
| `gt squash` | `gt sq` | Combine commits into one |
| `gt reorder` | | Reorder branches in stack |
| `gt absorb` | `gt ab` | Distribute staged changes to correct downstack branch |

## Branch Management

| Command | Description |
|---------|-------------|
| `gt delete <name>` | Delete a branch |
| `gt rename <name>` | Rename current branch |
| `gt track <branch>` | Start tracking an existing git branch |
| `gt untrack <branch>` | Stop tracking a branch |

## Recovery

| Command | Description |
|---------|-------------|
| `gt abort` | Abandon in-progress restack/merge |
| `gt continue` | Resume after resolving conflicts |
| `gt continue -a` | Stage all resolved files and continue |
| `gt undo` | Undo last gt operation |

## Info

| Command | Description |
|---------|-------------|
| `gt info [branch]` | Show branch details including PR number |
| `gt children` | Show child branches |
| `gt parent` | Show parent branch |
| `gt pr [branch]` | Open PR in browser |
| `gt dash` | Open Graphite dashboard |

## Collaboration

| Command | Description |
|---------|-------------|
| `gt get <branch>` | Fetch a teammate's stack locally |
| `gt track <branch>` | Start tracking an existing branch |
| `gt untrack <branch>` | Stop tracking a branch |
