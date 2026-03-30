# GitHub Copilot CLI Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Copilot CLI equivalent |
|-----------------|----------------------|
| `Read` (file reading) | `view` |
| `Write` (file creation) | `create` |
| `Edit` (file editing) | `edit` |
| `Bash` (run commands) | `bash` or `powershell` |
| `Grep` (search file content) | `grep` |
| `Glob` (search files by name) | `glob` |
| `TodoWrite` (task tracking) | `update_todo` |
| `Skill` tool (invoke a skill) | `/skills` command or `skill` tool |
| `WebSearch` | `web_fetch` with a search URL |
| `WebFetch` | `web_fetch` |
| `Task` tool (dispatch subagent) | `task` tool (see [Subagent dispatch](#subagent-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `task` calls |

## Subagent dispatch

GitHub Copilot CLI supports multi-agent delegation via the `task` tool. This maps directly to
Claude Code's `Task` tool. Skills that rely on subagent dispatch (`subagent-driven-development`,
`dispatching-parallel-agents`) work natively.

### Named agent dispatch

Claude Code skills reference named agent types like `superpowers:code-reviewer`.
Copilot CLI uses the `task` tool with explicit instructions. When a skill says to dispatch
a named agent type:

1. Find the agent's prompt file (e.g., `agents/code-reviewer.md`)
2. Read the prompt content
3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
4. Call `task` with the filled content as the instruction

| Skill instruction | Copilot CLI equivalent |
|-------------------|----------------------|
| `Task tool (superpowers:code-reviewer)` | `task(instruction=...)` with `agents/code-reviewer.md` content |
| `Task tool (general-purpose)` with inline prompt | `task(instruction=...)` with the same prompt |

## Additional Copilot CLI tools

These tools are available in Copilot CLI but have no Claude Code equivalent:

| Tool | Purpose |
|------|---------|
| `apply_patch` | Apply unified diffs to files |
| `ask_user` | Request structured input from the user |
| `report_intent` | Report planned actions before execution |
| `show_file` | Display files prominently in the session |
| `store_memory` | Persist facts across sessions |
| `exit_plan_mode` | Exit plan mode and begin executing |
| `/delegate` | Delegate work to the cloud Copilot agent |
| `/fleet` | Run the same task across multiple agents in parallel |
| `/resume` | Switch between local and cloud agent sessions |

## Known limitations

- **Hook bootstrap is per-repo:** Session-start hooks require a `.github/hooks/superpowers.json`
  in each repository. There is no confirmed global hooks config. Skills are globally discoverable
  via the `~/.agents/skills/` symlink regardless.
- **`hookSpecificOutput.additionalContext`:** This field is used for session-start context injection
  but is not formally documented across all Copilot CLI versions. If bootstrap context does not
  appear, manually invoke the `using-superpowers` skill at session start.
- **No equivalent to `/plugin install`:** Superpowers installs via clone + symlink, not via a
  plugin marketplace entry. See `docs/README.copilot.md` for install instructions.

## Windows path guidance

On Windows, use PowerShell for setup commands:

```powershell
# Create skills directory
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"

# Create junction (equivalent to Unix symlink for directories)
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.copilot-superpowers\skills"
```

In hook configs, use Windows-style escaped paths:
```json
"bash": "%USERPROFILE%\\.copilot-superpowers\\hooks\\session-start"
```

## Workflow Enhancements

For model selection guidance, cross-session memory (workflow state and project preferences),
and plan mode integration, see the `copilot-workflow` skill.
