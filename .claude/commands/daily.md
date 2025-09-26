---
description: Generate daily development log from GitHub commits
allowed-tools: Write, Bash(.claude/scripts/daily.sh:*)
---

# Daily Development Log Generation

## Instructions

Your role is to output a daily analysis of my commits on Github. To do so:
1- Use the Write tool to create a file with the path OUTPUT_FILE
2- Add the frontmatter with the key-values:
title: "Activity Log - TARGET_DATE" (replace TARGET_DATE by its value provided below)
date: TARGET_DATE
3- Add an "ANALYSIS" section with the result of your analysis below
4- Add a "RAW COMMITS" section with the exact list of commits provided in the RAW COMMITS section below

## Analysis

The analysis' goal is to surface:
- **Why we did things** rather than what was done. So focus on the intent. This intent can play over multiple commits, so paying specific attention to the spec files and the plan files can help understand the underlying reason to do things. For each overarching challenge that we tackled: 
  - Make it a single item
  - Report on lower level challenges of interest. Specifically report  on the decisions that were made if there were multiple options, and if there is research that has been logged in the commits.
- **What we learned** if there were some important learning items, ones that had some level of intricacies and required some research, summarize what was learnt.
- **AI process improvements or setbacks** - the AI-assisted development process is harnessed using claude.md files. Document changes to this file that indicate a new policy or some instruction regarding a specific problem. But ignore changes that are documenting things that you already reported upon in the challenges we tackled.

The report being about the daily activity is likely to be 1 to 10 items. And 0 sometimes. Ignore changes that are just content changes, or those for which there is no clear intent.

It should look like so:
- **Item title A**:
  - Details: sentence 1
  - Details: sentence 2
- **Item title B**:
  - Details: sentence 1
  - Details: sentence 2
  - Details: sentence 3
- An so on...


## Raw commits

!.claude/scripts/daily.sh "$1"

[Above script outputs:]
- OUTPUT_FILE=YYYY-MM-DD-daily-log.md (or numbered variant)
- TARGET_DATE=YYYY-MM-DD
- Formatted commit data

---