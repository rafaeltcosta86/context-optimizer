# Context-Optimizer — Product Specification

This directory contains the complete product specification for `context-optimizer` — a **host-portable skill** that scans any project and recommends token-efficient context optimizations for new AI agent sessions. **v1.0 ships as a Claude Code skill;** v1.1 (Cursor) and v1.2 (Gemini CLI / Antigravity) follow. The user installs it in whichever host they use for a given project — same procedure, host-native invocation.

**Status:** Specification phase. Implementation has not started.

---

## What `context-optimizer` Is

A host-native invocable skill that acts as a session-context optimization consultant for any project. It scans an existing project, diagnoses gaps in how new AI agent sessions receive context, and recommends targeted, token-efficient improvements.

**Typical use:** one project, one host. A user developing Project A in Claude Code invokes the Claude Code version of the skill on Project A. The same user developing Project B in Cursor invokes the Cursor version on Project B. Same procedure, host-native outputs.

**Edge case:** a single project with context files for multiple hosts (e.g., both `CLAUDE.md` and `.cursorrules`) — the skill optimizes all detected configs, applying caveat lines to anything outside its current host.

It is **not** a workflow framework, **not** a RAG infrastructure, **not** a benchmark-based search tool, and **not** a cross-channel personal AI assistant. See `COMPETITIVE_ANALYSIS.md` for explicit boundaries.

---

## Version Scope at a Glance

| Version | Scope | Status |
|---|---|---|
| **v1.0** (this spec's primary scope) | Claude Code skill — scan-first session-start optimization | Ready for implementation |
| **v1.1** | Cursor port — same procedure, Cursor-native invocation | High-level path documented; build after v1.0 |
| **v1.2** | Gemini CLI / Antigravity port | High-level path documented; build after v1.0 |
| **v2.0** | Organic memory growth via `save_project_fact` tool (OpenClaw-inspired pattern) | **Lower priority — deferred**. See `PRD.md` §12.2 and `ARCHITECTURE.md` §13. Do NOT build until v1.0 is in community use. |

**Implementing agents must complete v1.0 first before any v1.x or v2.0 work.**

---

## How to Read This Specification

Read in this order:

| # | File | Why |
|---|---|---|
| 1 | `README.md` (this file) | Orientation, reading order, version scope, glossary |
| 2 | `PRD.md` | Problem, vision, users, goals, non-goals, measurable success criteria, release roadmap |
| 3 | `COMPETITIVE_ANALYSIS.md` | What `context-optimizer` is NOT, positioning vs. 7 alternatives, scope boundaries |
| 4 | `ARCHITECTURE.md` | 5-phase skill design, detection signals, layer model, per-host adapters, data flow, v2.0 design sketch |
| 5 | `IMPLEMENTATION_GUIDE.md` | Phased build plan for v1.0, which specialist skills to invoke at each step, validation gates, post-v1.0 ports |

**Recommended workflow for the implementing agent:**

1. Read all 5 files end-to-end before starting (no shortcuts — the design has nuances that compound)
2. Invoke `superpowers:writing-plans` to author an implementation plan based on `IMPLEMENTATION_GUIDE.md` (v1.0 scope only)
3. Get user approval on the implementation plan
4. Execute phase by phase as described in `IMPLEMENTATION_GUIDE.md` §3 (Build Phases 1–5)
5. Use specialist skills at each step as mapped in `IMPLEMENTATION_GUIDE.md` §2
6. Run the verification checklist in `PRD.md` §2.3 (success criteria) before declaring done
7. **Do not start v1.1 / v1.2 / v2.0 until v1.0 is shipped and validated**

---

## Glossary

| Term | Meaning |
|---|---|
| **Session-start context** | Information available to an AI agent at the moment a new conversation begins in a project, before any user message |
| **Context file** | Any file an AI agent reads automatically or is instructed to read on session start (e.g., `CLAUDE.md`, `GEMINI.md`, `.cursorrules`) |
| **Host** | The AI agent environment from which the skill is invoked (Claude Code, Cursor, Gemini CLI / Antigravity). One project = one primary host in the typical case. |
| **Host-portable skill** | A skill whose procedure is host-agnostic but whose invocation and write paths are host-native. v1.0 ships as a Claude Code skill; v1.1 and v1.2 port the same procedure to Cursor and Gemini/Antigravity. |
| **Layer 0–4** | Tiered context loading model: Layer 0 = always loaded; Layer 1 = task routing; Layer 2 = workspace context; Layer 3 = stable reference (factory); Layer 4 = run-specific artifacts (product). Borrowed from ICM. |
| **In-flight state** | What's actively being worked on right now — open issues, current PR, active branch. Volatile. Layer 4. |
| **Stable identity** | Facts about the project that don't change between sessions — purpose, stack, invariants, workflow rules. Layer 3. |
| **Token ROI** | Cost in tokens added per session vs. tokens saved per session by avoiding discovery. Presented as numbers, never enforced as a threshold. |
| **Proposer prior** | The skill's encoded knowledge of what context patterns work well. Versioned in the skill file itself as a `Known Patterns` section. |
| **Caveat line** | A comment in a generated file declaring that the file was written by the skill from outside that host's environment and may need user verification. Required only for cross-host generation. |
| **Organic memory growth (v2.0)** | The deferred v2.0 capability in which the host agent calls a `save_project_fact` tool during real work to add stable facts to memory. Inspired by the OpenClaw memory-management pattern. |

---

## Source Conversation

This spec consolidates approximately 3 hours of design conversation including:
- The original session-context problem analysis on the `agentic-pdlc` project
- Three-way competitive comparison with CAR, ICM, and meta-harness
- Discovery search for direct competitors on GitHub (Continuous Claude, CCv3, claude-code-dotfiles)
- OpenClaw memory-management pattern analysis (deferred to v2.0)
- Five iterations of self-protection design for known flaws
- Clarification on multi-host positioning (per-project host choice, not parallel agents)

Every design decision from that conversation is encoded somewhere in these 5 files. If you find ambiguity, treat it as a bug in this spec — surface it via a clarifying question before implementing.

---

## License

To be added at project initialization. Suggested: MIT (matches comparable community tools).
