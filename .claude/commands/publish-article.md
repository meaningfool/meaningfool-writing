---
description: "Publishes a draft article by moving it to the articles folder with proper date prefix and frontmatter"
allowed-tools: Bash(git mv:*), Bash(test:*), Bash(echo:*), Bash(sed:*), Bash(mv:*), Read, Edit
---

## Task

The user will provide a file reference using the @ feature. The file reference may contain a path to the file, we need to extract the raw filename from the path, and then extract a clean filename from the raw filename. And finally generate the target filename from the clean filename and the current date.

## Context Variables

Use these bash command patterns to generate the variables:

- **[FILE_REFERENCE]**: The @ file reference provided by user (e.g., `@_draft/01-test-article.md`)
- **[RAW_FILENAME]**: `echo "[FILE_REFERENCE]" | sed 's/.*\///; s/\.md$//'` (e.g., `01-test-article`)
- **[CLEAN_FILENAME]**: `echo "[RAW_FILENAME]" | sed 's/^[^a-zA-Z]*//'` (e.g., `test-article`)
- **[DATE_PREFIX]**: today's date in YYYY-MM-DD format (e.g., `2025-09-19`)
- **[TARGET_FILENAME]**: `[DATE_PREFIX]-[CLEAN_FILENAME]` (e.g., `2025-09-19-test-article`)
- **[EXTRACTED_TITLE]**: First H1 header from draft content (e.g., `My Test Article`)

### Processing Steps:

1. **Generate variables**: Create [RAW_FILENAME], [CLEAN_FILENAME], [DATE_PREFIX] and [TARGET_FILENAME]
2. **Check target availability**: Verify `articles/[TARGET_FILENAME].md` doesn't already exist
3. **Extract title**: Get [EXTRACTED_TITLE] from first H1 header in draft content
4. **Validate and fix image paths**:
   - Scan for markdown image references: `![...](path)`
   - Images referencing local files must use relative paths from the `articles/` folder
   - Fix absolute paths: `/images/...` → `../images/...`
   - Fix incorrect relative paths: `images/...` → `../images/...`
   - Verify referenced images exist in `images/` folder
   - Report any missing images as warnings
5. **Move file**:
   - If the file is tracked, use `git mv` to rename draft to `articles/[TARGET_FILENAME].md`
   - If the file is untracked use bash move tool
6. **Add frontmatter**: Insert frontmatter template with [EXTRACTED_TITLE] and [DATE_PREFIX]

### Image Path Rules:

Articles in `articles/` folder must reference images using `../images/filename.ext` because:
- The `images/` folder is a sibling of `articles/`
- Absolute paths (`/images/...`) resolve to website root, not the content submodule

Valid: `![alt](../images/my-image.png)`
Invalid: `![alt](/images/my-image.png)` or `![alt](images/my-image.png)`

### Frontmatter Template:
```yaml
---
title: "[EXTRACTED_TITLE]"
date: [DATE_PREFIX]
tags: []
---
```

### Error Handling:
- If no file reference provided: "Error: Please provide a file reference (e.g., /publish-article @_draft/my-file.md)"
- If target already exists: "Error: Article with same name already exists for today's date"
- If no H1 header found: "Error: No H1 header found in draft for title extraction"
- If image file not found: "Warning: Image not found: [path]. Please verify the image exists."

Complete the conversion and report the new article filename, including any image path fixes applied.
