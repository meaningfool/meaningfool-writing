---
allowed-tools: Bash
description: Generate daily development log from GitHub commits
---

Generate a comprehensive daily development log by analyzing GitHub commits for today or a specified date.

**Usage:** 
- `/daily` - today's commits
- `/daily yesterday` - yesterday's commits
- `/daily -1` - yesterday (1 day ago)
- `/daily -3` - 3 days ago
- `/daily 2025-09-11` - specific date

## Phase 1: Collect GitHub Data

!.claude/scripts/fetch-commits.sh "$1"

## Phase 2: Prepare Analysis Framework  

# Extract the target date from the session file created by fetch-commits
!SESSION_FILE=$(find .daily -name "session.env" -type f | sort | tail -1) && source "$SESSION_FILE" && .claude/scripts/prepare-analysis.sh "$TARGET_DATE"

## Phase 3: AI Analysis & Insights

Now I'll analyze the collected commit data and generate insights for each repository.

!SESSION_FILE=$(find .daily -name "session.env" -type f | sort | tail -1) && source "$SESSION_FILE" && echo "Analyzing $COMMIT_COUNT commits from $TARGET_DATE"

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

Let me read each repository's data file and update the daily log with insights:

!SESSION_FILE=$(find .daily -name "session.env" -type f | sort | tail -1) && source "$SESSION_FILE" && for analysis_file in "$REPO_ANALYSIS_DIR"/*_analysis.md; do echo "Processing $(basename "$analysis_file")..."; done

Now I'll read each analysis file, extract the key learnings, and update the corresponding repository section in the daily log with bullet point insights.