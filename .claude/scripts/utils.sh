#!/usr/bin/env bash

# Shared utilities for daily command scripts

# Validate and normalize date format
validate_date() {
    local date_arg="$1"
    
    if [ -z "$date_arg" ]; then
        # Default to today (UTC)
        date -u +%Y-%m-%d
    else
        # Validate provided date format
        if ! [[ "$date_arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "Error: Date must be in YYYY-MM-DD format" >&2
            exit 1
        fi
        echo "$date_arg"
    fi
}

# Calculate ISO timestamps for a given date
get_time_range() {
    local target_date="$1"
    echo "${target_date}T00:00:00Z" "${target_date}T23:59:59Z"
}

# Get GitHub username
get_github_username() {
    gh api user -q .login
}

# Create local data directory for collection (avoids system temp permissions)
create_data_dir() {
    local data_dir=".daily/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$data_dir"
    echo "$data_dir"
}