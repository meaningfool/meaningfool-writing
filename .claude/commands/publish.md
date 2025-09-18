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

# Run content update workflow
.claude/scripts/run-content-update.sh

# Run deployment workflow
.claude/scripts/run-deployment.sh

echo "🎯 Publishing complete! Both workflows succeeded."
```