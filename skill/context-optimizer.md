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
    *   **Reference files:** any `*.md` files outside the agent config globs above (e.g. `docs/*.md`, `CONTRIBUTING.md`, `README.md`). Record path and line count; read on demand in Step 2.

2.  **Read all detected agent context files in full.** Read the content of all found context files. If a file read fails, note "partial scan" for that file and continue.

3.  **Read project manifest.** Detect and read the first found among: `package.json` (npm), `pyproject.toml` (python), `Cargo.toml` (rust), `go.mod` (go), `mix.exs` (elixir). Parse for project name, type, and summary (from description).

4.  **Read README.md (first 30 lines).** Extract project summary if no agent context file or manifest already provides it.

5.  **Query git metadata via Bash:**
    *   First, check if the current directory is a git root (defining the "git repository" status for the entire scan): `test -e .git`.
    *   If the check passes:
        *   Run `git rev-parse --abbrev-ref HEAD` (current branch).
        *   Run `git log --oneline -5` (recent activity).
        *   Run `git status --short` (uncommitted changes).
    *   If the check fails, skip these steps and note "Not a git repository — git metadata steps skipped." The project is not a git repository for the purpose of all remaining steps.

6.  **Optionally query `gh` for in-flight state.** Only if the Step 5 `test -e .git` check passed AND `gh auth status` reports authenticated:
    *   Run `gh issue list --state open --json number,title --limit 5`.
    *   Run `gh pr list --state open --json number,title,headRefName --limit 5`.
    *   If `gh` is not authenticated or not installed, or Step 5 check failed, skip and note "Skipped" or "no gh auth".

7.  **Detect workflow / stage signals.** Apply the multi-signal heuristic:
    *   Numbered folders (`01-`, `02-`): weak (1)
    *   `output/` or `artifacts/` subdirectories: medium (2)
    *   `CONTEXT.md` files in subdirectories: strong (3)
    *   GitHub Actions with sequential job dependencies (`needs:` chains): strong (3)
    *   Labels with stage prefix (`stage:`, `phase:`, `pipeline:`): strong (3)
    *   README mentions workflow / pipeline / stages: medium (2)
    *   **Rule:** Total score ≥ 4 = recommend stage contracts. (Note: strong=3pts, medium=2pts, weak=1pt — this is a weighted score, not a signal count. The weak-state threshold in Step 8 uses raw signal count, a separate metric.)

8.  **Emit the Scan Report.** Produce a structured report delimited by `---SCAN-REPORT-START---` and `---SCAN-REPORT-END---`. The report MUST start with a `# Scan Report — {project name}` header, followed by project metadata (Scanned path, Project type, and Summary), and then these 7 mandatory sections:
    *   `## Detected Agent Platforms`: Status (✅/❌) and files found for Claude Code, Cursor, Gemini, and Cross-tool.
    *   `## Context File Details`: Summary of each detected file (lines, sections present).
    *   `## Hooks`: Status of project and global hooks.
    *   `## Memory`: Status of memory files and count of entries.
    *   `## Git`: Branch name, recent activity, or "Not a git repository".
    *   `## In-Flight State`: List of active issues/PRs or "Skipped".
    *   `## Stage Signals`: Table of detected signals and a final summary line using the format: **Total signals: {N}**. If N < 3, include a warning about Phase 3 weak-state fallback.

### Phase 2 — DIAGNOSE

**Purpose:** Evaluate the Scan Report against 5 dimensions and 4 cross-cutting diagnostics, then emit a structured Diagnosis Report consumed by Phases 3–5. This phase is **read-only** — never write project files here.

**Inputs:** The Scan Report emitted in Phase 1.

**Procedure:**

1.  **Evaluate the 5 dimensions per detected platform.** For each platform in the Scan Report (Claude Code, Cursor, Gemini, Cross-tool/`AGENTS.md`), assign each dimension one status: `present-good`, `present-weak`, `missing`, or `duplicated`.
    *   **Identity:** Does a context file state what the project IS (purpose + type) in its first lines? Full summary → `present-good`; named but no purpose → `present-weak`; absent → `missing`.
    *   **Workflow:** Are mandatory steps, stage gates, or build/test commands documented? Complete → `present-good`; coding-style-only / partial → `present-weak`; absent → `missing`.
    *   **In-flight:** Does the agent see active work? Dynamic SessionStart `gh` hook → `present-good`; static roadmap or "Current PR/issue" line (goes stale) → `present-weak`; none → `missing`.
    *   **Startup:** Is there an explicit "Read X first" / "Run Y on start"? Present → `present-good`; absent → `missing`.
    *   **Duplication:** Does a rule in this file also appear verbatim in another context file? If yes → `duplicated`; if the file's rules are unique → `present-good`. (`duplicated` is a violation, not a gap — it counts toward canonical-source violations, not the gap total.)

2.  **Layer 3/4 contamination check.** Flag any context file mixing stable identity/invariants (Layer 3) with volatile in-flight state (Layer 4) — e.g. a static `Current PR: #N`, "active issue", or "this week's priorities" line inside `CLAUDE.md`/`AGENTS.md`/memory. Report file + offending content + fix (emit via dynamic hook).

3.  **Canonical-source check.** For each non-trivial rule (workflow step, invariant, any "always"/"never" statement), count occurrences across all context files. ≥2 files = violation. Report rule text + the files.

4.  **Size compliance check.** Compare each context file's line count to its limit. Limits by file type:
    *   `CLAUDE.md` — 150 lines
    *   `AGENTS.md` — 200 lines
    *   `GEMINI.md` — 150 lines
    *   `.cursorrules` — 150 lines
    *   Any `.cursor/rules/*.mdc` — 150 lines
    *   Any `CONTEXT.md` — 80 lines
    *   Any other reference file (`docs/`, etc.) — 200 lines
    Report file, lines, limit, ✅ (within) or ⚠️ (over).

5.  **Auto-load coverage check.** Identify rules/commands living only in a non-auto-loaded file (not Layer 0) and not referenced/summarized from the auto-loaded layer. Report each orphan + its location.

6.  **Emit the Diagnosis Report.** Produce a block delimited by `---DIAGNOSIS-REPORT-START---` and `---DIAGNOSIS-REPORT-END---`. Start with `# Diagnosis Report — {project name}`, then two metadata lines: `**Source:** Scan Report for {scanned path}` and `**Status legend:** present-good · present-weak · missing · duplicated`. Then these 6 sections in order:
    *   `## Dimension Evaluation` — one row per detected platform, columns: `Platform | Identity | Workflow | In-flight | Startup | Duplication`.
    *   `## Layer 3/4 Contamination` — columns `File | Status | Detail`; render `✅ None detected` when clean.
    *   `## Canonical-Source Violations` — columns `Rule | Appears in`; render `✅ None detected` when clean.
    *   `## Size Compliance` — columns `File | Lines | Limit | Status`.
    *   `## Auto-Load Coverage` — columns `Orphan content | Location | Issue`; render `✅ Full coverage` when clean.
    *   `## Diagnosis Summary` — reports: platforms evaluated, gaps (count of `missing` + `present-weak`), violations (contamination + canonical-source + size), and weak-state Yes/No (usable signals < 3).

    End with `**Diagnosis complete.**`.

### Phase 3 — ASK
Stub: Asking targeted clarifying questions only when information cannot be inferred from the scan.

### Phase 4 — RECOMMEND
Stub: Generating prioritized recommendations with token cost, estimated savings, and mandatory Known Pattern mapping (or ad-hoc tagging).

### Phase 5 — IMPLEMENT
Stub: Applying approved recommendations via non-destructive merges (with cross-host caveats) and producing a context-spec.md audit record.
