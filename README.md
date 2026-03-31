# Graphite Skill for Claude Code

A Claude Code plugin for managing [Graphite](https://graphite.dev) stacked PRs. Debug CI failures across your stack, aggregate all PR review comments, resolve restack conflicts with guided assistance, and streamline your daily Graphite workflow.

## Features

**4 workflows triggered via `/graphite`, `/gt`, or `/stack`:**

| Workflow | What it does |
|----------|--------------|
| **Debug Stack** | Checks CI status, review decisions, and blockers across all PRs in your stack. Presents a structured report with bottom-up fix recommendations. |
| **Stack Comments** | Aggregates inline code comments, review comments, and conversation from every PR in the stack. Filter by reviewer, file, or unresolved threads. |
| **Resolve Conflicts** | Guided conflict resolution during `gt restack` / `gt sync`. Auto-resolves safe patterns (imports, whitespace), asks about semantic conflicts. |
| **General Workflow** | Stack planning, creating/modifying/submitting branches, syncing, navigation, and reorganization. |

**Bonus: SessionStart hook** injects current stack context (branch, stack overview, restack status) into every new Claude Code session automatically.

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- [Graphite CLI](https://graphite.dev/docs/installing-the-cli) v1.6.7+ (`gt`)
- [GitHub CLI](https://cli.github.com/) (`gh`) - for PR comments, CI status, reviews
- A Graphite-initialized repository (`.git/.graphite_repo_config` exists)

## Installation

### As a Claude Code plugin

```bash
claude plugin add /path/to/graphite-skill
```

Or from GitHub (once published):

```bash
claude plugin add <your-username>/graphite-skill
```

### Manual installation

Copy the skill files into your project's `.claude/skills/` directory:

```bash
# From the repo root of your project
mkdir -p .claude/skills/graphite/references
cp /path/to/graphite-skill/skills/graphite/SKILL.md .claude/skills/graphite/
cp /path/to/graphite-skill/skills/graphite/references/*.md .claude/skills/graphite/references/
```

To also get the SessionStart hook (optional):

```bash
mkdir -p .claude/hooks/scripts
cp /path/to/graphite-skill/hooks/hooks.json .claude/hooks/
cp /path/to/graphite-skill/hooks/scripts/graphite-context.sh .claude/hooks/scripts/
chmod +x .claude/hooks/scripts/graphite-context.sh
```

## Usage

Start a Claude Code session in any Graphite-managed repo and use:

- `/graphite` or `/gt` or `/stack` - opens the workflow router
- `"debug my stack"` - jumps directly to the Debug Stack workflow
- `"get stack comments"` - jumps to Stack Comments
- `"resolve restack conflicts"` - jumps to Resolve Conflicts
- `"create a stack"` - jumps to General Workflow (stack planning)

### Example: Debug a failing stack

```
> /gt debug my stack

Stack Status Report:
| # | Branch              | PR   | CI      | Reviews          | Blockers        |
|---|---------------------|------|---------|------------------|-----------------|
| 1 | feat_add-api        | #201 | passing | approved         | none            |
| 2 | feat_add-hooks      | #202 | failing | pending          | CI: lint errors |
| 3 | feat_add-components | #203 | pending | changes_requested| blocked by #202 |

Recommended fix order:
1. Fix lint errors in PR #202 (feat_add-hooks) - this unblocks #203
2. Address review feedback on PR #203 after CI passes
```

### Example: Get all comments

```
> get stack comments

## PR #201: feat: add API endpoints (branch: feat_add-api)

### Inline Comments
- **router.ts:42** (@reviewer): "Add rate limiting to this endpoint"

### Review Comments
- @reviewer (APPROVED): "Looks good, minor suggestion above"

## PR #202: feat: add data hooks (branch: feat_add-hooks)
...
```

## Plugin Structure

```
graphite-skill/
  .claude-plugin/
    marketplace.json           # Marketplace metadata (required for claude plugin add)
  plugins/
    graphite/
      .claude-plugin/
        plugin.json            # Plugin metadata
      .mcp.json                # Graphite MCP server config
      hooks/
        hooks.json             # SessionStart hook registration
        scripts/
          graphite-context.sh  # Injects stack context at session start
      skills/
        graphite/
          SKILL.md             # Main skill (4 workflows, triggers)
          references/
            cheatsheet.md      # gt command quick reference
            conflict-resolution.md # Conflict resolution patterns
```

## Graphite MCP Integration

This plugin includes an `.mcp.json` that configures the Graphite MCP server (`gt mcp`). When connected, Claude Code can execute `gt` commands via `mcp__graphite__run_gt_cmd` and look up command syntax via `mcp__graphite__learn_gt`.

The skill falls back to `Bash(gt ...)` if the MCP server is unavailable.

## Customization

The skill is designed to be generic across any Graphite-managed repository. It auto-detects:
- **Trunk branch**: via `gt trunk`
- **GitHub repo**: via `gh repo view`

To customize for your project, edit `skills/graphite/SKILL.md` and add project-specific patterns (e.g., recommended stack structures for your architecture, branch naming conventions).


## License

Apache License 2.0 - see [LICENSE](LICENSE).
