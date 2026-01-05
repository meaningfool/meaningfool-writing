# Specification: Publishing Skill

## Overview
Create a publishing skill that consolidates article publishing and website deployment functionality, enabling automatic activation when Claude recognizes publishing-related requests, while maintaining explicit slash command triggers.

## Requirements

### Core Actions

#### 1. Publish Article
- **Input**: File reference to a draft article (e.g., `@_draft/my-article.md`)
- **Process**:
  1. Extract filename and generate target filename with date prefix
  2. Verify target doesn't already exist in `articles/`
  3. Extract title from first H1 header
  4. Validate and fix image paths (must use `../images/` relative paths)
  5. Move file to `articles/` folder
  6. Add frontmatter (title, date, tags)
- **Output**: Confirmation with new filename and any fixes applied

#### 2. Deploy Website (Rebuild)
- **Input**: None required
- **Process**:
  1. Validate frontmatter for all articles in visible folders
  2. Run content update workflow (GitHub Actions)
  3. Wait for workflow completion
  4. Run deployment workflow (GitHub Actions)
  5. Wait for workflow completion
  6. Verify deployment succeeded
- **Output**: Status report with success/failure and next steps

#### 3. Publish and Deploy (Chained)
- **Input**: File reference to a draft article
- **Process**:
  1. Execute Publish Article workflow
  2. Commit and push changes
  3. Execute Deploy Website workflow
- **Output**: Combined status report

### Activation Triggers

| Trigger Type | Examples | Confirmation Required |
|--------------|----------|----------------------|
| Slash command `/publish-article` | `/publish-article @_draft/article.md` | No |
| Slash command `/rebuild-website` | `/rebuild-website` | No |
| Natural language publish | "publish my article", "move draft to articles" | Yes |
| Natural language deploy | "deploy the website", "rebuild the site" | Yes |
| Combined request | "publish and deploy my article" | Yes |

### Verification Loop

After deployment, the skill should:
1. Poll GitHub workflow status until completion (timeout: 5 minutes)
2. Report final status (success/failure)
3. On failure: provide actionable troubleshooting steps
4. On success: confirm content is live

### Error Handling

| Error | Behavior |
|-------|----------|
| Missing file reference | Prompt user for file |
| Target file exists | Report conflict, ask for resolution |
| No H1 header in draft | Report error, suggest fix |
| Missing image files | Warn but continue |
| Frontmatter validation fails | List issues, provide fix template |
| Workflow failure | Report status, provide troubleshooting steps |
| Workflow timeout | Report timeout, provide manual check command |

## Architecture

### Skill Structure

```
.claude/skills/publishing/
├── SKILL.md                 # Main skill definition with core logic
├── workflows.md             # Detailed workflow documentation
└── troubleshooting.md       # Common issues and solutions
```

### Existing Scripts (Reused)

Scripts remain in `.claude/scripts/` and are referenced by the skill:
- `frontmatter-validation.sh` - Validates frontmatter in all articles
- `rebuild-website.sh` - Orchestrates full deployment pipeline
- `run-content-update.sh` - Triggers content update workflow
- `run-deployment.sh` - Triggers deployment workflow

### Slash Commands (Simplified)

Commands become thin wrappers that invoke the skill:

**`.claude/commands/publish-article.md`**:
```markdown
---
description: Publish a draft article to the articles folder
---
Use the publishing skill to publish this article: $ARGUMENTS
Proceed without asking for confirmation.
```

**`.claude/commands/rebuild-website.md`**:
```markdown
---
description: Rebuild and deploy the website
---
Use the publishing skill to rebuild and deploy the website.
Proceed without asking for confirmation.
```

### SKILL.md Structure

```yaml
---
name: publishing
description: Publish articles and deploy the meaningfool.github.io website. Use when the user mentions "publish", "deploy", "rebuild website", or wants to move drafts from _draft/ to articles/.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---
```

**Content sections:**
1. Repository context (submodule relationship)
2. Publish Article workflow (step-by-step)
3. Deploy Website workflow (step-by-step)
4. Verification process
5. References to workflows.md and troubleshooting.md

## Data Flow

### Publish Article Flow
```
User request → Skill activation → File validation → Image path fixes → 
File move → Frontmatter insertion → Confirmation
```

### Deploy Website Flow
```
User request → Skill activation → Frontmatter validation → 
Content update workflow → Wait → Deployment workflow → Wait → 
Verification → Status report
```

### Chained Flow
```
Publish Article Flow → git add/commit/push → Deploy Website Flow
```

## Key Differences from Current Implementation

### Added
- Automatic skill activation based on natural language
- Verification loop after deployment
- Chained publish-and-deploy workflow
- Extensible troubleshooting documentation
- Confirmation prompts for auto-activated requests

### Changed
- Slash commands become thin wrappers
- Logic moves from command files to SKILL.md
- Structured documentation in separate files

### Preserved
- All existing scripts remain functional
- Same underlying workflow mechanics
- Same frontmatter validation logic
- Same image path handling

## Implementation Notes

- Skill loads only when relevant (token-efficient)
- Description keywords enable semantic matching
- `allowed-tools` restricts to necessary operations
- Troubleshooting.md grows organically as issues are encountered
- Scripts can still be run directly from CLI if needed
