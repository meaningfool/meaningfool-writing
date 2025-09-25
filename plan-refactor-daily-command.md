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

### 4. Implement check_output_file function
- [ ] Check if base filename exists (YYYY-MM-DD-daily-log.md)
- [ ] Find highest numbered variant if file exists
- [ ] Return next available filename with proper numbering
- [ ] Test check_output_file with no existing file
- [ ] Test check_output_file with one existing file
- [ ] Test check_output_file with multiple numbered files

### 5. Implement fetch_commits function
- [ ] List all repositories with activity on target date
- [ ] Fetch commits for each repository in date range
- [ ] Extract commit SHA, message, and file list
- [ ] Format output with proper spacing and structure
- [ ] Add error handling for API failures and rate limits
- [ ] Test fetch_commits with date having multiple repos
- [ ] Test fetch_commits with date having no commits
- [ ] Test fetch_commits API error handling

### 6. Implement main orchestration function
- [ ] Parse command line arguments
- [ ] Call validate_date and handle errors
- [ ] Call get_time_range to get boundaries
- [ ] Call check_output_file to get filename
- [ ] Call fetch_commits and output metadata
- [ ] Output all data in format for Claude
- [ ] Test main function with various arguments

### 7. Create daily.md command file
- [ ] Set allowed-tools to Write only
- [ ] Add script execution directive
- [ ] Add Claude analysis instructions from spec
- [ ] Test command file with Claude

### 8. Integration testing
- [ ] Test /daily with no arguments (today)
- [ ] Test /daily yesterday
- [ ] Test /daily -3 (3 days ago)
- [ ] Test /daily 2025-09-20 (specific date)
- [ ] Test file numbering by running command twice

### 9. Documentation and cleanup
- [ ] Update CLAUDE.md with new daily command info
- [ ] Verify all old artifacts are removed
- [ ] Final test of complete workflow

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