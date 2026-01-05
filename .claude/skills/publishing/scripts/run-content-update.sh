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
            echo "✅ Content update workflow completed successfully!"

            # Verify submodule was actually updated
            echo "🔍 Verifying submodule commit..."
            EXPECTED_COMMIT=$(git rev-parse HEAD)
            SUBMODULE_COMMIT=$(gh api repos/meaningfool/meaningfool.github.io/contents/src/content/writing --jq '.sha')

            if [[ "$EXPECTED_COMMIT" == "$SUBMODULE_COMMIT" ]]; then
                echo "✅ Submodule verified: points to latest commit"
                exit 0
            else
                echo ""
                echo "❌ Verification Failed: Submodule Update"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "Content update workflow succeeded ✅"
                echo "But submodule wasn't updated to latest commit ❌"
                echo ""
                echo "Expected commit: $EXPECTED_COMMIT"
                echo "Submodule points to: $SUBMODULE_COMMIT"
                echo ""
                echo "Diagnosis:"
                echo "- Workflow ran but submodule reference wasn't updated"
                echo "- This can happen if the workflow had issues updating the submodule"
                echo ""
                echo "Recovery Steps:"
                echo "1. Re-run deployment: /rebuild-website"
                echo "   (This will try updating the submodule again)"
                echo ""
                echo "2. Check workflow logs for errors:"
                echo "   gh run view $CONTENT_RUN_ID --repo meaningfool/meaningfool.github.io --log"
                echo ""
                echo "Your content is safe in git. Re-running should fix this."
                exit 1
            fi
        else
            echo ""
            echo "❌ Content Update Workflow Failed"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Workflow conclusion: $CONCLUSION"
            echo ""
            echo "Diagnosis:"
            echo "- The GitHub Actions workflow encountered an error"
            echo ""
            echo "Recovery Steps:"
            echo "1. Check workflow logs for the error:"
            echo "   gh run view $CONTENT_RUN_ID --repo meaningfool/meaningfool.github.io --log"
            echo ""
            echo "2. Common issues:"
            echo "   - Submodule update failed"
            echo "   - GitHub Actions permissions issue"
            echo "   - Network/API error"
            echo ""
            echo "3. After fixing the issue, re-run:"
            echo "   /rebuild-website"
            exit 1
        fi
    fi
    echo "   Still running... (checking again in 10s)"
    sleep 10
done