---
name: context-optimizer
description: Use this skill to scan any project and recommend token-efficient improvements to how new AI agent sessions receive context. Supports Claude Code, Cursor, and Gemini CLI / Antigravity. Use when starting work on a project that doesn't have well-structured session-start context for AI agents.
---

## Purpose
When a developer opens a new Claude Code (or Cursor, or Gemini CLI / Antigravity) session in an existing project, the AI agent often starts with near-zero awareness of the project's identity, workflow, invariants, and current state. This "discovery overhead" forces the agent to spend the first 1–3 turns discovering basics, burning tokens, increasing latency, and diluting attention. `context-optimizer` solves this by diagnosing session-context gaps and recommending token-efficient improvements to ensure agents are productive from turn 1.

## When to Use This Skill
- Starting work on a project that does not have a `CLAUDE.md` or equivalent context file.
- Returning to a project after a long break where context might have drifted.
- Onboarding a new project that needs to support multiple agents (Claude Code, Cursor, Gemini).
- When you suspect existing context files are stale or inconsistent with the current project state.

## What This Skill Does NOT Do
- Provide mid-session memory or RAG-style retrieval for large codebases.
- Orchestrate complex multi-agent pipelines or automated workflow execution.
- Directly modify business logic or source code (it only writes context configuration files).

## Procedure

### Phase 1 — SCAN

**Purpose:** Build a complete picture of the project's current session-context infrastructure without asking the user anything.

**Inputs:** The project root directory (assumed to be the working directory at invocation).

**Procedure:**

1.  **Detect agent configurations.** Glob for the following files and directories. Record what's present, what's missing, and the size of each present file.
    *   **Claude Code:** `CLAUDE.md` (project root), `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/*`, `~/.claude/projects/<proj>/memory/MEMORY.md`
    *   **Cross-tool:** `AGENTS.md` (any version)
    *   **Cursor:** `.cursorrules` (legacy), `.cursor/rules/*.mdc`
    *   **Gemini CLI / Antigravity:** `GEMINI.md`, `.gemini/config.yaml`, `.gemini/styleguide.md`, `.agent/workflows/*.md`, `.agents/skills/SKILL.md`
    *   **Global user-level:** `~/.claude/settings.json` (read-only), `~/.claude/hooks/session-start.sh` (read-only)

2.  **Read all detected agent context files in full.** Read the content of all found context files. If a file read fails, note "partial scan" for that file and continue.

3.  **Read project manifest.** Detect and read the first found among: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `mix.exs`. Parse for project name, type, and summary (from description).

4.  **Read README.md (first 30 lines).** Extract project summary if no agent context file or manifest already provides it.

5.  **Query git metadata via Bash:**
    *   Run `git rev-parse --abbrev-ref HEAD` (current branch).
    *   Run `git log --oneline -5` (recent activity).
    *   Run `git status --short` (uncommitted changes).
    *   If not a git repository, skip these steps and note "Not a git repository — git metadata steps skipped."

6.  **Optionally query `gh` for in-flight state.** Only if `gh auth status` reports authenticated and project is a git repository:
    *   Run `gh issue list --state open --label "stage:development" --json number,title --limit 5`.
    *   Run `gh pr list --state open --json number,title,headRefName --limit 5`.
    *   If `gh` is not authenticated or not installed, or project is not a git repository, skip and note "Skipped" or "no gh auth".

7.  **Detect workflow / stage signals.** Apply the multi-signal heuristic:
    *   Numbered folders (`01-`, `02-`): weak (1)
    *   `output/` or `artifacts/` subdirectories: medium (2)
    *   `CONTEXT.md` files in subdirectories: strong (3)
    *   GitHub Actions with sequential job dependencies (`needs:` chains): strong (3)
    *   Labels with stage prefix (`stage:`, `phase:`, `pipeline:`): strong (3)
    *   README mentions workflow / pipeline / stages: medium (2)
    *   **Rule:** Total score ≥ 4 OR (≥ 1 strong signal AND ≥ 1 other signal) = recommend stage contracts.

8.  **Emit the Scan Report.** Produce a structured report delimited by `---SCAN-REPORT-START---` and `---SCAN-REPORT-END---`. The report MUST contain the following 7 sections:
    *   `## Detected Agent Platforms`: Status (✅/❌) and files found for Claude Code, Cursor, Gemini, and Cross-tool.
    *   `## Context File Details`: Summary of each detected file (lines, sections present).
    *   `## Hooks`: Status of project and global hooks.
    *   `## Memory`: Status of memory files and count of entries.
    *   `## Git`: Branch name, recent activity, or "Not a git repository".
    *   `## In-Flight State`: List of active issues/PRs or "Skipped".
    *   `## Stage Signals`: Table of detected signals and "Total signals" count. If signals < 3, include a warning about Phase 3 weak-state fallback.

### Phase 2 — DIAGNOSE
Stub: Evaluating detected configurations against identity, workflow, in-flight, startup, and duplication dimensions.

### Phase 3 — ASK
Stub: Asking targeted clarifying questions only when information cannot be inferred from the scan.

### Phase 4 — RECOMMEND
Stub: Generating prioritized recommendations with token cost, estimated savings, and mandatory Known Pattern mapping (or ad-hoc tagging).

### Phase 5 — IMPLEMENT
Stub: Applying approved recommendations via non-destructive merges (with cross-host caveats) and producing a context-spec.md audit record.
