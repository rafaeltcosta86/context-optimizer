---DIAGNOSIS-REPORT-START---

# Diagnosis Report — acme-cli

**Source:** Scan Report for `examples/before/diagnose-fixture/`
**Status legend:** present-good · present-weak · missing · duplicated

---

## Context Health Score

Current: 4 / 10
After recommendations: 9 / 10  (+5)

| Platform     | Identity | Workflow | In-flight | Startup | Duplication | Score |
|--------------|----------|----------|-----------|---------|-------------|-------|
| Claude Code  | 10       | 10       | 4         | 0       | 6           | 6/10  |
| Cursor       | 0        | 4        | 0         | 0       | 10          | 3/10  |
| Cross-tool   | 4        | 10       | 0         | 0       | 6           | 4/10  |
| **Aggregate**|          |          |           |         |             | **4/10** |

> 2 P1 gaps blocking agent efficiency. Applying top P1+P2 recommendations brings score to 9/10.

---

## Dimension Evaluation

| Platform | Identity | Workflow | In-flight | Startup | Duplication |
|---|---|---|---|---|---|
| Claude Code | present-good | present-good | present-weak | missing | duplicated |
| Cursor | missing | present-weak | missing | missing | present-good |
| Cross-tool (AGENTS.md) | present-weak | present-good | missing | missing | duplicated |

---

## Layer 3/4 Contamination

| File | Status | Detail |
|---|---|---|
| `CLAUDE.md` | ⚠️ flagged | Static in-flight state `Current PR: #42` (Layer 4) inside a stable-identity file (Layer 3). Goes stale; emit via dynamic hook instead. |

---

## Canonical-Source Violations

| Rule | Appears in |
|---|---|
| "Never force-push to main" | `CLAUDE.md`, `AGENTS.md` |

---

## Size Compliance

| File | Lines | Limit | Status |
|---|---|---|---|
| `CLAUDE.md` | 13 | 150 | ✅ |
| `AGENTS.md` | 6 | 200 | ✅ |
| `.cursorrules` | 1 | 150 | ✅ |

---

## Auto-Load Coverage

| Orphan content | Location | Issue |
|---|---|---|
| Build / test commands | `docs/dev.md` | Not referenced from any auto-loaded (Layer 0) file — agent must discover it. |

---

## Diagnosis Summary

- Platforms evaluated: 3
- Gaps (missing + present-weak): 9
- Violations (contamination + canonical-source + size): 2
- Weak-state: No — usable signals ≥ 3

**Diagnosis complete.**

---DIAGNOSIS-REPORT-END---
