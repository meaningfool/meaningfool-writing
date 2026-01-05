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

## Publishing Skill

The **publishing skill** (`.claude/skills/publishing/`) handles article publishing and website deployment.

### Automatic Activation

Claude will recognize and offer the publishing skill when you:
- Mention "publish", "deploy", or "rebuild website"
- Ask to move drafts to articles
- Request website updates

### Core Commands

**Publish an article:**
```bash
/publish-article @_draft/my-article.md
```

**Rebuild and deploy the website:**
```bash
/rebuild-website
```

**Natural language also works:**
- "Publish my article about X" (publishes + deploys)
- "Deploy the website" (deploy only)

### What Happens When Publishing

**Publish Article** (automatically deploys):
1. Extracts title from first H1 header
2. Generates dated filename (YYYY-MM-DD-article-name.md)
3. Validates and fixes image paths
4. Moves file to `articles/` folder
5. Adds frontmatter (title, date, tags)
6. Commits and pushes changes
7. Triggers deployment workflows
8. Content live at https://meaningfool.github.io/ in ~3-5 minutes

**Rebuild Website** (deploy only):
1. Validates frontmatter for all articles
2. Triggers content update workflow (GitHub Actions)
3. Triggers deployment workflow
4. Waits for completion and reports status
5. Content live at https://meaningfool.github.io/ in ~3-5 minutes

### Detailed Documentation

For detailed workflows and troubleshooting, see:
- `.claude/skills/publishing/SKILL.md` - Core skill definition
- `.claude/skills/publishing/workflows.md` - Step-by-step processes
- `.claude/skills/publishing/troubleshooting.md` - Common issues and fixes

### Important Notes

- **No automatic deployment**: Pushing to this repo does NOT trigger website updates
- **Manual control**: You decide when content goes live via explicit commands or requests
- **Slash commands proceed automatically**: No confirmation required
- **Natural language requests ask first**: Claude confirms before proceeding


## Troubleshooting

### Build Failing with "data does not match collection schema"

**Most common issue**: Missing or incorrect frontmatter

1. **Run validation script**:
   ```bash
   # Use the built-in validation script to check all content
   .claude/skills/publishing/scripts/frontmatter-validation.sh
   ```

   This will show exactly which files are missing `title` or `date` fields.

2. **Fix any files that appear** by adding proper frontmatter template

3. **Verify date format**: Must be `YYYY-MM-DD` (no quotes, no time)

**Note**: The `/rebuild-website` command automatically runs this validation before deploying, so you'll see these errors before any failed builds.

### Article Not Appearing After Rebuilding Website

1. Check workflow status:
   ```bash
   gh run list --repo meaningfool/meaningfool.github.io --limit 5
   ```

2. Look for deployment workflow failure (build errors)

3. Check article filename (should be lowercase with hyphens: `my-article.md`)

### Website Rebuild Command Not Working

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
- **Publishing Skill**: Self-contained skill in `.claude/skills/publishing/` with bundled scripts
  - `SKILL.md`: Main skill definition for publishing and deployment
  - `scripts/rebuild-website.sh`: Main orchestration script
  - `scripts/frontmatter-validation.sh`: Validates all content has proper frontmatter
  - `scripts/run-content-update.sh`: Handles content update workflow
  - `scripts/run-deployment.sh`: Handles deployment workflow
- **Daily Command**: Separate skill in `.claude/scripts/`
  - `daily.sh`: Generates daily development logs from GitHub commits

### Future Enhancements

- Draft vs Published states (via frontmatter or folders)
- Content categories and series
- Automated quality checks
- Preview deployments

## Key Commands Summary

```bash
# Publishing (via skill)
/publish-article @_draft/my-article.md    # Publish a draft article
/rebuild-website                           # Deploy website updates

# Or use natural language:
# "publish my article"
# "deploy the website"
# "publish and deploy this article"

# Daily development logs
/daily                    # Today's commits
/daily yesterday         # Yesterday's commits
/daily -3               # 3 days ago
/daily 2025-09-20      # Specific date

# Manual validation and checks
.claude/skills/publishing/scripts/frontmatter-validation.sh   # Validate frontmatter
gh run list --repo meaningfool/meaningfool.github.io         # Check deploy status

# Individual workflow scripts (usually not needed - use skill instead)
.claude/skills/publishing/scripts/run-content-update.sh
.claude/skills/publishing/scripts/run-deployment.sh
```

Remember: Write → Commit → Push → Publish (when ready)