---
allowed-tools: Read(.ai-orchestration/*), Edit(.ai-orchestration/*), Bash(command:grep*), Bash(command:git*)
---

# Close Issue Command

Close a completed issue by moving it from issues.md to devlog.md with technical findings.

## Usage
```
/close issue description or keywords
```

## Process
1. Search issues.md for matching issue based on provided keywords
2. If multiple matches found, present disambiguation options
3. Analyze recent commits (last 1-2) for technical implementation details
4. Move complete issue content (including sub-issues and discussion) to devlog.md
5. Add technical findings from commit analysis
6. Remove issue from issues.md

## Example
```
/close close command
```

This would find and close MW-0003 (Add a close command to close issues).