# Superpowers for GitHub Copilot CLI

Install Superpowers as an official Copilot CLI plugin — skills become globally available in
every session, and the session-start hook auto-injects workflow context.

## Install

```bash
copilot plugin install obra/superpowers
```

This is a **global install** — skills are available in every Copilot session, not just the
current repository.

## What You Get

- All Superpowers skills globally available (brainstorming, writing-plans, executing-plans, etc.)
- Session-start hook automatically injects `using-superpowers` context at the start of every session
- `copilot-workflow` skill for model selection guidance, cross-session memory, and plan mode integration

For the full tool name mapping (Copilot CLI tool names → Superpowers skill equivalents), see
[`skills/using-superpowers/references/copilot-tools.md`](../skills/using-superpowers/references/copilot-tools.md).

## Verify

After install, start a new Copilot session. The `using-superpowers` context should appear
automatically. To verify manually:

```
/using-superpowers
```

Or invoke any skill:

```
/brainstorming
```

## Update

```bash
copilot plugin update superpowers
```

## Uninstall

```bash
copilot plugin uninstall superpowers
```

## Troubleshooting

### Skills not appearing

1. Confirm install: `copilot plugin list`
2. Restart Copilot CLI — plugins are loaded at startup
3. Reinstall: `copilot plugin uninstall superpowers && copilot plugin install obra/superpowers`

### Bootstrap context not appearing

If the session-start hook fires but `using-superpowers` context is missing, the
`hookSpecificOutput.additionalContext` field may not be supported in your Copilot CLI version.
Workaround: start your session with `/using-superpowers` in your first prompt.

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
