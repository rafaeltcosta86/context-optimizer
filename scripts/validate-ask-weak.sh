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

# Assertions for weak-state
ASSERTIONS=(
    "**Mode:** weak-state"
    "In one or two sentences, what does this project do?"
    "What are the rules a new agent must never break"
    "What changes most frequently in the active work"
    "**Ask complete.**"
)

for assertion in "${ASSERTIONS[@]}"; do
    if [[ "$INPUT" != *"$assertion"* ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: weak-state ASK report verified"
exit 0
