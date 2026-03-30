# Superpowers for GitHub Copilot CLI

Guide for using Superpowers with GitHub Copilot CLI via native skill discovery.

## Quick Install

Tell Copilot CLI:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.copilot/INSTALL.md
```

## Manual Installation

### Prerequisites

- GitHub Copilot CLI
- Git

### Steps

1. Clone the repo to a path outside Copilot's own data directories:
   ```bash
   git clone https://github.com/obra/superpowers.git ~/.copilot-superpowers
   ```

2. Create the skills symlink — this is a **global install**: skills are discoverable in every
   Copilot session regardless of which repo you have open:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.copilot-superpowers/skills ~/.agents/skills/superpowers
   ```

3. Restart Copilot CLI. Run `/skills list` — you should see `superpowers:*` skills.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.copilot-superpowers\skills"
```

## Hook Setup (Optional — Full Bootstrap Context)

The skills symlink gives you global skill discovery. The hook below adds automatic session-start
context injection: at the start of every session the agent receives the full `using-superpowers`
skill without needing to load it on demand.

**Important:** Copilot CLI hooks are per-repository — there is no confirmed global hooks config.
The symlink install already works globally; the hook is opt-in per repo.

### Setup

1. In your project, create `.github/hooks/superpowers.json`:

   **Linux/macOS:**
   ```json
   {
     "version": 1,
     "hooks": {
       "sessionStart": [
         {
           "type": "command",
           "bash": "$HOME/.copilot-superpowers/hooks/session-start",
           "env": {
             "COPILOT_CLI": "1"
           },
           "timeoutSec": 30
         }
       ]
     }
   }
   ```

   **Windows:**
   ```json
   {
     "version": 1,
     "hooks": {
       "sessionStart": [
         {
           "type": "command",
           "bash": "%USERPROFILE%\\.copilot-superpowers\\hooks\\session-start",
           "env": {
             "COPILOT_CLI": "1"
           },
           "timeoutSec": 30
         }
       ]
     }
   }
   ```

   Replace `~/.copilot-superpowers` with your actual clone path if different.

2. Commit `.github/hooks/superpowers.json` to your repo.

3. Start a new Copilot session in that repo. The agent should receive `using-superpowers`
   context automatically at startup.

## How It Works

GitHub Copilot CLI discovers skills from `~/.agents/skills/` at session start. Superpowers
skills are made visible through a single symlink:

```
~/.agents/skills/superpowers/ → ~/.copilot-superpowers/skills/
```

The `using-superpowers` skill is discovered automatically and enforces skill usage discipline.
The optional session-start hook injects the full `using-superpowers` context at startup.

For the full tool name mapping, see
[`skills/using-superpowers/references/copilot-tools.md`](../skills/using-superpowers/references/copilot-tools.md).

## Verification

After install, start a new Copilot session and run:

```
/skills list
```

You should see `superpowers:*` skills listed.

To verify the symlink directly:
```bash
ls -la ~/.agents/skills/superpowers
```

**Windows:**
```powershell
Get-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

To verify hook bootstrap (if configured): start a session in a repo with
`.github/hooks/superpowers.json`. The session should open with `using-superpowers` context
already loaded.

## Updating

```bash
cd ~/.copilot-superpowers && git pull
```

Skills update instantly through the symlink — no restart needed.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

Optionally delete the clone:
```bash
rm -rf ~/.copilot-superpowers
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers"
Remove-Item -Recurse -Force "$env:USERPROFILE\.copilot-superpowers"
```

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.copilot-superpowers/skills`
3. Try `/skills reload` in your session
4. Restart Copilot CLI — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, run PowerShell as
administrator.

### Hook not firing

1. Verify `.github/hooks/superpowers.json` exists in the repo and is committed
2. Check the script path is correct: `ls -la ~/.copilot-superpowers/hooks/session-start`
3. Verify the script is executable: `chmod +x ~/.copilot-superpowers/hooks/session-start`
4. Check your Copilot CLI version supports hooks

### Bootstrap context not appearing

If the hook fires but `using-superpowers` context is missing, the `hookSpecificOutput.additionalContext`
field may not be supported in your Copilot CLI version. Workaround: start your session with
`/skills load using-superpowers` or mention "use using-superpowers skill" in your first prompt.

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
