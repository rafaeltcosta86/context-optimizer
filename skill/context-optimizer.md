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
Stub: Scanning project context files, manifest files, and git metadata.

### Phase 2 — DIAGNOSE
Stub: Evaluating detected configurations against identity, workflow, in-flight, startup, and duplication dimensions.

### Phase 3 — ASK
Stub: Asking targeted clarifying questions only when information cannot be inferred from the scan.

### Phase 4 — RECOMMEND
Stub: Generating prioritized recommendations with token cost, estimated savings, and mandatory Known Pattern mapping (or ad-hoc tagging).

### Phase 5 — IMPLEMENT
Stub: Applying approved recommendations and producing a `context-spec.md` audit record.
