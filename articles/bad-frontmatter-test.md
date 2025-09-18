---
name: "This Article Has Bad Frontmatter"
created: 2025-09-17
categories: ["test", "validation"]
---

# Testing Bad Frontmatter

This article intentionally has incorrect frontmatter to test our validation system.

## What's Wrong?

Instead of the required fields:
- `title` - we used `name`
- `date` - we used `created`
- `tags` - we used `categories`

## Expected Behavior

When we try to publish, the validation should catch these errors and prevent deployment until they're fixed.

This helps ensure that only properly formatted articles make it to the live site.