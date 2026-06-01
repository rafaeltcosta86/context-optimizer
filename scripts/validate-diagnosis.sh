#!/bin/bash

# Read input from stdin
INPUT=$(cat)

# Check for delimiters
if [[ "$INPUT" != *"---DIAGNOSIS-REPORT-START---"* ]]; then
    echo "FAIL: Missing ---DIAGNOSIS-REPORT-START---"
    exit 1
fi

if [[ "$INPUT" != *"---DIAGNOSIS-REPORT-END---"* ]]; then
    echo "FAIL: Missing ---DIAGNOSIS-REPORT-END---"
    exit 1
fi

# Check for required sections (Phase 2 Diagnosis Report)
SECTIONS=(
    "## Context Health Score"
    "## Dimension Evaluation"
    "## Layer 3/4 Contamination"
    "## Canonical-Source Violations"
    "## Size Compliance"
    "## Auto-Load Coverage"
    "## Diagnosis Summary"
)

for section in "${SECTIONS[@]}"; do
    if [[ "$INPUT" != *"$section"* ]]; then
        echo "FAIL: Missing $section"
        exit 1
    fi
done

# diagnose-fixture specific assertions
ASSERTIONS=(
    "After recommendations:"
    "P1 gaps blocking agent efficiency"
    "duplicated"
    "Current PR: #42"
    "Never force-push to main"
    "Diagnosis complete."
    "**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**"
)

for assertion in "${ASSERTIONS[@]}"; do
    if [[ "$INPUT" != *"$assertion"* ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: all sections and assertions verified"
exit 0
