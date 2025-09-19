---
allowed-tools: Bash(git mv:*), Bash(date:*), Bash(test:*), Bash(echo:*), Bash(sed:*)
---

## Task

The user will provide a file reference using the @ feature. If this file reference contains a path, we need to extract the raw filename from the path, and then extract a clean filename from the raw filename. And finally generate the target filename from the clean filename and the current date.
Convert the provided draft file to a published article `articles/[TARGET_FILENAME].md`.

## Context Variables

Use these bash command patterns to generate the variables:

- **[FILE_REFERENCE]**: The @ file reference provided by user (e.g., `@_draft/01-test-article.md`)
- **[RAW_FILENAME]**: `echo "[FILE_REFERENCE]" | sed 's/.*\///; s/\.md$//'` (e.g., `01-test-article`)
- **[CLEAN_FILENAME]**: `echo "[RAW_FILENAME]" | sed 's/^[^a-zA-Z]*//'` (e.g., `test-article`)
- **[DATE_PREFIX]**: `date +%Y-%m-%d` (e.g., `2025-09-19`)
- **[ISO_TIMESTAMP]**: `date +%Y-%m-%dT%H:%M:%S%z` (e.g., `2025-09-19T17:53:59+0200`)
- **[TARGET_FILENAME]**: `[DATE_PREFIX]-[CLEAN_FILENAME]` (e.g., `2025-09-19-test-article`)
- **[EXTRACTED_TITLE]**: First H1 header from draft content (e.g., `My Test Article`)

### Processing Steps:

1. **Generate variables**: Create [RAW_FILENAME], [CLEAN_FILENAME], [DATE_PREFIX], [ISO_TIMESTAMP], and [TARGET_FILENAME]
2. **Check target availability**: Verify `articles/[TARGET_FILENAME].md` doesn't already exist
3. **Extract title**: Get [EXTRACTED_TITLE] from first H1 header in draft content
4. **Move file**: Use `git mv` to rename draft to `articles/[TARGET_FILENAME].md`
5. **Add frontmatter**: Insert frontmatter template with [EXTRACTED_TITLE] and [ISO_TIMESTAMP]

### Frontmatter Template:
```yaml
---
title: "[EXTRACTED_TITLE]"
date: [ISO_TIMESTAMP]
tags: []
---
```

### Error Handling:
- If no file reference provided: "Error: Please provide a file reference (e.g., /publish-article @_draft/my-file.md)"
- If target already exists: "Error: Article with same name already exists for today's date"
- If no H1 header found: "Error: No H1 header found in draft for title extraction"

Complete the conversion and report the new article filename.