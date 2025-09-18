#!/bin/bash
echo "🏗️ Triggering deployment workflow..."
gh workflow run deploy.yml --repo meaningfool/meaningfool.github.io

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
            exit 0
        else
            echo "❌ Deployment workflow failed with conclusion: $CONCLUSION"
            echo "Check logs: gh run view $DEPLOY_RUN_ID --repo meaningfool/meaningfool.github.io"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done