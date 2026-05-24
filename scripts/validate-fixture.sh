#!/bin/bash

# Read input from stdin
INPUT=$(cat)

# Check for delimiters
if [[ ! "$INPUT" =~ "---SCAN-REPORT-START---" ]]; then
    echo "FAIL: Missing ---SCAN-REPORT-START---"
    exit 1
fi

if [[ ! "$INPUT" =~ "---SCAN-REPORT-END---" ]]; then
    echo "FAIL: Missing ---SCAN-REPORT-END---"
    exit 1
fi

# Check for required sections
SECTIONS=(
    "## Project Snapshot"
    "## Diagnosis Summary"
    "## Applied Recommendations"
    "## Declined Recommendations"
    "## Out of Scope (Deliberately Not Touched)"
    "## Known Patterns Referenced"
    "## Ad-Hoc Recommendations"
)

for section in "${SECTIONS[@]}"; do
    if [[ ! "$INPUT" =~ "$section" ]]; then
        echo "FAIL: Missing $section"
        exit 1
    fi
done

# Hello-fixture specific assertions
ASSERTIONS=(
    "my-hello-app"
    "npm"
    "Not a git repository"
    "Total signals: 0"
)

for assertion in "${ASSERTIONS[@]}"; do
    if [[ ! "$INPUT" =~ "$assertion" ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: all sections and assertions verified"
exit 0
