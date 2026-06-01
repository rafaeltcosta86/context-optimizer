#!/bin/bash
set -euo pipefail

# Read input from stdin
INPUT=$(cat)

# Check for all three reports
if [[ "$INPUT" != *"---SCAN-REPORT-START---"* ]]; then echo "FAIL: Missing SCAN-REPORT"; exit 1; fi
if [[ "$INPUT" != *"---SCAN-REPORT-END---"* ]]; then echo "FAIL: Missing SCAN-REPORT-END"; exit 1; fi

if [[ "$INPUT" != *"---DIAGNOSIS-REPORT-START---"* ]]; then echo "FAIL: Missing DIAGNOSIS-REPORT"; exit 1; fi
if [[ "$INPUT" != *"---DIAGNOSIS-REPORT-END---"* ]]; then echo "FAIL: Missing DIAGNOSIS-REPORT-END"; exit 1; fi

if [[ "$INPUT" != *"---ASK-REPORT-START---"* ]]; then echo "FAIL: Missing ASK-REPORT"; exit 1; fi
if [[ "$INPUT" != *"---ASK-REPORT-END---"* ]]; then echo "FAIL: Missing ASK-REPORT-END"; exit 1; fi

# Check for the automatic transition anchors
if [[ "$INPUT" != *"**→ Scan complete. Proceeding to Phase 2 — DIAGNOSE immediately.**"* ]]; then
    echo "FAIL: Missing Scan-to-Diagnose anchor"
    exit 1
fi

if [[ "$INPUT" != *"**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**"* ]]; then
    echo "FAIL: Missing Diagnosis-to-Ask anchor"
    exit 1
fi

echo "PASS: Chained output verified"
exit 0
