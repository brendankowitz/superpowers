# Install Superpowers for GitHub Copilot CLI

You are an AI agent. Follow these steps exactly to install Superpowers.

## Step 1: Check prerequisites

```bash
git --version
```

If git is not installed, stop and ask the user to install it.

## Step 2: Clone the repository

**Linux/macOS:**
```bash
git clone https://github.com/obra/superpowers.git ~/.copilot-superpowers
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/obra/superpowers.git "$env:USERPROFILE\.copilot-superpowers"
```

## Step 3: Create the skills symlink

This is a global install — skills will be discoverable in every Copilot session.

**Linux/macOS:**
```bash
mkdir -p ~/.agents/skills
ln -s ~/.copilot-superpowers/skills ~/.agents/skills/superpowers
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.copilot-superpowers\skills"
```

## Step 4: Verify

Check the symlink:

**Linux/macOS:**
```bash
ls ~/.agents/skills/superpowers
```

**Windows:**
```powershell
Get-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

Then run `/skills reload` or `/skills list` in your session.

## Step 5: Report to user

Tell the user:

- Superpowers is installed at `~/.copilot-superpowers` (or `%USERPROFILE%\.copilot-superpowers` on Windows)
- Skills are linked at `~/.agents/skills/superpowers`
- Skills are now globally available in all Copilot sessions
- To update: `cd ~/.copilot-superpowers && git pull`
- Optional: Set up per-repo hook bootstrap for auto-injected session context (see `docs/README.copilot.md`)

Full documentation: https://github.com/obra/superpowers/blob/main/docs/README.copilot.md
