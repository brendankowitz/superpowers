# Copilot Workflow Skill Design

A single additive skill — `copilot-workflow` — that surfaces GitHub Copilot CLI-specific
workflow enhancements without modifying any existing skills.

## Motivation

GitHub Copilot CLI has three capabilities with no equivalent on other platforms that
Superpowers can meaningfully leverage:

1. **Model selection** — multiple named models with different cost/capability profiles
2. **`store_memory`** — native cross-session persistence built into the tool itself
3. **Plan mode + `exit_plan_mode`** — explicit read-only planning phase with a hard gate to execution

These are purely additive. Existing skills are unchanged.

## Skill

**File:** `skills/copilot-workflow/SKILL.md`

**Description:** `"Use when running on GitHub Copilot CLI — model selection guidance, cross-session memory for workflow state and project preferences, and native plan mode integration"`

**Discovery:** A one-line pointer is added to `skills/using-superpowers/references/copilot-tools.md`:
> "For workflow enhancements (model guidance, memory, plan mode), see the `copilot-workflow` skill."

## Section 1: Model Guidance

Suggestions only — never mandates. The agent surfaces the recommendation and the user switches
via `/model <name>` if they agree.

| Phase | Recommended model | Reason |
|---|---|---|
| `brainstorming` | gpt5.4, opus 4.6 | Creative exploration and design space work |
| `writing-plans` | opus 4.6, sonnet 4.6, codex 5.3 | Methodical task decomposition |
| `executing-plans` subagents — single file / routine | gemini flash, haiku 4.6 | Straightforward edits; saves cost and time |
| `executing-plans` subagents — complex / multi-file | sonnet 4.6, codex 5.3 | More context needed for larger changes |
| Code review | opus 4.6 | Most capable catches the most issues |
| Debugging | opus 4.6, sonnet 4.6 | Structured reasoning through complex logic |

The skill text: *"Consider switching via `/model <name>` before entering this phase. These are
suggestions — use judgment based on task complexity."*

## Section 2: Memory Management

Two namespaces, both scoped to the current project. Keys use the format
`superpowers:<namespace>:<repo-name>` where `repo-name` is derived from the git remote URL or
the directory name as a fallback (e.g., `superpowers:workflow:myproject`).

### Workflow state — `superpowers:workflow`

Transient. Tracks active Superpowers flow progress.

| Trigger | What is stored |
|---|---|
| Brainstorming completes | Design doc path, key architectural decisions |
| Writing-plans completes | Plan file path, total task count |
| Executing-plans checkpoint | Current task number, any blocking issues |
| Flow complete | Clear workflow state |

**At session start:** Check for existing workflow state. If found, surface it:
> "You have an in-progress Superpowers workflow: [plan file], task 3 of 7. Resume?"

### Project preferences — `superpowers:preferences`

Durable. Accumulates as the agent learns conventions in the repo.

What gets stored as it is learned:
- Coding conventions (e.g., "functional style", "no classes")
- Preferred patterns (e.g., "explicit error handling, no silent catches")
- Communication preferences (e.g., "concise responses, no preamble")

**At session start:** Recall silently and apply — no prompt to the user unless something is
ambiguous.

## Section 3: Plan Mode Integration

Copilot CLI's plan mode maps onto the Superpowers planning/execution boundary.

| Superpowers phase | Plan mode state |
|---|---|
| `brainstorming` | Stay in plan mode — research and design only, no file changes |
| `writing-plans` | Stay in plan mode — producing the plan is still planning |
| User approves plan | Call `exit_plan_mode` before proceeding |
| `executing-plans` / `subagent-driven-development` | Out of plan mode, actively making changes |

**Rules for the agent:**
1. If Copilot enters plan mode automatically, lean into it during brainstorming and writing-plans
2. Call `exit_plan_mode` explicitly when the user approves a plan and implementation is about to begin
3. Never call `exit_plan_mode` during brainstorming or writing-plans, even if asked to make a quick edit

Plan mode becomes a natural reinforcement of the existing Superpowers discipline — thinking
phases stay in plan mode, execution phases exit it.

## Out of Scope

- Modifying any existing skill
- `/fleet` (same behavior as `dispatching-parallel-agents` via `task` tool — no additive value)
- `/delegate` cloud agent routing
- Custom agent definitions
