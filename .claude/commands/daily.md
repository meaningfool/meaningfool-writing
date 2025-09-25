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

Here are the items I want you to focus on for your analysis:
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


## Raw commits

!.claude/scripts/daily.sh "$1"

[Above script outputs:]
- OUTPUT_FILE=YYYY-MM-DD-daily-log.md (or numbered variant)
- TARGET_DATE=YYYY-MM-DD
- Formatted commit data

---