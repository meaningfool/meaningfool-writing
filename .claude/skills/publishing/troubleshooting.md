# Troubleshooting Publishing Issues

Common issues encountered when publishing articles and deploying the website.

## Frontmatter Validation Errors

### Issue: "data does not match collection schema"

**Cause**: Missing or incorrect frontmatter in article files.

**Solution**:

1. Run validation script to identify issues:
   ```bash
   .claude/scripts/frontmatter-validation.sh
   ```

2. Check reported files for missing `title` or `date` fields

3. Add proper frontmatter template:
   ```yaml
   ---
   title: "Your Article Title Here"
   date: 2025-09-11
   tags: ["optional", "tags"]
   ---
   ```

4. Verify date format is `YYYY-MM-DD` (no quotes, no time)

**Note**: Files in hidden folders (starting with `.`) or in root don't need frontmatter. Only articles in `articles/` and `daily-logs/` require it.

### Issue: "Title field missing"

**Cause**: Frontmatter exists but `title` field is missing or empty.

**Fix**: Add title field with quoted string:
```yaml
title: "Your Article Title"
```

### Issue: "Date field missing or invalid"

**Cause**: Date field is missing, incorrectly formatted, or quoted.

**Fix**: Add date in YYYY-MM-DD format without quotes:
```yaml
date: 2025-09-11
```

Common mistakes:
- ❌ `date: "2025-09-11"` (quoted)
- ❌ `date: 09-11-2025` (wrong format)
- ❌ `date: 2025-09-11T00:00:00` (includes time)
- ✅ `date: 2025-09-11` (correct)

## Workflow Failures

### Issue: Submodule Verification Failed

**Cause**: Content update workflow succeeded but submodule wasn't updated to latest commit.

**Symptoms**:
```
❌ Verification Failed: Submodule Update
Expected commit: abc123
Submodule points to: def456
```

**Diagnosis**:
- Workflow ran successfully
- But the main site's submodule reference wasn't updated
- This can happen if the workflow had issues updating the submodule

**Fix**:
1. Re-run deployment:
   ```bash
   /rebuild-website
   ```
2. If problem persists, check workflow logs:
   ```bash
   gh run list --repo meaningfool/meaningfool.github.io --limit 3
   gh run view [RUN_ID] --repo meaningfool/meaningfool.github.io --log
   ```
3. Look for errors in the "Update submodule" step

**Note**: Your content is safe in git. This is just a deployment issue.

### Issue: Content Update Workflow Failed

**Cause**: GitHub Actions workflow failed to update submodule.

**Diagnosis**:
```bash
gh run list --repo meaningfool/meaningfool.github.io --limit 5
gh run view [RUN_ID] --repo meaningfool/meaningfool.github.io
```

**Common causes**:
- Commit not pushed to this repo yet
- Submodule reference outdated in main repo
- GitHub Actions permissions issue

**Fix**:
1. Ensure changes are committed and pushed
2. Manually trigger workflow again
3. Check workflow logs for specific error

### Issue: Deployment Workflow Failed

**Cause**: Astro build failed or deployment encountered error.

**Symptoms**:
```
❌ Deployment Workflow Failed
Workflow conclusion: failure
```

**Diagnosis** (automatically provided by script):
- The deployment workflow encountered an error
- Your content was updated in the repo, but not deployed to website
- Common issues listed in error output

**Fix**:
1. Check workflow logs (command provided in error output):
   ```bash
   gh run view [RUN_ID] --repo meaningfool/meaningfool.github.io --log
   ```

2. Common causes:
   - Astro build failed (check for frontmatter errors)
   - Missing images referenced in articles
   - Deployment permissions issue

3. Fix the issue in this repo, commit and push

4. Re-run deployment:
   ```bash
   /rebuild-website
   ```

### Issue: Workflow Timeout

**Cause**: Workflow took longer than 5 minutes.

**Fix**:
1. Check if workflow is still running:
   ```bash
   gh run list --repo meaningfool/meaningfool.github.io --limit 3
   ```
2. Wait for completion and check status
3. If workflow failed, see troubleshooting above

## Image Path Issues

### Issue: Images not appearing on website

**Cause**: Incorrect image paths in articles.

**Fix**: Articles in `articles/` folder must use relative paths to sibling `images/` folder:

- ✅ Correct: `![alt](../images/my-image.png)`
- ❌ Wrong: `![alt](/images/my-image.png)` (absolute path)
- ❌ Wrong: `![alt](images/my-image.png)` (incorrect relative)

**Why**: The `images/` folder is a sibling of `articles/`, so we go up one level (`..`) first.

### Issue: "Image not found" warning during publish

**Cause**: Article references an image that doesn't exist in `images/` folder.

**Action**:
1. Add the missing image to `images/` folder
2. Or update the article to remove/fix the reference
3. Commit and push changes

**Note**: This is a warning, not an error. Publish continues but image won't display.

## GitHub CLI Issues

### Issue: "gh: command not found"

**Cause**: GitHub CLI not installed.

**Fix**:
```bash
brew install gh
```

### Issue: "authentication required"

**Cause**: GitHub CLI not authenticated.

**Fix**:
```bash
gh auth login
```

Follow prompts to authenticate.

### Issue: "repository not found" or "permission denied"

**Cause**: No access to main repository.

**Fix**: Request access to `meaningfool/meaningfool.github.io` repository.

## Article Not Appearing After Deploy

### Issue: All workflows succeeded but content not visible on website

**What happened**:
- ✅ Content update workflow succeeded
- ✅ Submodule verification passed
- ✅ Deployment workflow succeeded
- ❌ But content not visible on website

**Likely causes**:
1. **GitHub Pages cache delay** (most common)
   - Wait 2-3 minutes after deployment
   - Hard refresh browser (Cmd+Shift+R)

2. **Content not in expected location**
   - Check article is in `articles/` folder
   - Verify filename format: `YYYY-MM-DD-article-name.md`

3. **Frontmatter issues**
   - Even though validation passed, Astro might skip the article
   - Check build logs for warnings

**Fix**:
1. Wait a few minutes and check again

2. Clear browser cache and hard refresh

3. Check if article appears in site navigation/index

4. If still not visible, check build logs:
   ```bash
   gh run view [DEPLOY_RUN_ID] --repo meaningfool/meaningfool.github.io --log
   ```

### Issue: Deployment succeeded but article not visible (legacy checks)

**Checks**:

1. **Verify article filename**: Should be lowercase with hyphens
   - ✅ `2025-09-11-my-article.md`
   - ❌ `2025-09-11-My_Article.md`

2. **Check article is in `articles/` folder**: Not in `_draft/` or elsewhere

3. **Verify frontmatter**: Must have `title` and `date`

4. **Check deployment time**: Can take 3-5 minutes to propagate

5. **Clear browser cache**: Hard refresh (Cmd+Shift+R)

6. **Check site URL**: https://meaningfool.github.io/

## Git Issues

### Issue: Target file already exists

**Cause**: Article with same name already published for today.

**Options**:
1. Choose different filename/title
2. Delete existing article if it's outdated
3. Publish with tomorrow's date

### Issue: "git mv failed"

**Cause**: File is untracked or path is incorrect.

**Fix**: Use regular `mv` instead of `git mv` for untracked files.

## Extensibility Note

This file will grow as new issues are encountered. Add new sections as needed with:
- Issue description
- Cause
- Diagnosis steps
- Fix/solution
