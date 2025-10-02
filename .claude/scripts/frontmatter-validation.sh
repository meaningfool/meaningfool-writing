#!/bin/bash

VALIDATION_FAILED=0
MISSING_TITLE=()
MISSING_DATE=()
INVALID_DATE_FORMAT=()

# Find and validate all content files (exclude images directory and _draft directory)
for file in $(find . -type f -name "*.md" -not -path "./.*" -not -path "./images/*" -not -path "./_draft/*" | grep -v "^./[^/]*\.md$"); do
    if ! grep -q "^title:" "$file"; then
        MISSING_TITLE+=("$file")
        VALIDATION_FAILED=1
    fi

    if ! grep -q "^date:" "$file"; then
        MISSING_DATE+=("$file")
        VALIDATION_FAILED=1
    else
        # Check date format - must be exactly YYYY-MM-DD
        date_line=$(grep "^date:" "$file")
        if ! echo "$date_line" | grep -qE "^date: [0-9]{4}-[0-9]{2}-[0-9]{2}$"; then
            INVALID_DATE_FORMAT+=("$file")
            VALIDATION_FAILED=1
        fi
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
        echo ""
    fi

    if [[ ${#INVALID_DATE_FORMAT[@]} -gt 0 ]]; then
        echo "⚠️  Invalid date format (must be YYYY-MM-DD) in:"
        for file in "${INVALID_DATE_FORMAT[@]}"; do
            echo "   - $file"
        done
    fi

    exit 1
fi

echo "✅ Frontmatter validation passed! All articles have required title and date fields."
exit 0