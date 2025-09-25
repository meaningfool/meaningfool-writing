#!/usr/bin/env bash

set -euo pipefail

# Daily Development Log Generator
# Simplified single-script implementation

# Function: validate_date
# Input: date argument (empty, "yesterday", "-3", "2025-09-11", etc.)
# Output: YYYY-MM-DD format
validate_date() {
    local input="${1:-}"

    if [[ -z "$input" ]]; then
        # Empty input defaults to today
        date "+%Y-%m-%d"
    elif [[ "$input" == "yesterday" ]]; then
        # Handle "yesterday" keyword
        # Try macOS date format first, then GNU date format
        date -v-1d "+%Y-%m-%d" 2>/dev/null || date -d "yesterday" "+%Y-%m-%d"
    elif [[ "$input" =~ ^-[0-9]+$ ]]; then
        # Handle relative dates like -3 (3 days ago)
        local days="${input#-}"
        date -v-${days}d "+%Y-%m-%d" 2>/dev/null || date -d "${days} days ago" "+%Y-%m-%d"
    elif [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Handle YYYY-MM-DD format
        # Validate it's a real date
        if date -j -f "%Y-%m-%d" "$input" "+%Y-%m-%d" &>/dev/null 2>&1 || date -d "$input" "+%Y-%m-%d" &>/dev/null 2>&1; then
            echo "$input"
        else
            echo "ERROR: Invalid date: $input" >&2
            return 1
        fi
    else
        echo "ERROR: Unsupported date format: $input" >&2
        echo "Supported formats: empty (today), 'yesterday', '-N' (N days ago), 'YYYY-MM-DD'" >&2
        return 1
    fi
}

# Function: get_time_range
# Input: validated date in YYYY-MM-DD
# Output: START_TIME and END_TIME in ISO format with local timezone
get_time_range() {
    local target_date="$1"

    # Get timezone offset
    local tz_offset=$(date "+%z" | sed 's/^\([+-][0-9][0-9]\)\([0-9][0-9]\)$/\1:\2/')

    # Calculate start time (00:00:00) in local timezone
    local start_time="${target_date}T00:00:00${tz_offset}"

    # Calculate end time (23:59:59) in local timezone
    local end_time="${target_date}T23:59:59${tz_offset}"

    echo "START_TIME=$start_time"
    echo "END_TIME=$end_time"
}

# Function: check_output_file
# Input: target date YYYY-MM-DD
# Output: available filename
check_output_file() {
    local target_date="$1"
    local base_filename="daily-logs/${target_date}-daily-log.md"

    # Check if base file exists
    if [[ ! -f "$base_filename" ]]; then
        echo "$base_filename"
        return
    fi

    # Find the next available numbered variant
    local counter=2
    local output_file="daily-logs/${target_date}-daily-log(${counter}).md"

    while [[ -f "$output_file" ]]; do
        ((counter++))
        output_file="daily-logs/${target_date}-daily-log(${counter}).md"
    done

    echo "$output_file"
}

# Function: fetch_commits
# Input: target_date, start_time, end_time
# Output: formatted commit data
fetch_commits() {
    local target_date="$1"
    local start_time="$2"
    local end_time="$3"

    echo "=== COMMIT DATA ===" >&2
    echo "Fetching commits for $target_date..." >&2
    echo "" >&2

    # Get current GitHub username
    local username=$(gh api user --jq '.login' 2>/dev/null)
    if [[ -z "$username" ]]; then
        echo "ERROR: Unable to get GitHub username" >&2
        return 1
    fi

    echo "Searching for commits by $username on $target_date..." >&2

    # Use GitHub Search API to find commits by author on target date
    local search_query="author:${username} committer-date:${target_date}"

    # Search for commits using GitHub API
    local search_results=$(gh api search/commits \
        --method GET \
        -f q="$search_query" \
        --jq '.items[] | {sha: .sha, message: (.commit.message | split("\n")[0]), repository: .repository.full_name}' \
        2>&1)

    local api_exit_code=$?

    if [[ $api_exit_code -ne 0 ]]; then
        if echo "$search_results" | grep -q "rate limit"; then
            echo "ERROR: GitHub API rate limit exceeded. Please try again later." >&2
        elif echo "$search_results" | grep -q "403"; then
            echo "ERROR: GitHub API access forbidden. Check your authentication." >&2
        elif echo "$search_results" | grep -q "404"; then
            echo "ERROR: GitHub API endpoint not found. The search/commits API may not be available." >&2
        else
            echo "ERROR: Failed to search commits: $search_results" >&2
        fi
        return 1
    fi

    if [[ -z "$search_results" ]]; then
        echo "No commits found for $username on $target_date" >&2
        return 0
    fi

    echo "Processing search results..." >&2
    echo "" >&2

    # Group commits by repository using temporary files instead of associative arrays
    local temp_dir=$(mktemp -d)

    while IFS= read -r commit_json; do
        if [[ -n "$commit_json" ]]; then
            local repo=$(echo "$commit_json" | jq -r '.repository')
            local sha=$(echo "$commit_json" | jq -r '.sha')
            local message=$(echo "$commit_json" | jq -r '.message')

            # Create/append to repo-specific file
            local repo_file="$temp_dir/$(echo "$repo" | tr '/' '_')"
            echo "$sha|$message" >> "$repo_file"
        fi
    done <<< "$search_results"

    echo "Extracting commit details and files..." >&2

    # Extract and output commit data with file lists
    for repo_file in "$temp_dir"/*; do
        if [[ -f "$repo_file" ]]; then
            local repo=$(basename "$repo_file" | tr '_' '/')

            while IFS= read -r commit_line; do
                if [[ -n "$commit_line" ]]; then
                    local sha=$(echo "$commit_line" | cut -d'|' -f1)
                    local message=$(echo "$commit_line" | cut -d'|' -f2-)

                    # Fetch files changed in this commit
                    local files_result=$(gh api "repos/$repo/commits/$sha" \
                        --jq '.files[].filename' 2>&1)

                    local files=""
                    if [[ $? -eq 0 ]]; then
                        files=$(echo "$files_result" | tr '\n' ', ' | sed 's/,$//')
                    else
                        echo "Warning: Could not fetch file list for commit $sha" >&2
                    fi

                    echo "Repository: $repo"
                    echo "Commit: [$sha] $message"
                    if [[ -n "$files" ]]; then
                        echo "Files: $files"
                    fi
                    echo ""
                fi
            done < "$repo_file"
        fi
    done

    # Clean up temporary directory
    rm -rf "$temp_dir"

    echo "Commit extraction completed." >&2
}

# Main function
main() {
    local date_arg="${1:-}"

    echo "Daily Development Log Generator" >&2
    echo "==============================" >&2
    echo "" >&2

    # Step 1: Validate date and handle errors
    echo "Validating date argument: '$date_arg'" >&2

    local target_date
    if ! target_date=$(validate_date "$date_arg"); then
        echo "FATAL: Date validation failed" >&2
        exit 1
    fi

    echo "Target date: $target_date" >&2
    echo "" >&2

    # Step 2: Get time range boundaries
    echo "Getting time range for $target_date..." >&2

    local time_range
    time_range=$(get_time_range "$target_date")

    local start_time=$(echo "$time_range" | grep "START_TIME=" | cut -d'=' -f2)
    local end_time=$(echo "$time_range" | grep "END_TIME=" | cut -d'=' -f2)

    echo "Time range: $start_time to $end_time" >&2
    echo "" >&2

    # Step 3: Get output filename
    echo "Checking output file availability..." >&2

    local output_file
    output_file=$(check_output_file "$target_date")

    echo "Output file: $output_file" >&2
    echo "" >&2

    # Step 4: Fetch commits and prepare output for Claude
    echo "Fetching commits..." >&2

    local commit_data
    commit_data=$(fetch_commits "$target_date" "$start_time" "$end_time")

    echo "=== DATA FOR CLAUDE ===" >&2
    echo "" >&2

    # Output metadata and commit data for Claude to process
    echo "OUTPUT_FILE=$output_file"
    echo "TARGET_DATE=$target_date"
    echo ""
    echo "$commit_data"
}

# Execute main function with all arguments
main "$@"