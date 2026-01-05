---
name: publishing
description: Publish articles and deploy the meaningfool.github.io website. Use when the user mentions "publish", "deploy", "rebuild website", or wants to move drafts from _draft/ to articles/.
allowed-tools: Bash(.claude/skills/publishing/scripts/*), Bash(git:*), Bash(date:*), Bash(echo:*), Bash(sed:*), Bash(grep:*), Bash(test:*), Bash(gh:*), Read, Edit, Write, Glob, Grep
---

# Publishing Skill

This skill handles publishing articles and deploying the meaningfool.github.io website.

## Repository Context

This repository (`meaningfool-writing`) is a content-only repository that serves as a Git submodule for the main website. Changes here do NOT automatically deploy - a manual publish step is required.

```
meaningfool.github.io (Main Site)
└── src/content/writing/ → [Git Submodule] → meaningfool-writing (This Repo)
```

## Confirmation Behavior

- **Slash commands** (`/publish-article`, `/rebuild-website`): Proceed without confirmation
- **Natural language requests** ("publish my article", "deploy the website"): Ask for confirmation before proceeding

## Core Actions

### 1. Publish Article (with Deploy)

**Default behavior**: Publishes article AND deploys to website.

Moves a draft article from `_draft/` to `articles/` with proper formatting, then automatically deploys to the website.

**Steps:**
1. Extract filename from the provided file reference
2. Generate target filename: `YYYY-MM-DD-clean-filename.md`
3. Verify target doesn't already exist in `articles/`
4. Extract title from first H1 header in the draft
5. Validate image paths (must use `../images/` relative paths)
6. Fix any incorrect image paths
7. Move file to `articles/` folder (use `git mv` if tracked)
8. Add frontmatter at the top of the file
9. Commit and push changes:
   ```bash
   git add articles/
   git commit -m "Publish: [ARTICLE_TITLE]

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   git push
   ```
10. Execute Deploy Website workflow (see below)

**Frontmatter handling:**
- Preserves all existing frontmatter fields
- Updates/adds required fields:
  - `title`: Extracted from H1 header
  - `date`: Today's date (YYYY-MM-DD)
- Optional fields preserved if present (e.g., `hooks`, `tags`, etc.)
- Does NOT add optional fields if they don't exist

Example:
```yaml
# Before (in draft):
---
title: "Old Title"
hooks:
  - https://example.com
---

# After (in articles):
---
title: "Cost of Change is Agile's ceiling"  # Updated
date: 2026-01-05                            # Added
hooks:                                       # Preserved
  - https://example.com
---
```

**Image path rules:**
- Valid: `![alt](../images/my-image.png)`
- Invalid: `![alt](/images/my-image.png)` or `![alt](images/my-image.png)`

### 2. Deploy Website (Rebuild Only)

Validates content and triggers deployment workflows. Use when you've made changes (edited articles, updated daily logs) and want to deploy without publishing a new article.

**Steps:**
1. Run frontmatter validation: `scripts/frontmatter-validation.sh`
2. If validation fails: report issues and stop
3. Run content update: `scripts/run-content-update.sh`
4. Wait for workflow completion
5. Run deployment: `scripts/run-deployment.sh`
6. Wait for workflow completion
7. Report final status

**Verification:**

After content update:
- Verifies submodule commit matches latest push
- On mismatch: provides diagnosis and recovery steps

After deployment:
- Confirms workflow succeeded
- Reminds to manually verify website (GitHub Pages cache takes 2-3 minutes)
- On failure: provides diagnosis and recovery steps

Manual check:
```bash
gh run list --repo meaningfool/meaningfool.github.io --limit 3
```

## Error Handling

| Error | Action |
|-------|--------|
| No file reference provided | Ask user for the file |
| Target file exists | Report conflict, ask for resolution |
| No H1 header found | Report error, suggest adding a title |
| Image file not found | Warn but continue |
| Frontmatter validation fails | List issues with fix template |
| Workflow fails | Report status, see [troubleshooting.md](troubleshooting.md) |

## Supporting Documentation

- [workflows.md](workflows.md) - Detailed step-by-step processes
- [troubleshooting.md](troubleshooting.md) - Common issues and solutions
