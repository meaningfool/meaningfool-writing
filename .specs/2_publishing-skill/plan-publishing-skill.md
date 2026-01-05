# Plan: Publishing Skill

## Overview
Convert the existing `/publish-article` and `/rebuild-website` slash commands into a unified publishing skill with automatic activation, verification loops, and extensible troubleshooting.

## Todo List

### 1. Create skill directory structure
- [ ] Create `.claude/skills/publishing/` directory
- [ ] Verify directory is recognized by Claude Code

### 2. Create SKILL.md
- [ ] Add frontmatter with name, description, allowed-tools
- [ ] Write repository context section (submodule relationship)
- [ ] Document Publish Article workflow (from existing publish-article.md)
- [ ] Document Deploy Website workflow (from existing rebuild-website.md)
- [ ] Document chained Publish and Deploy workflow
- [ ] Add verification process instructions
- [ ] Add references to supporting files

### 3. Create workflows.md
- [ ] Detail Publish Article step-by-step process
- [ ] Detail Deploy Website step-by-step process
- [ ] Document script locations and usage
- [ ] Include frontmatter template and rules
- [ ] Document image path requirements

### 4. Create troubleshooting.md
- [ ] Add frontmatter validation errors section
- [ ] Add workflow failure troubleshooting
- [ ] Add image path issues section
- [ ] Add GitHub CLI authentication issues
- [ ] Leave structure extensible for future issues

### 5. Update slash commands
- [ ] Simplify publish-article.md to thin wrapper
- [ ] Simplify rebuild-website.md to thin wrapper
- [ ] Test commands trigger skill correctly

### 6. Testing
- [ ] Test skill auto-activation with "publish my article"
- [ ] Test skill auto-activation with "deploy the website"
- [ ] Test /publish-article command (no confirmation)
- [ ] Test /rebuild-website command (no confirmation)
- [ ] Test chained publish-and-deploy flow
- [ ] Test verification loop reports success
- [ ] Test verification loop handles failure

### 7. Documentation
- [ ] Update CLAUDE.md to reference new skill
- [ ] Remove redundant documentation from command files

## Files to Create

| File | Purpose |
|------|---------|
| `.claude/skills/publishing/SKILL.md` | Main skill definition |
| `.claude/skills/publishing/workflows.md` | Detailed workflow documentation |
| `.claude/skills/publishing/troubleshooting.md` | Common issues and solutions |

## Files to Modify

| File | Change |
|------|--------|
| `.claude/commands/publish-article.md` | Replace with thin wrapper |
| `.claude/commands/rebuild-website.md` | Replace with thin wrapper |
| `CLAUDE.md` | Add reference to publishing skill |

## Files to Preserve (No Changes)

| File | Reason |
|------|--------|
| `.claude/scripts/frontmatter-validation.sh` | Still used by skill |
| `.claude/scripts/rebuild-website.sh` | Still used by skill |
| `.claude/scripts/run-content-update.sh` | Still used by skill |
| `.claude/scripts/run-deployment.sh` | Still used by skill |
| `.claude/commands/daily.md` | Separate functionality |
| `.claude/scripts/daily.sh` | Separate functionality |

## Implementation Order

1. **Create skill structure** - Directory and SKILL.md first
2. **Add supporting docs** - workflows.md and troubleshooting.md
3. **Update commands** - Convert to thin wrappers
4. **Test thoroughly** - Both auto-activation and explicit commands
5. **Update CLAUDE.md** - Document the new skill

## Key Design Decisions

- **Scripts stay in place**: Existing scripts in `.claude/scripts/` are reused, not duplicated
- **Thin wrapper commands**: Slash commands become minimal, delegating to skill
- **Confirmation behavior**: Auto-activation asks, slash commands proceed automatically
- **Verification built-in**: Skill waits for workflow completion and reports status
- **Extensible troubleshooting**: Start minimal, grow based on encountered issues

## Expected Outcomes

- Simpler mental model (one skill instead of separate commands)
- Automatic recognition of publishing requests
- Better error handling with troubleshooting guidance
- Chained workflows (publish → deploy in one request)
- Foundation for future enhancements (draft states, preview deployments)
