#!/bin/bash
# SessionStart hook: inject Graphite context if in a Graphite-enabled repo

set -euo pipefail

# Check if we're in a git repo with Graphite initialized
if [ ! -f ".git/.graphite_repo_config" ]; then
  exit 0
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Get compact stack view
STACK_VIEW=$(gt log short 2>/dev/null || echo "Unable to fetch stack")

# Check if any branches need restacking
NEEDS_RESTACK=""
if echo "$STACK_VIEW" | grep -qi "needs restack" 2>/dev/null; then
  NEEDS_RESTACK="Yes - some branches need restacking. Run \`gt sync\` or \`gt restack\`."
else
  NEEDS_RESTACK="No"
fi

cat << EOF
This repo uses Graphite CLI for stacked PRs.

**Current branch**: \`${CURRENT_BRANCH}\`
**Needs restack**: ${NEEDS_RESTACK}

**Use \`gt\` commands instead of \`git\` for commits and branches:**
- \`gt create -am "msg"\` instead of \`git commit\` (creates new branch/PR)
- \`gt modify -a\` instead of \`git commit --amend\` (amends current PR)
- \`gt submit --no-interactive\` instead of \`git push\` (submits stack)
- \`gt sync\` instead of \`git pull\` (pulls trunk, restacks, cleans merged)

**Stack overview:**
\`\`\`
${STACK_VIEW}
\`\`\`

Use \`/graphite\`, \`/gt\`, or \`/stack\` for full stack management workflows.
EOF
