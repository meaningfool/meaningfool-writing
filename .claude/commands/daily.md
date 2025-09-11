---
allowed-tools: Bash
description: Generate daily development log from GitHub commits
---

Generate a comprehensive daily development log by analyzing GitHub commits for today or a specified date.

**Usage:** `/daily [YYYY-MM-DD]`

## Phase 1: Collect GitHub Data

!.claude/scripts/fetch-commits.sh "$1"

## Phase 2: Prepare Analysis Framework  

!.claude/scripts/prepare-analysis.sh

## Phase 3: AI Analysis & Insights

Now I'll analyze the collected commit data and generate insights for each repository.

!source .daily_session && echo "Analyzing $COMMIT_COUNT commits from $TARGET_DATE"

For each repository with activity, I'll analyze the commits and update the daily log with:
- What was learned
- What went well  
- What went wrong
- Technical challenges solved
- Process improvements or setbacks

Let me process each repository and update the daily log directly:

!source .daily_session && for analysis_file in "$REPO_ANALYSIS_DIR"/*_analysis.md; do echo "Processing $(basename "$analysis_file")..."; done

Now I'll read each analysis file and generate the insights for each repository section in the daily log.