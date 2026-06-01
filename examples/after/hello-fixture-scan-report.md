---SCAN-REPORT-START---

# Scan Report — my-hello-app

**Scanned:** `examples/before/hello-fixture/`
**Project type:** npm package (`package.json` → name: `my-hello-app`)
**Summary:** A simple hello world CLI application.

---

## Detected Agent Platforms

| Platform | Status | Files found |
|---|---|---|
| Claude Code | ✅ present | `CLAUDE.md` (5 lines) |
| Cursor | ❌ absent | `.cursorrules` — not found; `.cursor/rules/` — not found |
| Gemini CLI / Antigravity | ❌ absent | `GEMINI.md` — not found; `.gemini/` — not found |
| Cross-tool | ❌ absent | `AGENTS.md` — not found |

---

## Context File Details

### `CLAUDE.md` (5 lines)
- Has startup section: **No**
- Has workflow rules: **No**
- Has invariants: **No**
- Content: project name + 2-line description only

---

## Hooks

| Hook | Status |
|---|---|
| `.claude/hooks/` | ❌ not found |
| Global `~/.claude/hooks/session-start.sh` | ❌ not found |

---

## Memory

- `~/.claude/projects/*/memory/MEMORY.md`: ❌ not found
- Memory entries: 0

---

## Git

**Not a git repository** — git metadata steps skipped.

---

## In-Flight State (gh)

**Skipped** — project is not a git repository.

---

## Stage Signals

| Signal type | Detected |
|---|---|
| Agent config with workflow rules | ❌ |
| Stage-gate labels (gh) | skipped |
| Sequential folders or numbered stages | ❌ |
| Hook emitting in-flight state | ❌ |

**Total signals: 0**

> ⚠️ Signal count < 3 — Phase 3 will trigger the weak-state fallback (3-question dialog).

**→ Scan complete. Proceeding to Phase 2 — DIAGNOSE immediately.**

---SCAN-REPORT-END---
