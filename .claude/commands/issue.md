---
description: Create a new issue in the AI orchestration tracker
argument-hint: <title> -- <optional description>
---

I'll parse the arguments, clean up any dictated text, find the next issue ID, and add the issue to the tracker.

First, let me parse the input and find the next available issue ID:

!bash -c "
FULL_ARG='$1'
if [[ \"\$FULL_ARG\" == *' -- '* ]]; then
    TITLE=\"\${FULL_ARG%% -- *}\"
    DESCRIPTION=\"\${FULL_ARG#* -- }\"
else
    TITLE=\"\$FULL_ARG\"
    DESCRIPTION=\"\"
fi

ISSUES_FILE='.ai-orchestration/issues.md'
LAST_ID=\$(grep -E '^## MW-[0-9]{4}:' \"\$ISSUES_FILE\" | tail -1 | sed 's/^## MW-\([0-9]*\):.*/\1/')

if [ -z \"\$LAST_ID\" ]; then
    NEXT_ID='0001'
else
    NEXT_ID=\$(printf '%04d' \$((10#\$LAST_ID + 1)))
fi

echo \"TITLE: \$TITLE\"
echo \"DESCRIPTION: \$DESCRIPTION\"
echo \"NEXT_ID: MW-\$NEXT_ID\"
"

Now I'll clean up any dictated text in the title and description, then add the issue to the tracker.