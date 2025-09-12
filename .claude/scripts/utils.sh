#!/usr/bin/env bash

# Shared utilities for daily command scripts

# Validate and normalize date format
validate_date() {
    local date_arg="$1"
    
    if [ -z "$date_arg" ]; then
        # Default to today (UTC)
        date -u +%Y-%m-%d
    elif [ "$date_arg" = "yesterday" ]; then
        # Yesterday's date
        date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u --date="1 day ago" +%Y-%m-%d
    elif [[ "$date_arg" =~ ^-[0-9]+$ ]]; then
        # Handle -1, -2, -3 format (days ago)
        local days_ago="${date_arg#-}"
        date -u -v-${days_ago}d +%Y-%m-%d 2>/dev/null || date -u --date="${days_ago} days ago" +%Y-%m-%d
    elif [[ "$date_arg" =~ ^[0-9]+\ days?\ ago$ ]]; then
        # Handle "N days ago" format
        local days=$(echo "$date_arg" | grep -o '^[0-9]\+')
        date -u -v-${days}d +%Y-%m-%d 2>/dev/null || date -u --date="${days} days ago" +%Y-%m-%d
    elif [[ "$date_arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Standard YYYY-MM-DD format
        echo "$date_arg"
    else
        echo "Error: Invalid date format. Use: YYYY-MM-DD, 'yesterday', '-N', or 'N days ago'" >&2
        exit 1
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
    local target_date="$1"
    local run_timestamp="$(date +%Y%m%d_%H%M%S)"
    local data_dir=".daily/target-${target_date}_run-${run_timestamp}"
    mkdir -p "$data_dir"
    echo "$data_dir"
}

# Check if existing data should be reused or collection should be re-run
check_existing_data() {
    local target_date="$1"
    local current_date=$(date -u +%Y-%m-%d)
    local current_hour=$(date -u +%H)
    
    # Find existing data for target_date - look for directories with target-DATE pattern
    local existing_data_dir=""
    if [ -d ".daily" ]; then
        for dir in .daily/target-${target_date}_run-*/; do
            [ -d "$dir" ] || continue
            existing_data_dir="$dir"
            break
        done
    fi
    
    if [ -z "$existing_data_dir" ]; then
        echo "No existing data for $target_date - running collection" >&2
        return 1  # Run collection
    fi
    
    # Extract last run timestamp from directory name
    local timestamp=$(basename "$existing_data_dir" | grep -o '[0-9]*_[0-9]*')
    local last_run_date=${timestamp%_*}
    local last_run_time=${timestamp#*_}
    local last_run_hour=${last_run_time:0:2}
    
    # Compare dates (convert to epoch for reliable comparison)
    local target_epoch=$(date -d "$target_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$target_date" +%s)
    local current_epoch=$(date -d "$current_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$current_date" +%s)
    
    if [ "$target_epoch" -lt "$current_epoch" ]; then
        # Target date is in the past
        echo "Target date $target_date is in the past - reusing existing data from $existing_data_dir" >&2
        echo "$existing_data_dir"
        return 0  # Reuse existing
    elif [ "$target_epoch" -eq "$current_epoch" ]; then
        # Target date is today
        if [ "$current_hour" -gt "$last_run_hour" ]; then
            echo "Target date is today and time has passed since last run ($last_run_hour:xx) - checking for new commits" >&2
            return 1  # Run collection
        else
            echo "Target date is today but no significant time has passed - reusing existing data from $existing_data_dir" >&2
            echo "$existing_data_dir"
            return 0  # Reuse existing
        fi
    else
        # Target date is in the future
        echo "Target date $target_date is in the future - running collection" >&2
        return 1  # Run collection
    fi
}