#!/usr/bin/env bash

# Phase 1: Fetch GitHub commits and collect data

set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Parse arguments
TARGET_DATE=$(validate_date "$1")
read -r START_TIME END_TIME <<< "$(get_time_range "$TARGET_DATE")"

echo "Fetching commits for $TARGET_DATE..."

# Get GitHub username
USERNAME=$(get_github_username)
echo "GitHub user: $USERNAME"

# Create local data directory (avoids system temp permissions)
DATA_DIR=$(create_data_dir)
echo "DATA_DIR=$DATA_DIR" > .daily_session
COMMIT_DATA_FILE="$DATA_DIR/commits.json"
REPO_ANALYSIS_DIR="$DATA_DIR/repos"
mkdir -p "$REPO_ANALYSIS_DIR"

echo "Data directory: $DATA_DIR"

# Fetch all commits from all repos for the specified day
echo "Scanning repositories..."
gh api user/repos --paginate -q '.[].full_name' | while read -r repo; do
    # Fetch commits for this repo
    COMMITS=$(gh api "repos/$repo/commits?author=$USERNAME&since=$START_TIME&until=$END_TIME" 2>/dev/null || echo "[]")
    
    if [ "$COMMITS" != "[]" ] && [ -n "$COMMITS" ]; then
        echo "Found commits in $repo"
        
        # Create repo-specific data file
        REPO_FILE="$REPO_ANALYSIS_DIR/$(echo "$repo" | tr '/' '_').json"
        
        # Store basic commit data as JSON array
        echo "$COMMITS" | jq --arg repo "$repo" '[.[] | {repo: $repo, sha: .sha, message: .commit.message, url: .html_url, date: .commit.author.date}]' > "$REPO_FILE.commits"
        
        # For each commit, collect detailed information
        echo "$COMMITS" | jq -r '.[].sha' | while read -r sha; do
            echo "  Analyzing commit $sha..."
            
            # Get commit details including files changed
            COMMIT_DETAILS=$(gh api "repos/$repo/commits/$sha" 2>/dev/null || echo "{}")
            
            # Extract relevant data
            echo "$COMMIT_DETAILS" | jq '{
                sha: .sha,
                files: .files | map({
                    filename: .filename,
                    status: .status,
                    additions: .additions,
                    deletions: .deletions,
                    changes: .changes,
                    patch: .patch
                }),
                stats: .stats,
                commit_message: .commit.message
            }' >> "$REPO_FILE.details"
            
            # Check for CLAUDE.md or .claude changes
            echo "$COMMIT_DETAILS" | jq -r '.files[].filename' | grep -E '(CLAUDE\.md|\.claude/.*\.md)' >> "$REPO_FILE.claude_files" 2>/dev/null || true
        done
    fi
done

# Collect all commits into a single file for overview
find "$REPO_ANALYSIS_DIR" -name "*.commits" -exec cat {} \; > "$COMMIT_DATA_FILE" 2>/dev/null || echo "[]" > "$COMMIT_DATA_FILE"

# Check if we found any commits
if [ ! -s "$COMMIT_DATA_FILE" ]; then
    echo "No commits found for $TARGET_DATE"
    rm -rf "$TEMP_DIR"
    exit 0
fi

# Count total commits
COMMIT_COUNT=$(jq -s 'length' "$COMMIT_DATA_FILE")
echo "Found $COMMIT_COUNT commits total"

# Export variables for next phase
cat >> .daily_session << EOF
TARGET_DATE=$TARGET_DATE
COMMIT_COUNT=$COMMIT_COUNT
COMMIT_DATA_FILE=$COMMIT_DATA_FILE
REPO_ANALYSIS_DIR=$REPO_ANALYSIS_DIR
EOF

echo "✓ Data collection complete. Variables saved to .daily_session"