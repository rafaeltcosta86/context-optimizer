*Scanning project structure...*
---DIAGNOSIS-REPORT-START---

# Diagnosis Report — acme-cli

**Source:** Phase 1 scan of `examples/before/diagnose-fixture/`
**Status legend:** present-good · present-weak · missing · duplicated

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
**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**

---DIAGNOSIS-REPORT-END---
---ASK-REPORT-START---

# Ask Report — acme-cli

**Mode:** normal-state
**Signal count:** 3

## Questions Asked

1. Do you want dynamic in-flight queries (requires `gh auth login`) or a static roadmap file (you maintain manually)?

## Answers Received

1. Static roadmap file.

**Ask complete.**

---ASK-REPORT-END---
---RECOMMEND-REPORT-START---

# Recommendation Report — acme-cli

| ID | Title | Turns saved | Token cost |
|---|---|---|---|
| R-1 | Add dynamic gh hook | 2–4 turns/session | +30 tokens/session (~0.02s latency, negligible) |
| R-2 | Implement stage-contract | 3–5 turns/session | +120 tokens/session (~0.1s latency, negligible) |

> ℹ️ 3 recommendations (R-3, R-4, R-5) were suppressed as they save < 3 turns each. They will be logged in `context-spec.md`.

**→ Recommendations generated. Waiting for user approval to proceed to Phase 5 — IMPLEMENT.**

---RECOMMEND-REPORT-END---
