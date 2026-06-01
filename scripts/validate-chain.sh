#!/bin/bash
set -euo pipefail

# Read input from stdin
INPUT=$(cat)

assert_contains() {
  local substring="$1"
  local error_msg="$2"
  if [[ "$INPUT" != *"$substring"* ]]; then
    echo "FAIL: $error_msg" >&2
    exit 1
  fi
}

assert_contains "---SCAN-REPORT-START---" "Missing SCAN-REPORT"
assert_contains "---SCAN-REPORT-END---" "Missing SCAN-REPORT-END"
assert_contains "---DIAGNOSIS-REPORT-START---" "Missing DIAGNOSIS-REPORT"
assert_contains "---DIAGNOSIS-REPORT-END---" "Missing DIAGNOSIS-REPORT-END"
assert_contains "---ASK-REPORT-START---" "Missing ASK-REPORT"
assert_contains "---ASK-REPORT-END---" "Missing ASK-REPORT-END"

# Check for the automatic transition anchors
assert_contains "**→ Scan complete. Proceeding to Phase 2 — DIAGNOSE immediately.**" "Missing Scan-to-Diagnose anchor"
assert_contains "**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**" "Missing Diagnosis-to-Ask anchor"

# Check that phase transitions are consecutive — no text between closing and opening delimiters.
# The line immediately after ---SCAN-REPORT-END--- must be ---DIAGNOSIS-REPORT-START---.
# The line immediately after ---DIAGNOSIS-REPORT-END--- must be ---ASK-REPORT-START---.
# Any intervening text (including blank lines) means the LLM stopped between phases.
assert_consecutive() {
  local end_delimiter="$1"
  local start_delimiter="$2"
  local error_msg="$3"
  if ! echo "$INPUT" | grep -A1 "^${end_delimiter}$" | grep -q "^${start_delimiter}$"; then
    echo "FAIL: $error_msg" >&2
    exit 1
  fi
}

assert_consecutive "---SCAN-REPORT-END---" "---DIAGNOSIS-REPORT-START---" \
  "Phase 1→2 transition broken: text or blank line between ---SCAN-REPORT-END--- and ---DIAGNOSIS-REPORT-START---"

assert_consecutive "---DIAGNOSIS-REPORT-END---" "---ASK-REPORT-START---" \
  "Phase 2→3 transition broken: text or blank line between ---DIAGNOSIS-REPORT-END--- and ---ASK-REPORT-START---"

echo "PASS: Chained output verified"
exit 0
