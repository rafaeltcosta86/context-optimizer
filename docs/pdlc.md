# PDLC — context-optimizer

## Board Columns

| Column | Meaning | Who moves the card |
|---|---|---|
| 💡 Idea — don't move manually to Exploration | Backlog — tell agent: "work on issue #XX" | Don't move manually |
| 🔍 Exploration | Claude is analyzing code and context | Label `stage:exploration` |
| 🧠 Brainstorming | Claude proposed approaches, awaiting PM gate | Label `stage:brainstorming` |
| 📐 Detail Solution | Claude is writing the technical spec | Label `stage:detailing` |
| ✅ Approval | Spec ready, awaiting `spec:approved` label | Label `spec:approval` (auto when spec complete) |
| ⚙️ Development | Jules implementing the spec | Label `stage:development` (via agent-trigger.yml) |
| 🧪 Testing | QA Agent verifying AC coverage (Variant B) | GitHub Actions (qa-agent.yml) |
| 👁 Code Review / PR | QA approved, awaiting human review | GitHub Actions (on qa:approved label) |
| 🚀 Ready for Production | Merged to main | GitHub Actions (on PR merge) |

## Workflow Variants (QA Agent)

- **Variant B (Active):** PRs land in the `Testing` column first. The AI QA Agent (`qa-agent.yml`) verifies AC coverage via GitHub Models (gpt-4o-mini). On `qa:approved` label, the issue moves to `Code Review / PR`. On `qa:needs-work`, the agent must fix and re-push.

## Board Identifiers (GitHub Projects)

> ⚠️ **PENDING:** Board not yet created. Replace `{{PROJECT_ID}}` and `{{STATUS_FIELD_ID}}` with real values after creating the board and running `gh auth login --scopes project`.

```
PROJECT_ID   = {{PROJECT_ID}}
STATUS_FIELD = {{STATUS_FIELD_ID}}
REPO         = rafaeltcosta86/context-optimizer
```

## Column Option IDs

> ⚠️ **PENDING:** Fill these IDs after board creation. Query with:
> `gh api graphql -f query='{ node(id: "PROJECT_ID") { ... on ProjectV2 { fields(first:20) { nodes { ... on ProjectV2SingleSelectField { name options { id name } } } } } } }'`

| Column | Option ID |
|---|---|
| 💡 Idea | `{{ID_IDEA}}` |
| 🔍 Exploration | `{{ID_EXPLORATION}}` |
| 🧠 Brainstorming | `{{ID_BRAINSTORMING}}` |
| 📐 Detail Solution | `{{ID_DETAILING}}` |
| ✅ Approval | `{{ID_APPROVAL}}` |
| ⚙️ Development | `{{ID_DEVELOPMENT}}` |
| 🧪 Testing | `{{ID_TESTING}}` |
| 👁 Code Review / PR | `{{ID_CODE_REVIEW_PR}}` |
| 🚀 Ready for Production | `{{ID_PRODUCTION}}` |

## Agent × Phase Mapping

| Phase | Responsible |
|---|---|
| 💡 → 📐 (upstream) | Claude Code in conversational session (you + this session) |
| ⚙️ → 🔀 (downstream) | @google-labs-jules (triggered automatically on `spec:approved`) |
| 🧪 Testing | QA Agent (GitHub Models / gpt-4o-mini, via `qa-agent.yml`) |
| 👁 Code Review / PR | Human (you) |
| Automatic transitions | GitHub Actions |

## Issue Title Conventions

```
[type:us]   feat: <feature description>      ← user story / new behavior
[type:task] chore: <operational change>      ← non-user-facing
[type:bug]  fix: <what is broken>            ← regression / broken behavior
[type:spike] spike: <research question>      ← never reaches Development
```

## Definition of Done (per issue)

A feature is done when:
1. All Acceptance Criteria in the issue body are met
2. Phase 1 fixture test: `examples/after/<fixture>-report.md` matches actual skill output
3. CI passes (Sentinel / CI + Stage Gate)
4. QA Agent returns `qa:approved`
5. Human code review approved
6. PR merged to `main` with `Closes #N` in body
7. Card is at 🚀 Ready for Production on the board

## Pipeline Updates

To add or configure optional agents (Jules, QA Agent, Sentinel):

```bash
npx create-agentic-pdlc --update
```
