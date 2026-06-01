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

assert_contains "---RECOMMEND-REPORT-START---" "Missing RECOMMEND-REPORT"
assert_contains "---RECOMMEND-REPORT-END---" "Missing RECOMMEND-REPORT-END"
assert_contains "Turns saved" "Missing Turns saved metric"
assert_contains "Token cost" "Missing Token cost metric"
assert_contains "turns/session" "Missing turns/session unit"
assert_contains "tokens/session" "Missing tokens/session unit"
assert_contains "suppressed" "Missing suppressed recommendations note"

echo "PASS: Recommendation report verified"
exit 0
