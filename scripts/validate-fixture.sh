#!/bin/bash

# Read input from stdin
INPUT=$(cat)

# Check for delimiters
if [[ "$INPUT" != *"---SCAN-REPORT-START---"* ]]; then
    echo "FAIL: Missing ---SCAN-REPORT-START---"
    exit 1
fi

if [[ "$INPUT" != *"---SCAN-REPORT-END---"* ]]; then
    echo "FAIL: Missing ---SCAN-REPORT-END---"
    exit 1
fi

# Check for required sections (Phase 1 Scan Report)
SECTIONS=(
    "## Detected Agent Platforms"
    "## Context File Details"
    "## Hooks"
    "## Memory"
    "## Git"
    "## In-Flight State"
    "## Stage Signals"
)

for section in "${SECTIONS[@]}"; do
    if [[ "$INPUT" != *"$section"* ]]; then
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
    if [[ "$INPUT" != *"$assertion"* ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: all sections and assertions verified"
exit 0
