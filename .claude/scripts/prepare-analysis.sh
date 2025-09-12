#!/usr/bin/env bash

# Phase 2: Prepare data for AI analysis

set -e

# Load session variables from fetch phase
# Find the most recent session file
SESSION_FILE=""
if [ -d ".daily" ]; then
    SESSION_FILE=$(find .daily -name "session.env" -type f | sort | tail -1)
fi

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
    echo "Error: Must run fetch-commits.sh first"
    exit 1
fi

source "$SESSION_FILE"

echo "Phase 2: Preparing data for AI analysis..."

# Function to get unique filename with numbering
get_unique_filename() {
    local base_name="$1"
    local counter=2
    local output_file="$base_name"
    
    while [ -f "$output_file" ]; do
        output_file="${base_name%.*} ($counter).${base_name##*.}"
        counter=$((counter + 1))
    done
    
    echo "$output_file"
}

# Create output filename (with numbering if needed)
BASE_OUTPUT_FILE="${TARGET_DATE}-daily-log.md"
OUTPUT_FILE=$(get_unique_filename "$BASE_OUTPUT_FILE")

if [ "$OUTPUT_FILE" != "$BASE_OUTPUT_FILE" ]; then
    echo "Daily log already exists, creating: $OUTPUT_FILE"
fi

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
ANALYSIS_EOF
done

# Log template ready - no additional sections needed

echo "✓ Daily log template created: $OUTPUT_FILE"
echo "✓ Analysis files prepared in: $DATA_DIR"
echo ""
echo "Analysis files ready:"
find "$REPO_ANALYSIS_DIR" -name "*_analysis.md" -exec basename {} \; | head -5

# Export final variables (quote to handle parentheses)
cat >> "$SESSION_FILE" << EOF
OUTPUT_FILE="$OUTPUT_FILE"
EOF