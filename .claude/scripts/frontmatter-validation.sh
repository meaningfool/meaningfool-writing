#!/bin/bash

VALIDATION_FAILED=0
MISSING_TITLE=()
MISSING_DATE=()

# Find and validate all content files
for file in $(find . -type f -name "*.md" -not -path "./.*" | grep -v "^./[^/]*\.md$"); do
    if ! grep -q "^title:" "$file"; then
        MISSING_TITLE+=("$file")
        VALIDATION_FAILED=1
    fi

    if ! grep -q "^date:" "$file"; then
        MISSING_DATE+=("$file")
        VALIDATION_FAILED=1
    fi
done

# Report validation results
if [[ $VALIDATION_FAILED -eq 1 ]]; then
    echo "❌ Frontmatter validation failed!"
    echo ""

    if [[ ${#MISSING_TITLE[@]} -gt 0 ]]; then
        echo "📝 Missing 'title' field in:"
        for file in "${MISSING_TITLE[@]}"; do
            echo "   - $file"
        done
        echo ""
    fi

    if [[ ${#MISSING_DATE[@]} -gt 0 ]]; then
        echo "📅 Missing 'date' field in:"
        for file in "${MISSING_DATE[@]}"; do
            echo "   - $file"
        done
    fi

    exit 1
fi

exit 0