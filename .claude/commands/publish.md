---
description: Publish content changes to meaningfool.github.io with frontmatter validation
argument-hint: (no arguments needed)
---

Validates frontmatter for all articles, then publishes content changes by running both workflows sequentially.

!```bash
#!/bin/bash

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
echo "🚀 Triggering content update workflow..."

# Trigger content update and capture run info
gh workflow run update-content.yml --repo meaningfool/meaningfool.github.io

# Get the latest run ID for content update
echo "⏳ Getting run ID for content update..."
sleep 5  # Brief wait for the run to appear
CONTENT_RUN_ID=$(gh run list --repo meaningfool/meaningfool.github.io --workflow="update-content.yml" --limit=1 --json databaseId --jq '.[0].databaseId')

echo "📋 Content update run ID: $CONTENT_RUN_ID"
echo "⏳ Waiting for content update to complete..."

while true; do
    RESULT=$(gh run view $CONTENT_RUN_ID --repo meaningfool/meaningfool.github.io --json status,conclusion)
    STATUS=$(echo "$RESULT" | jq -r '.status')
    CONCLUSION=$(echo "$RESULT" | jq -r '.conclusion')
    
    if [[ "$STATUS" == "completed" ]]; then
        if [[ "$CONCLUSION" == "success" ]]; then
            echo "✅ Content update completed successfully!"
            break
        else
            echo "❌ Content update workflow failed with conclusion: $CONCLUSION"
            echo "Check logs: gh run view $CONTENT_RUN_ID --repo meaningfool/meaningfool.github.io"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done

echo "🏗️ Triggering deployment workflow..."
gh workflow run deploy.yml --repo meaningfool/meaningfool.github.io

# Get the latest run ID for deployment
echo "⏳ Getting run ID for deployment..."
sleep 5
DEPLOY_RUN_ID=$(gh run list --repo meaningfool/meaningfool.github.io --workflow="deploy.yml" --limit=1 --json databaseId --jq '.[0].databaseId')

echo "📋 Deployment run ID: $DEPLOY_RUN_ID"
echo "⏳ Waiting for deployment to complete..."

while true; do
    RESULT=$(gh run view $DEPLOY_RUN_ID --repo meaningfool/meaningfool.github.io --json status,conclusion)
    STATUS=$(echo "$RESULT" | jq -r '.status')
    CONCLUSION=$(echo "$RESULT" | jq -r '.conclusion')
    
    if [[ "$STATUS" == "completed" ]]; then
        if [[ "$CONCLUSION" == "success" ]]; then
            echo "✅ Deployment completed successfully!"
            echo "🎉 Content published to https://meaningfool.github.io/"
            break
        else
            echo "❌ Deployment workflow failed with conclusion: $CONCLUSION"
            echo "Check logs: gh run view $DEPLOY_RUN_ID --repo meaningfool/meaningfool.github.io"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done

echo "🎯 Publishing complete! Both workflows succeeded."
```