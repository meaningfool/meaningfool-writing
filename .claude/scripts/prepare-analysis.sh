#!/usr/bin/env bash

# Phase 2: Prepare data for AI analysis

set -e

# Load session variables from fetch phase
if [ ! -f .daily_session ]; then
    echo "Error: Must run fetch-commits.sh first"
    exit 1
fi

source .daily_session

echo "Phase 2: Preparing data for AI analysis..."

# Create output filename
OUTPUT_FILE="${TARGET_DATE}-daily-log.md"

# Start with simple structure - just repository headers
cat > "$OUTPUT_FILE" << EOF
# Daily Development Log - $TARGET_DATE

EOF

# For each repository, prepare analysis data
for repo_file in "$REPO_ANALYSIS_DIR"/*.commits; do
    [ -f "$repo_file" ] || continue
    
    REPO_NAME=$(basename "$repo_file" .commits | tr '_' '/')
    REPO_COMMIT_COUNT=$(jq 'length' "$repo_file")
    
    echo "## $REPO_NAME" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "*Analysis will be added here by Claude*" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Create analysis file for Claude to process
    COMMITS=$(cat "$repo_file")
    DETAILS=$(cat "${repo_file%.commits}.details" 2>/dev/null || echo "[]")
    CLAUDE_FILES=$(cat "${repo_file%.commits}.claude_files" 2>/dev/null || echo "")
    
    ANALYSIS_FILE="$REPO_ANALYSIS_DIR/${REPO_NAME//\//_}_analysis.md"
    cat > "$ANALYSIS_FILE" << ANALYSIS_EOF
**REPOSITORY:** $REPO_NAME ($REPO_COMMIT_COUNT commits on $TARGET_DATE)

**COMMIT DATA:**
\`\`\`json
$COMMITS
\`\`\`

**DETAILED CHANGES:**
\`\`\`json
$DETAILS
\`\`\`

**CLAUDE.md/.claude FILES:**
\`\`\`
$CLAUDE_FILES
\`\`\`

**ANALYSIS TASK:**
Generate 3-5 concise bullet points about what was learned, what went well, and what went wrong in this repository today. Focus on:
- Technical challenges solved
- Learning moments and insights
- Process improvements or setbacks
- Evolution of approach across commits
- Changes to documentation/tooling (CLAUDE.md/.claude files)

Format as simple bullet points, use sub-bullets only if needed for clarity.
ANALYSIS_EOF
done

# Log template ready - no additional sections needed

echo "✓ Daily log template created: $OUTPUT_FILE"
echo "✓ Analysis files prepared in: $DATA_DIR"
echo ""
echo "Analysis files ready:"
find "$REPO_ANALYSIS_DIR" -name "*_analysis.md" -exec basename {} \; | head -5

# Export final variables
cat >> .daily_session << EOF
OUTPUT_FILE=$OUTPUT_FILE
EOF