# AI Orchestration Issues Tracker

<!-- 
ISSUE TRACKING CONVENTIONS:

Issue IDs: MW-XXXX (MW = MeaningFool-Writing, XXXX = 0001-9999)
Sub-issue IDs: MW-XXXX-XX (XX = 01-99)
Sub-sub-issue IDs: MW-XXXX-XX-XX

Structure:
- Issues: Level 2 headers (##)
- Sub-issues: Bullet points (-)
- Sub-sub-issues: Nested bullet points (  -)
- Discussion: Plain text under issue/sub-issue

Workflow:
1. New issues are added here with next available ID
2. When completed, they move to devlog.md with implementation details
3. Issues should remain somewhat immutable - if approach changes, log the reason in devlog and create new sub-issues
4. This preserves the history of our thinking and approach evolution

IMPORTANT FOR AI ASSISTANTS:
- Only add what is explicitly requested - no additional fields, status, dates, or sub-issues
- Only add discussion points when actual decisions or findings exist
- Do not be eager or go beyond what is asked
- If description is not provided, do not add one
- Wait for explicit instructions before adding sub-issues or additional structure
-->

## MW-0001: Create Issues with Slash Command
**Sub-issues**:
- MW-0001-01: Create the slash command
- MW-0001-02: Slash command takes a long time and requires manual authorization
**Discussion**: 
- Chose single argument with "--" delimiter for separating title and description
- Research findings on authorization:
  - Frontmatter `allowed-tools` syntax: `allowed-tools: Bash(command:*), Write(path/*)` - unclear if session authorization still required
  - Settings.json pre-authorization syntax: `{"permissions": {"allow": ["Edit(.ai-orchestration/*)"]}}` - eliminates authorization prompts
  - Slash commands cannot bypass AI processing for pure bash execution - `!` prefix still involves Claude
- Decision: Use settings.json permissions to pre-authorize Edit/Read tools for .ai-orchestration/ files

## MW-0002: Devlog needs better structure

Devlog should capture design decisions from issues, technical findings, and implementation-related discoveries. Current structure may need enhancement to distinguish between different types of entries.

## MW-0003: Add a close command to close issues

Need to create a command that transfers completed issues from the issue tracker to the devlog with implementation details.

## MW-0004: Add a thoughts.md

Need to create a file for capturing thoughts and ideas that are not related to specific issues.

## MW-0005: Add a thought command to capture a new thought in thoughts.md

Need to create a slash command for adding new thoughts to the thoughts.md file.

## MW-0006: Clean up settings.json

Configure settings.json with proper tool permissions to eliminate authorization prompts for AI orchestration commands.

**Discussion**:
- Research findings on permission scoping:
  - Settings.json permissions cannot be scoped to specific slash commands - operates at tool level only
  - Three scoping approaches: minimal bash permissions, directory-scoped permissions, slash command frontmatter
  - Bash patterns use prefix matching and "can be bypassed" according to documentation
- Recommendation: Use directory-scoped approach with `"allow"` for Edit/Read on `.ai-orchestration/*` and `"ask"` for specific bash commands (grep, printf, sed) for safety
- Decision: Will use allow/ask patterns for directory-scoped permissions, and test frontmatter `allowed-tools` approach for command-level scoped authorization

---

*Issues marked with ✓ have been completed and documented in devlog.md*