#!/bin/bash

# Read input from stdin
INPUT=$(cat)

# Phase 1 output must contain the status line
if [[ "$INPUT" != *"*Scanning project structure...*"* ]]; then
    echo "FAIL: Missing Phase 1 status line (*Scanning project structure...*)"
    exit 1
fi

# Phase 1 must NOT emit a scan report block (issue #33 regression guard)
if [[ "$INPUT" == *"---SCAN-REPORT-START---"* ]]; then
    echo "FAIL: Phase 1 emitted ---SCAN-REPORT-START--- — scan report must be suppressed"
    exit 1
fi

echo "PASS: all sections and assertions verified"
exit 0
