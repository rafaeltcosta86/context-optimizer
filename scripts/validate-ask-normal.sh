#!/bin/bash
set -euo pipefail

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

# Assertions for normal-state
ASSERTIONS=(
    "**Mode:** normal-state"
    "**Signal count:** 3"
    "dynamic in-flight queries"
    "static roadmap file"
    "**Ask complete.**"
)

for assertion in "${ASSERTIONS[@]}"; do
    if [[ "$INPUT" != *"$assertion"* ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: normal-state ASK report verified"
exit 0
