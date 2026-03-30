# Copilot CLI Plugin Alignment Design

Replace the manual symlink-based Copilot CLI install with the official Copilot CLI plugin
system: a `plugin.json` manifest, `hooks.json`, and `copilot plugin install` distribution.

## Motivation

The initial Copilot CLI support used a manual install (clone repo, symlink skills directory,
configure per-repo hooks). The official Copilot CLI plugin system provides a better path:
`copilot plugin install obra/superpowers` handles everything, skills become globally available
without symlinking, and hooks defined in the plugin fire globally — not just per-repo.

## Approach

Add `plugin.json` at the repo root pointing to the existing `skills/` directory and a new
`hooks.json`. The `hooks.json` replaces `hooks-copilot.json` with a relative path to the
session-start hook. Delete all symlink-based install artifacts and rewrite the install docs.

**Skills are already in the correct format** — no changes needed to any `SKILL.md` file.

The key unverified assumption is that Copilot CLI resolves `./hooks/session-start` relative
to the plugin cache directory when running plugin hooks. The implementation plan includes a
verification task before the rest of the work proceeds. If relative paths do not work, the
fallback is to use whatever env var Copilot CLI exposes for the plugin install directory.

## File Map

| File | Action |
|---|---|
| `plugin.json` | Create — official manifest |
| `hooks.json` | Create — replaces `hooks-copilot.json` with relative hook path |
| `hooks-copilot.json` | Delete |
| `hooks/session-start` | No change |
| `.copilot/INSTALL.md` | Simplify — one-line plugin install command |
| `docs/README.copilot.md` | Rewrite — plugin install only, no symlink/clone/junction |
| `README.md` | Update — Copilot section updated to plugin install command |
| `RELEASE-NOTES.md` | Update — note plugin install as install method |
| `tests/copilot/test-hook-bootstrap.sh` | Update — check `plugin.json` + `hooks.json` |
| `tests/copilot/test-install-paths.sh` | Rewrite — replace symlink checks with plugin checks |
| All `skills/` | No change |

## Component Designs

### plugin.json

```json
{
  "name": "superpowers",
  "description": "Workflow skills and hooks for AI coding agents — structured brainstorming, TDD plans, subagent-driven execution, and cross-platform tool mapping",
  "version": "5.1.0",
  "author": {
    "name": "Jesse Vincent",
    "url": "https://github.com/obra/superpowers"
  },
  "repository": "https://github.com/obra/superpowers",
  "license": "MIT",
  "keywords": ["superpowers", "skills", "workflow", "tdd", "agents"],
  "skills": "skills/",
  "hooks": "hooks.json"
}
```

- `skills: "skills/"` covers all existing skills without enumeration
- `hooks: "hooks.json"` references a separate file rather than inlining hook definitions

### hooks.json

Replaces `hooks-copilot.json`. Identical structure; only the `bash` path changes from
`$HOME/.copilot-superpowers/hooks/session-start` to `./hooks/session-start`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{
      "type": "command",
      "bash": "./hooks/session-start",
      "env": {
        "COPILOT_CLI": "1"
      },
      "timeoutSec": 30
    }]
  }
}
```

`COPILOT_CLI=1` is retained — `hooks/session-start` is shared across Claude Code, Cursor,
and Copilot CLI and uses this env var to select the correct JSON output format.

### docs/README.copilot.md (rewrite)

Structure:

1. **Install** — `copilot plugin install obra/superpowers`
2. **What you get** — skills globally available in all sessions; session-start hook
   auto-injects `using-superpowers` context
3. **Update** — `copilot plugin update superpowers`
4. **Uninstall** — `copilot plugin uninstall superpowers`
5. **Verify** — invoke `/using-superpowers`; confirm context appears at session start

No clone path, no symlink, no Windows junction, no per-repo hook section.

### .copilot/INSTALL.md (simplify)

Reduce to a single instruction for the remote-fetch bootstrap pattern:

```
Run: copilot plugin install obra/superpowers
```

### Test Changes

**test-hook-bootstrap.sh** — existing session-start tests unchanged; `hooks-copilot.json`
checks replaced:

| Removed | Added |
|---|---|
| `hooks-copilot.json` exists | `plugin.json` exists |
| `hooks-copilot.json` has `sessionStart` | `hooks.json` exists |
| `hooks-copilot.json` sets `COPILOT_CLI` env | `hooks.json` has `sessionStart` |
| — | `hooks.json` sets `COPILOT_CLI` env var |
| — | `plugin.json` has `name: superpowers` |
| — | `plugin.json` references `hooks.json` |

**test-install-paths.sh** — symlink/junction/clone checks replaced:

| Removed | Added |
|---|---|
| `ln -s` command present | `copilot plugin install` command present |
| `mklink /J` junction command | `plugin.json` exists at repo root |
| Safe clone path documented | `plugin.json` has correct `name` field |
| Per-repo hooks limitation | Global install documented |

Tests retained: `docs/README.copilot.md` exists, `.copilot/INSTALL.md` exists, root
`README.md` has Copilot section, global install documented.

## Out of Scope

- Changes to any existing `SKILL.md` file
- Adding Superpowers to a public plugin marketplace (that is a separate future step)
- Windows-specific junction or PowerShell install paths (plugin install handles cross-platform)
- Testing the live hook behavior end-to-end (no Copilot CLI instance available in CI)
