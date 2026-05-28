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
    "## Dimension Evaluation"
    "## Layer 3/4 Contamination"
    "## Canonical-Source Violations"
    "## Size Compliance"
    "## Auto-Load Coverage"
    "## Diagnosis Summary"
)

for section in "${SECTIONS[@]}"; do
    if [[ "$INPUT" != *"$section"* ]]; then
        echo "FAIL: Missing section: $section"
        exit 1
    fi
done

# Fixture-specific assertions
ASSERTIONS=(
    "diagnose-fixture"
    "duplicated"
    "CLAUDE.md"
    "AGENTS.md"
    "Always write tests before code."
    "docs/dev.md"
    "250 lines"
    "stale"
)

for assertion in "${ASSERTIONS[@]}"; do
    if [[ "$INPUT" != *"$assertion"* ]]; then
        echo "FAIL: Missing assertion: $assertion"
        exit 1
    fi
done

echo "PASS: all sections and assertions verified"
exit 0
