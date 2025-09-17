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


## MW-0002: Devlog needs better structure

Devlog should capture design decisions from issues, technical findings, and implementation-related discoveries. Current structure may need enhancement to distinguish between different types of entries.

## MW-0003: Add a close command to close issues

Need to create a command that transfers completed issues from the issue tracker to the devlog with implementation details.

**Sub-issues**:
- MW-0003-01: Create a close command for a single issue as a whole
- MW-0003-02: Update the documentation process in CLAUDE.md and related files
- MW-0003-03: Extend the close command to handle closing sub-issues within issues that remain open

**Discussion**:
- Issue identification challenge: Full issue ID might be cumbersome, text-based identification could work better
- Need to avoid reproducing commit messages in devlog - focus on technical learnings and decisions
- Process needs to handle different levels (issues, sub-issues, sub-sub-issues) which may require different workflows
- Decision: Use string-based identifier with disambiguation prompts when matches are ambiguous
- Technical findings auto-detection: Analyze last 1-2 commits that likely relate to the closed issue to extract implementation details
- Bash-centric approach for file manipulation between issues.md and devlog.md with format preservation

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