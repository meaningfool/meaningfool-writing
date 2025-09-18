#!/bin/bash

# Complete publishing pipeline script
# This script orchestrates the entire publish workflow

# Run frontmatter validation using our dedicated script
echo "🔍 Running frontmatter validation..."
if ! .claude/scripts/frontmatter-validation.sh; then
    echo ""
    echo "Please fix the frontmatter issues above before publishing."
    echo "Example frontmatter:"
    echo "---"
    echo "title: \"Your Article Title\""
    echo "date: $(date +%Y-%m-%d)"
    echo "tags: [\"optional\", \"tags\"]"
    echo "---"
    exit 1
fi

echo "✅ All articles have valid frontmatter!"
echo ""

# Run content update workflow
.claude/scripts/run-content-update.sh
if [ $? -ne 0 ]; then
    echo "❌ Content update failed. Aborting publish."
    exit 1
fi

# Run deployment workflow
.claude/scripts/run-deployment.sh
if [ $? -ne 0 ]; then
    echo "❌ Deployment failed. Content was updated but not deployed."
    exit 1
fi

echo "🎯 Publishing complete! Both workflows succeeded."