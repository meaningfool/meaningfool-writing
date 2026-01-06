#!/bin/bash

# Exit on error
set -e

echo "🔍 Checking for uncommitted changes in articles/..."

# Check if there are any changes in articles/ (both staged and unstaged)
if git diff --quiet articles/ && git diff --cached --quiet articles/ && ! git ls-files --others --exclude-standard articles/ | grep -q .; then
  echo "✓ No uncommitted changes in articles/"
  exit 0
fi

echo "📝 Found uncommitted changes in articles/"
echo ""

# Show what will be committed
echo "Changes to be committed:"
git status --short articles/
echo ""

# Stage all changes (modifications, deletions, and new files)
git add articles/

# Create commit message
COMMIT_MSG="Update articles

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Commit
echo "💾 Committing changes..."
git commit -m "$COMMIT_MSG"

# Push
echo "🚀 Pushing to remote..."
git push

echo "✅ Article changes committed and pushed successfully"
