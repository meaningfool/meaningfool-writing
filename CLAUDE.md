# CLAUDE.md - meaningfool-writing Repository

This file provides guidance to Claude Code when working with content in the `meaningfool-writing` repository.

## Architecture Overview

This repository (`meaningfool-writing`) is a **content-only repository** that serves as a Git submodule for the main website `meaningfool.github.io`.

### Repository Relationship

```
meaningfool.github.io (Main Site Repository)
└── src/content/writing/ → [Git Submodule] → meaningfool-writing (This Repository)
```

**Key Points:**
- This repository's purpose is to store and edit content. It mostly contains **only Markdown articles**.
- Some of these articles (located in specific folders - see below) are the content of the main site that pulls that content from here via Git submodule mechanism
- Changes here do NOT automatically deploy to the website
- Manual publishing step required to update the live site

## Content Structure

**CRITICAL**: Every article MUST have proper frontmatter or the build will fail. Articles requiring frontmatter are located in visible folders (like `articles/` or `daily-logs/`). Files at the root or in hidden folders (starting with `.`) do not need frontmatter.

### Required Frontmatter Template

**Always use this exact template for new articles:**

```markdown
---
title: "Your Article Title Here"
date: 2025-09-11
tags: ["tag1", "tag2"]
---

Your article content goes here...
```

### Frontmatter Rules

**Required Fields:**
- `title`: String - The article title (must be quoted)
- `date`: Date - Format as YYYY-MM-DD (no quotes)

**Optional Fields:**
- `tags`: Array - List of tags in brackets with quotes

## Publishing Workflow

To publish content to the live website:

1. **Commit your changes** (as you normally would)

2. **Run the /publish command**

### What Happens When You Publish

The `publish` command executes `.claude/scripts/publish-all.sh` which:
1. **Validate frontmatter** - Uses `.claude/scripts/frontmatter-validation.sh` to check all articles in visible folders (articles/, daily-logs/, etc.)
2. **Show validation results** - Lists any files with missing or invalid frontmatter with clear error messages
3. **Run content update** - Uses `.claude/scripts/run-content-update.sh` to trigger and wait for content workflow
4. **Run deployment** - Uses `.claude/scripts/run-deployment.sh` to trigger and wait for deployment workflow
5. **Stop on any failure** - Process halts immediately if validation or any workflow fails

If validation succeeds, the deployment process:
1. **Content Update Workflow** runs in main site repository
2. **Submodule Update**: Main site pulls latest content from this repo
3. **Automatic Deployment**: Site rebuilds and deploys to GitHub Pages
4. **Live in ~3-5 minutes**: Content appears at https://meaningfool.github.io/

### Important Notes

- **No automatic deployment**: Pushing to this repo does NOT trigger website updates
- **Manual control**: You decide when content goes live
- **Selective publishing**: Future enhancement will support draft vs published states
- **One command**: The `gh workflow run` command handles everything


## Troubleshooting

### Build Failing with "data does not match collection schema"

**Most common issue**: Missing or incorrect frontmatter

1. **Run validation script**:
   ```bash
   # Use the built-in validation script to check all content
   .claude/scripts/frontmatter-validation.sh
   ```

   This will show exactly which files are missing `title` or `date` fields.

2. **Fix any files that appear** by adding proper frontmatter template

3. **Verify date format**: Must be `YYYY-MM-DD` (no quotes, no time)

**Note**: The `/publish` command automatically runs this validation before deploying, so you'll see these errors before any failed builds.

### Article Not Appearing After Publishing

1. Check workflow status:
   ```bash
   gh run list --repo meaningfool/meaningfool.github.io --limit 5
   ```

2. Look for deployment workflow failure (build errors)

3. Check article filename (should be lowercase with hyphens: `my-article.md`)

### Publishing Command Not Working

1. Ensure GitHub CLI is installed: `gh --version`
2. Verify authentication: `gh auth status`
3. Check you have access to the main repository

## AI Orchestration & Tooling Development

The `.ai-orchestration/` directory contains files for tracking tooling development and automation work.

### Development Log (devlog.md)

**Purpose**: Captures the evolution of tooling and automation infrastructure.

**When to update**:
- After implementing new commands or features
- When fixing significant tooling issues
- When changing architectural approaches

**What to include**:
- Intent behind the change
- What specifically changed (without duplicating commit messages)
- Why the change was made
- Technical implementation details

### Issues Tracker (issues.md)

**Purpose**: Structured tracking of tooling tasks and improvements.

**Issue ID Convention**:
- Issues: `MW-XXXX` (MW = MeaningFool-Writing, XXXX = 0001-9999)
- Sub-issues: `MW-XXXX-XX` (XX = 01-99)
- Sub-sub-issues: `MW-XXXX-XX-XX`

**Structure**:
- Issues: Level 2 headers (`##`)
- Sub-issues: Bullet points (`-`)
- Sub-sub-issues: Nested bullet points (`  -`)

**Workflow**:
1. New issues are added to issues.md with next available ID
2. When completed, move to devlog.md with implementation details
3. Issues remain somewhat immutable - if approach changes, log reason in devlog and create new sub-issues
4. This preserves the history of thinking and approach evolution

**Important for AI Assistants**:
- Check `.ai-orchestration/devlog.md` at session start to understand recent tooling changes
- Consult `.ai-orchestration/issues.md` for planned work and ongoing tasks
- Focus on tooling/automation only - content changes are not tracked here
- Only add what is explicitly requested - no additional fields, status, dates, or sub-issues
- Do not be eager or go beyond what is asked
- Wait for explicit instructions before adding sub-issues or additional structure

## Architecture Details

### Why This Design?

1. **Separation of Concerns**: Content separate from site code
2. **Editorial Control**: Decide when to publish, not on every commit
3. **Collaboration Friendly**: Content writers don't need site code access
4. **Version Control**: Independent history for content changes

### Technical Implementation

- **Main Site**: Astro static site generator at `meaningfool.github.io`
- **Content Collection**: Astro reads articles from `src/content/writing/`
- **Submodule Pointer**: Main site tracks specific commit of this repo
- **GitHub Actions**: Automated workflows handle building and deployment
- **GitHub Pages**: Final deployment target
- **Publishing Pipeline**: Modular scripts in `.claude/scripts/` handle validation, content updates, and deployment
  - `publish-all.sh`: Main orchestration script called by `/publish` command
  - `frontmatter-validation.sh`: Validates all content has proper frontmatter
  - `run-content-update.sh`: Handles content update workflow
  - `run-deployment.sh`: Handles deployment workflow

### Future Enhancements

- Draft vs Published states (via frontmatter or folders)
- Content categories and series
- Automated quality checks
- Preview deployments

## Key Commands Summary

```bash
# In this repository - commit your work
git add . && git commit -m "Your message" && git push

# Validate frontmatter manually (optional)
.claude/scripts/frontmatter-validation.sh

# Publish to website (includes validation + deployment)
/publish

# Run individual workflow components (if needed)
.claude/scripts/run-content-update.sh
.claude/scripts/run-deployment.sh

# Check publishing status
gh run list --repo meaningfool/meaningfool.github.io --limit 3
```

Remember: Write → Commit → Push → Publish (when ready)