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

# Phase 1 emits only a status line — no scan report block in output
assert_contains "*Scanning project structure...*" "Missing Phase 1 status line"
assert_contains "---DIAGNOSIS-REPORT-START---" "Missing DIAGNOSIS-REPORT-START"
assert_contains "---DIAGNOSIS-REPORT-END---" "Missing DIAGNOSIS-REPORT-END"
assert_contains "---ASK-REPORT-START---" "Missing ASK-REPORT-START"
assert_contains "---ASK-REPORT-END---" "Missing ASK-REPORT-END"

# Check for the automatic transition anchor
assert_contains "**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**" "Missing Diagnosis-to-Ask anchor"

# Check that Phase 2→3 transition is consecutive — no text between closing and opening delimiters.
# Any intervening text (including blank lines) means the LLM stopped between phases.
assert_consecutive() {
  local end_delimiter="$1"
  local start_delimiter="$2"
  local error_msg="$3"
  if ! printf '%s\n' "$INPUT" | sed -n "/^${end_delimiter}$/{n;/^${start_delimiter}$/p;}" | grep -q .; then
    echo "FAIL: $error_msg" >&2
    exit 1
  fi
}

assert_consecutive "---DIAGNOSIS-REPORT-END---" "---ASK-REPORT-START---" \
  "Phase 2→3 transition broken: text or blank line between ---DIAGNOSIS-REPORT-END--- and ---ASK-REPORT-START---"

echo "PASS: Chained output verified"
exit 0
