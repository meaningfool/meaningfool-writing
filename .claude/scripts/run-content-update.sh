#!/bin/bash
echo "🚀 Triggering content update workflow..."
gh workflow run update-content.yml --repo meaningfool/meaningfool.github.io

echo "⏳ Getting run ID for content update..."
sleep 5
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
            exit 0
        else
            echo "❌ Content update workflow failed with conclusion: $CONCLUSION"
            echo "Check logs: gh run view $CONTENT_RUN_ID --repo meaningfool/meaningfool.github.io"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done