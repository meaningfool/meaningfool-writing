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
- This repository contains **only Markdown articles** - no site code, no workflows
- The main site pulls content from here via Git submodule mechanism
- Changes here do NOT automatically deploy to the website
- Manual publishing step required to update the live site

## Content Structure

Articles should be Markdown files with frontmatter:

```markdown
---
title: "Article Title"
date: 2025-01-15
description: "Optional description"
tags: ["optional", "tags"]
---

Article content here...
```

## Publishing Workflow

### Prerequisites Before Publishing

1. **Commit all changes** in this repository:
   ```bash
   git add .
   git commit -m "Add/update article: [title]"
   git push origin main
   ```

2. **Verify content** is ready for publication:
   - Check article formatting
   - Verify frontmatter is correct
   - Ensure no draft content is being published

### Publishing Command

To publish content to the live website, run this command from **anywhere** (you don't need to be in any specific directory):

```bash
gh workflow run update-content.yml --repo meaningfool/meaningfool.github.io
```

### What Happens When You Publish

1. **Content Update Workflow** runs in main site repository
2. **Submodule Update**: Main site pulls latest content from this repo
3. **Automatic Deployment**: Site rebuilds and deploys to GitHub Pages
4. **Live in ~3-5 minutes**: Content appears at https://meaningfool.github.io/

### Important Notes

- **No automatic deployment**: Pushing to this repo does NOT trigger website updates
- **Manual control**: You decide when content goes live
- **Selective publishing**: Future enhancement will support draft vs published states
- **One command**: The `gh workflow run` command handles everything

## Common Tasks

### Adding a New Article

1. Create new `.md` file in this repository
2. Add frontmatter and content
3. Commit and push:
   ```bash
   git add your-article.md
   git commit -m "Add article: Your Title"
   git push origin main
   ```
4. When ready to publish, run the publishing command above

### Updating an Existing Article

1. Edit the `.md` file
2. Commit and push changes
3. Run publishing command when ready

### Removing an Article

1. Delete the `.md` file
2. Commit and push the deletion
3. Run publishing command to remove from live site

## Troubleshooting

### Article Not Appearing After Publishing

1. Check workflow status:
   ```bash
   gh run list --repo meaningfool/meaningfool.github.io --limit 5
   ```

2. Verify article has valid frontmatter (especially `title` and `date`)

3. Check article filename (should be lowercase with hyphens: `my-article.md`)

### Publishing Command Not Working

1. Ensure GitHub CLI is installed: `gh --version`
2. Verify authentication: `gh auth status`
3. Check you have access to the main repository

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

### Future Enhancements

- Draft vs Published states (via frontmatter or folders)
- Content categories and series
- Automated quality checks
- Preview deployments

## Key Commands Summary

```bash
# In this repository - commit your work
git add . && git commit -m "Your message" && git push

# From anywhere - publish to website
gh workflow run update-content.yml --repo meaningfool/meaningfool.github.io

# Check publishing status
gh run list --repo meaningfool/meaningfool.github.io --limit 3
```

Remember: Write → Commit → Push → Publish (when ready)