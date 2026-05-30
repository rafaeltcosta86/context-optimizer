#!/bin/bash

# Read input from stdin
INPUT=$(cat)

# Check for delimiters
if [[ "$INPUT" != *"---ASK-REPORT-START---"* ]]; then
    echo "FAIL: Missing ---ASK-REPORT-START---"
    exit 1
fi

if [[ "$INPUT" != *"---ASK-REPORT-END---"* ]]; then
    echo "FAIL: Missing ---ASK-REPORT-END---"
    exit 1
fi

# Check for required metadata
if [[ "$INPUT" != *"**Mode:**"* ]]; then
    echo "FAIL: Missing Mode metadata"
    exit 1
fi

if [[ "$INPUT" != *"**Signal count:**"* ]]; then
    echo "FAIL: Missing Signal count metadata"
    exit 1
fi

# Check for required sections
SECTIONS=(
    "## Questions Asked"
    "## Answers Received"
)

for section in "${SECTIONS[@]}"; do
    if [[ "$INPUT" != *"$section"* ]]; then
        echo "FAIL: Missing $section"
        exit 1
    fi
done

# Check for completion marker
if [[ "$INPUT" != *"**Ask complete.**"* ]]; then
    echo "FAIL: Missing Ask complete marker"
    exit 1
fi

echo "PASS: ASK report structure verified"
exit 0
