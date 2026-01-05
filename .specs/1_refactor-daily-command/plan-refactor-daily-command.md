# Plan: Refactor Daily Command

## Overview
Refactor the `/daily` command from a complex multi-script system to a single, streamlined script that generates development logs by fetching and analyzing GitHub commits.

## Todo List

### 1. Clean up old implementation ✓
- [x] Remove old script files (fetch-commits.sh, prepare-analysis.sh, utils.sh)
- [x] Remove old daily.md command file
- [x] Clean up .daily working directory

### 2. Create script structure and validate_date function ✓
- [x] Create daily.sh with basic structure and function stubs
- [x] Implement validate_date for empty input (default to today)
- [x] Implement validate_date for 'yesterday' keyword
- [x] Implement validate_date for relative dates (-N format)
- [x] Implement validate_date for YYYY-MM-DD format
- [x] Add error handling for invalid date formats
- [x] Test validate_date with all input types

### 3. Implement get_time_range function ✓
- [x] Calculate start time (00:00:00) in local timezone
- [x] Calculate end time (23:59:59) in local timezone
- [x] Format times in ISO format with timezone offset
- [x] Test get_time_range with different dates and timezones

### 4. Implement check_output_file function ✓
- [x] Check if base filename exists (YYYY-MM-DD-daily-log.md)
- [x] Find highest numbered variant if file exists
- [x] Return next available filename with proper numbering
- [x] Test check_output_file with no existing file
- [x] Test check_output_file with one existing file
- [x] Test check_output_file with multiple numbered files

### 5. Implement fetch_commits function ✓
- [x] Use GitHub Search API to find all commits on target date
- [x] Group commits by repository from search results
- [x] Extract commit SHA, message, and file list for each commit
- [x] Format output with proper spacing and structure
- [x] Add error handling for API failures and rate limits
- [x] Test fetch_commits with date having multiple repos
- [x] Test fetch_commits with date having no commits
- [x] Test fetch_commits API error handling

### 6. Implement main orchestration function ✓
- [x] Parse command line arguments
- [x] Call validate_date and handle errors
- [x] Call get_time_range to get boundaries
- [x] Call check_output_file to get filename
- [x] Call fetch_commits and output metadata
- [x] Output all data in format for Claude
- [x] Test main function with various arguments

### 7. Create daily.md command file ✓
- [x] Set allowed-tools to Write only
- [x] Add script execution directive
- [x] Add Claude analysis instructions from spec
- [x] Test command file with Claude

### 8. Integration testing ✓
- [x] Test /daily with no arguments (today)
- [x] Test /daily yesterday
- [x] Test /daily -3 (3 days ago)
- [x] Test /daily 2025-09-20 (specific date)
- [x] Test file numbering by running command twice

### 9. Documentation and cleanup ✓
- [x] Update CLAUDE.md with new daily command info
- [x] Verify all old artifacts are removed
- [x] Final test of complete workflow

## Implementation Notes

### Key Changes from Current Implementation
- **Single script** instead of multiple scripts (fetch-commits.sh, prepare-analysis.sh, utils.sh)
- **No intermediate files** - data flows directly from script to Claude
- **No caching** - fresh execution every time
- **Local timezone** instead of UTC for more intuitive date handling
- **Simplified file naming** - automatic numbering for duplicates
- **Direct output** - script outputs all data for Claude in one execution

### Technical Details
- Use GitHub CLI (`gh`) for all API calls
- Handle rate limiting gracefully with error messages
- Output format optimized for Claude's analysis
- All functions contained in single `daily.sh` file
- Command file (`daily.md`) contains Claude's analysis instructions

### Expected Outcomes
- Simpler, more maintainable codebase
- Faster execution (no intermediate file I/O)
- Easier debugging (single script to troubleshoot)
- More reliable (fewer moving parts)
- Better user experience (clearer error messages)