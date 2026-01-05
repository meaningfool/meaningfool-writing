# Publishing Workflows

Detailed step-by-step processes for publishing articles and deploying the website.

**Default behavior**: Publishing an article automatically deploys the website.

## Publish Article Workflow (with Deploy)

### Context Variables

Generate these bash variables for the workflow:

- **[FILE_REFERENCE]**: The @ file reference provided by user (e.g., `@_draft/01-test-article.md`)
- **[RAW_FILENAME]**: `echo "[FILE_REFERENCE]" | sed 's/.*\///; s/\.md$//'` (e.g., `01-test-article`)
- **[CLEAN_FILENAME]**: `echo "[RAW_FILENAME]" | sed 's/^[^a-zA-Z]*//'` (e.g., `test-article`)
- **[DATE_PREFIX]**: Today's date in YYYY-MM-DD format (e.g., `2025-09-19`)
- **[TARGET_FILENAME]**: `[DATE_PREFIX]-[CLEAN_FILENAME]` (e.g., `2025-09-19-test-article`)
- **[EXTRACTED_TITLE]**: First H1 header from draft content (e.g., `My Test Article`)

### Step-by-Step Process

1. **Generate variables**
   - Create [RAW_FILENAME], [CLEAN_FILENAME], [DATE_PREFIX], and [TARGET_FILENAME]

2. **Check target availability**
   - Verify `articles/[TARGET_FILENAME].md` doesn't already exist
   - If exists: report conflict and stop

3. **Extract title**
   - Read the draft file
   - Find first H1 header (`# Title`)
   - Extract [EXTRACTED_TITLE]
   - If no H1 found: report error and stop

4. **Validate and fix image paths**
   - Scan for markdown image references: `![...](path)`
   - Check each image path:
     - Images must use `../images/` relative paths
     - Fix absolute paths: `/images/...` → `../images/...`
     - Fix incorrect relative: `images/...` → `../images/...`
   - Verify referenced images exist in `images/` folder
   - Report any missing images as warnings (but continue)

5. **Move file**
   - If file is tracked by git: use `git mv`
     ```bash
     git mv _draft/[SOURCE].md articles/[TARGET_FILENAME].md
     ```
   - If file is untracked: use regular `mv`
     ```bash
     mv _draft/[SOURCE].md articles/[TARGET_FILENAME].md
     ```

6. **Add frontmatter**
   - Insert frontmatter at the top of the file:
     ```yaml
     ---
     title: "[EXTRACTED_TITLE]"
     date: [DATE_PREFIX]
     tags: []
     ---
     ```

7. **Report completion**
   - Confirm new article filename
   - List any image path fixes applied
   - List any warnings (missing images)

8. **Commit and push changes**
   ```bash
   git add articles/[TARGET_FILENAME].md
   git commit -m "Publish: [EXTRACTED_TITLE]

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   git push
   ```

9. **Deploy the website** (see Deploy Website Workflow below)

### Image Path Rules

Articles in `articles/` folder must use relative paths to sibling `images/` folder:

- **Valid**: `![alt](../images/my-image.png)`
- **Invalid**:
  - `![alt](/images/my-image.png)` (absolute path)
  - `![alt](images/my-image.png)` (incorrect relative)

Why: The `images/` folder is a sibling of `articles/`, so we need to go up one level (`..`) first.

### Frontmatter Requirements

All articles in `articles/` folder **must** have frontmatter or the build will fail.

**Required fields:**
- `title` - String, must be quoted
- `date` - YYYY-MM-DD format, no quotes

## Deploy Website Workflow (Rebuild Only)

Use this workflow when you've made changes (edited articles, updated daily logs) and want to deploy without publishing a new article.

### Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Access to `meaningfool/meaningfool.github.io` repository
- All changes committed and pushed to this repo

### Step-by-Step Process

1. **Validate frontmatter**
   ```bash
   scripts/frontmatter-validation.sh
   ```
   - Checks all articles in visible folders (`articles/`, `daily-logs/`)
   - Reports files with missing or invalid frontmatter
   - If validation fails: stop and report issues

2. **Trigger content update workflow**
   ```bash
   scripts/run-content-update.sh
   ```
   - Triggers GitHub Actions workflow in main site repo
   - Updates git submodule to latest commit from this repo
   - Waits for workflow to complete (timeout: 5 minutes)
   - **Verifies submodule commit matches latest push**
   - On verification failure: provides diagnosis and recovery steps
   - Reports success or failure

3. **Trigger deployment workflow**
   ```bash
   scripts/run-deployment.sh
   ```
   - Triggers GitHub Actions deployment workflow
   - Rebuilds Astro site with updated content
   - Deploys to GitHub Pages
   - Waits for workflow to complete (timeout: 5 minutes)
   - On failure: provides diagnosis and recovery steps
   - Reports success or failure

4. **Manual verification**
   - Workflow success confirms deployment completed
   - GitHub Pages cache takes 2-3 minutes to update
   - Manually verify content appears at https://meaningfool.github.io/
   - If issues, check troubleshooting.md

### Scripts Location

All publishing scripts are bundled in `.claude/skills/publishing/scripts/`:
- `frontmatter-validation.sh` - Validates all article frontmatter
- `run-content-update.sh` - Triggers and waits for content update
- `run-deployment.sh` - Triggers and waits for deployment
- `rebuild-website.sh` - Orchestrates all three scripts

### Manual Verification

Check workflow status manually:
```bash
gh run list --repo meaningfool/meaningfool.github.io --limit 3
```
