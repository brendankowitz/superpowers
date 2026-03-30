---
name: copilot-workflow
description: Use when running on GitHub Copilot CLI — model selection guidance, cross-session memory for workflow state and project preferences, and native plan mode integration
---

# Copilot CLI Workflow Enhancements

These enhancements are specific to GitHub Copilot CLI and are additive — no existing skills change.

## Model Guidance

Before entering each Superpowers phase, consider switching models with `/model <name>`. These are suggestions; use judgment based on task complexity.

| Phase | Recommended model | Reason |
|---|---|---|
| `brainstorming` | gpt5.4, opus 4.6 | Creative exploration and design space work |
| `writing-plans` | opus 4.6, sonnet 4.6, codex 5.3 | Methodical task decomposition |
| `executing-plans` subagents — single file / routine | gemini flash, haiku 4.6 | Straightforward edits; saves cost and time |
| `executing-plans` subagents — complex / multi-file | sonnet 4.6, codex 5.3 | More context needed for larger changes |
| Code review | opus 4.6 | Most capable catches the most issues |
| Debugging | opus 4.6, sonnet 4.6 | Structured reasoning through complex logic |

## Cross-Session Memory

Use `store_memory` to persist state across sessions. Keys follow the format
`superpowers:<namespace>:<repo-name>` where `repo-name` is the git remote name or working
directory name.

### At Session Start

Before doing anything else, recall both namespaces:

1. Check workflow state (`superpowers:workflow:<repo-name>`):
   - If found: surface it — "You have an in-progress Superpowers workflow: [plan], task N of M. Resume?"
   - If not found: proceed normally

2. Check project preferences (`superpowers:preferences:<repo-name>`):
   - If found: apply silently — no prompt unless something is ambiguous

### Workflow State (`superpowers:workflow:<repo-name>`)

Transient. Store and update as the flow progresses.

**After brainstorming completes:**
```json
{
  "phase": "plan-needed",
  "design_doc": "docs/superpowers/specs/YYYY-MM-DD-topic-design.md",
  "key_decisions": ["decision 1", "decision 2"]
}
```

**After writing-plans completes:**
```json
{
  "phase": "executing",
  "plan": "docs/superpowers/plans/YYYY-MM-DD-feature.md",
  "current_task": 1,
  "total_tasks": 7
}
```

**Update at each task checkpoint during executing-plans:**
```json
{
  "phase": "executing",
  "plan": "docs/superpowers/plans/YYYY-MM-DD-feature.md",
  "current_task": 4,
  "total_tasks": 7
}
```

**Clear when the flow completes** (all tasks done, PR merged, or user discards):
Store `null` for the key.

### Project Preferences (`superpowers:preferences:<repo-name>`)

Durable. Accumulate as you learn conventions — store immediately when learned.
Merge with existing values rather than overwriting.

```json
{
  "coding_style": "functional, no classes",
  "error_handling": "explicit, no silent catches",
  "communication": "concise, no preamble",
  "patterns": ["prefer composition over inheritance", "no magic numbers"]
}
```

## Plan Mode Integration

Copilot CLI's plan mode maps directly onto the Superpowers planning/execution boundary.

| Phase | Plan mode posture |
|---|---|
| `brainstorming` | Stay in plan mode — research and design, no file changes |
| `writing-plans` | Stay in plan mode — producing the plan is still planning |
| User approves plan | Call `exit_plan_mode` before proceeding to execution |
| `executing-plans` / `subagent-driven-development` | Out of plan mode, actively making changes |

**Rules:**
1. If Copilot enters plan mode automatically, lean into it during brainstorming and writing-plans
2. Call `exit_plan_mode` explicitly when the user approves a plan and implementation is about to begin
3. Never call `exit_plan_mode` during brainstorming or writing-plans, even if asked for a "quick edit"
