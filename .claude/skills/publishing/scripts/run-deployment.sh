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
            echo ""
            echo "Note: GitHub Pages may take 2-3 minutes to reflect changes."
            echo "Manually verify your content appears on the website."
            exit 0
        else
            echo ""
            echo "❌ Deployment Workflow Failed"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Workflow conclusion: $CONCLUSION"
            echo ""
            echo "Diagnosis:"
            echo "- The deployment workflow encountered an error"
            echo "- Your content was updated in the repo, but not deployed"
            echo ""
            echo "Recovery Steps:"
            echo "1. Check workflow logs for the error:"
            echo "   gh run view $DEPLOY_RUN_ID --repo meaningfool/meaningfool.github.io --log"
            echo ""
            echo "2. Common issues:"
            echo "   - Astro build failed (check for frontmatter errors)"
            echo "   - Missing images referenced in articles"
            echo "   - Deployment permissions issue"
            echo ""
            echo "3. After fixing the issue, re-run:"
            echo "   /rebuild-website"
            echo ""
            echo "4. Or check recent runs:"
            echo "   gh run list --repo meaningfool/meaningfool.github.io --limit 5"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done