# Specification: Refactored Daily Command

## Overview
Simplify the `/daily` command to generate development logs by fetching GitHub commits for a specified date and having Claude analyze them for insights.

## Requirements

### Input
- Date parameter that can take forms:
  - Empty (defaults to today)
  - `yesterday`
  - `-N` (N days ago, e.g., `-3`)
  - `YYYY-MM-DD` (specific date)

### Output
- Creates a file in root directory: `YYYY-MM-DD-daily-log.md`
- If file exists, creates numbered versions: `YYYY-MM-DD-daily-log(2).md`, `YYYY-MM-DD-daily-log(3).md`, etc.
- File contains Claude's analysis of the day's commits

### Core Functionality
1. Validate date parameter
2. Check for existing output file and determine filename
3. Fetch all commits from all repos for TARGET_DATE (local timezone)
4. Pass commit data to Claude for analysis
5. Claude writes insights to output file

## Architecture

### Single Script Approach
- One script file: `.claude/scripts/daily.sh`
- Contains functions that can be called internally
- Single execution outputs all data needed for Claude

### Script Structure (`daily.sh`)

```bash
#!/usr/bin/env bash

validate_date() {
    # Input: date argument (empty, "yesterday", "-3", "2025-09-11", etc.)
    # Output: YYYY-MM-DD format
    # Uses local timezone
}

get_time_range() {
    # Input: validated date in YYYY-MM-DD
    # Output: START_TIME and END_TIME in ISO format with local timezone
    # Example: 2025-09-25T00:00:00-07:00 2025-09-25T23:59:59-07:00
}

check_output_file() {
    # Input: target date YYYY-MM-DD
    # Output: available filename
    # Logic: Check for existing files, find highest (N), return next available
    # Examples:
    #   - No file exists → 2025-09-25-daily-log.md
    #   - File exists → 2025-09-25-daily-log(2).md
    #   - (2) exists → 2025-09-25-daily-log(3).md
}

fetch_commits() {
    # Input: target_date, start_time, end_time
    # Output: formatted commit data
    # Uses: gh api to fetch commits from all repos with activity
    # Filters: only repos with commits on target date
    # Format:
    #   Repository: user/repo-name
    #   Commit: [sha] commit message
    #   Files: file1.js, file2.md
    #   [blank line between repos]
}

main() {
    # Orchestrates all functions
    # Outputs metadata and commit data for Claude
}
```

### Command File (`daily.md`)

```markdown
---
allowed-tools: Write
description: Generate daily development log from GitHub commits
---

# Daily Development Log Generation

!.claude/scripts/daily.sh "$1"

[Above script outputs:]
- OUTPUT_FILE=YYYY-MM-DD-daily-log.md (or numbered variant)
- TARGET_DATE=YYYY-MM-DD
- Formatted commit data

---

## Analysis Instructions

For each repository with activity, I'll analyze the data and extract from the data meaningful signals focusing on:
- **Technical challenges solved** - what specific problems were encountered, how they were debugged, and what solutions were implemented. For this look specifically at code file diffs and at changes in plans that are reflected in .md files.
- **New technologies, specific findings about how their idiosyncracies** - trials and mistakes lead, and research, lead to discoveries about why things won't work or work only in certain ways. This is useful knowledge that we want to surface. For that look in particular at .md files which un packs our thinking, our plans, what we tried, and our research.
- **AI process improvements or setbacks** - the AI-assisted development process is harnessed using .md files. Some of them contain general instructions (claude.md), some capture automation processes (in .claude). And some others (those that contains plans, or logs of what happened for example) support the AI-assisted development process to store short-term memories mostly and keep track of what was done and what needs to be done. For these last ones, it's not so much the exact content than how they are used to support the development process that is interesting. So analyze all those files to identify if and how we changed the process.

Each extracted item is formatted a new bullet point. And for each extracted item provide some details in the form of up to 3 sub-bullet points each of one sentence maximum.

It should look like so:
- **Item title A**:
  - Description sentence 1
  - Description sentence 2
- **Item title B**:
  - Description sentence 1
  - Description sentence 2
  - Description sentence 3
- An so on...

[Claude processes commits and writes analysis to OUTPUT_FILE]
```

## Data Flow

1. User runs `/daily` or `/daily yesterday` or `/daily -3` etc.
2. `daily.sh` executes with the argument
3. Script validates date → determines time range → checks output file → fetches commits
4. All data outputs to stdout and becomes part of Claude's prompt
5. Claude analyzes commits according to instructions
6. Claude writes formatted analysis to the output file

## Key Differences from Current Implementation

### Removed
- Multiple script files (fetch-commits.sh, prepare-analysis.sh, utils.sh)
- Session files and environment variables
- Intermediate data storage in `.daily/` directory
- Caching and data reuse logic
- Complex phase-based execution
- File patches and detailed diffs (keeping just commit messages and file names)

### Simplified
- Single script execution
- No intermediate files
- Direct output to Claude's context
- Local timezone instead of UTC
- Straightforward file numbering for duplicates

## Implementation Notes

- Use GitHub CLI (`gh`) for API calls
- Handle rate limiting gracefully
- Include only repos with commits on target date
- Keep output format simple and parseable
- Error handling for invalid dates or API failures