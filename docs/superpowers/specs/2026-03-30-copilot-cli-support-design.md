# Copilot CLI Support: Parity-First Superpowers Integration Design

Enable Superpowers in GitHub Copilot CLI with behavior as close as possible to Claude Code CLI integration: native skill discovery + startup bootstrap context + platform mapping + regression tests.

## Motivation

Superpowers already has strong platform paths for Claude Code, Codex, OpenCode, and Gemini. Copilot CLI support must not be “docs only” or extension-fragile; it should follow the same proven primitives as Claude/Codex where possible.

## Parity target

“As close as possible” means matching core operational behavior, not identical internal APIs:

1. Skills are discovered natively from standard skill directories.
2. Session-start bootstrap injects `using-superpowers` guidance automatically.
3. Platform-specific tool mapping exists and is referenced by bootstrap/docs.
4. Integration has automated checks and documented install/verify/update flow.

## Current State

- Existing bootstrap hook script: `hooks/session-start`
- Existing hooks config present in repo: `hooks/hooks.json` (Claude Code format) and `hooks/hooks-cursor.json` (Cursor format)
- **Unverified:** Whether Copilot CLI reads `hooks/hooks.json`, `.github/hooks/hooks.json`, or another location. Must be verified before documenting hook setup.
- Existing platform mapping precedents:
  - `skills/using-superpowers/references/codex-tools.md`
  - `skills/using-superpowers/references/gemini-tools.md`
- Existing install doc pattern:
  - `.codex/INSTALL.md`
  - `.opencode/INSTALL.md`
- No Copilot-specific README or mapping doc currently exists.

## Design Principles

1. **Prefer proven paths over novel APIs**
   - Use hook-based startup injection as primary bootstrap mechanism.
2. **Use standard skill discovery paths**
   - Align with `~/.agents/skills/superpowers` style setup used by Codex/Claude ecosystem.
3. **Treat extension support as additive, not foundational**
   - Copilot extension can be optional fallback/enhancement, not required for v1 parity.
4. **Document verified capabilities only**
   - Tool mapping must be based on validated Copilot tool inventory.

## Proposed Architecture

### 1) Primary bootstrap: hooks-based session start

Use Copilot hooks configuration (repo/local) to run:

- `hooks/session-start`

This script already emits platform-aware JSON (`additional_context` fallback and Claude-specific `hookSpecificOutput`) and loads full `skills/using-superpowers/SKILL.md`.

Action:
- Verify which environment variables (if any) Copilot CLI sets at hook invocation time. The existing script handles `CURSOR_PLUGIN_ROOT` and `CLAUDE_PLUGIN_ROOT` but has no Copilot-specific detection. If Copilot sets neither, the script falls back to generic `additional_context` JSON — verify Copilot actually consumes this field.
- Verify exact hooks config file location Copilot CLI reads (`.github/hooks/hooks.json`, `hooks/hooks.json`, user-scoped config, or other). Do not document a path until verified.
- **Verify whether Copilot supports a user-level (global) hooks config** that fires in every session regardless of which repo is open. This determines the global install story:
  - If a global config exists, the bootstrap fires everywhere and global install is fully supported.
  - If hooks are per-repo only, the session-start bootstrap only fires in repos with a local hook config. Skills are still globally discoverable via the symlink, but context injection requires per-repo opt-in. This limitation must be documented explicitly.
- If Copilot sets its own env variable, add a detection branch to `hooks/session-start` (matching the existing `CURSOR_PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` pattern). If Copilot requires a different config file format or location, create `hooks-copilot.json` alongside the existing `hooks-cursor.json`.

### 2) Native skill discovery parity

Install flow must include symlink/junction setup to a standard skills location:

- Unix: `~/.agents/skills/superpowers -> <clone-path>/skills` (skill discovery path TBD pending verification)
- Windows: junction equivalent under `%USERPROFILE%\.agents\skills\superpowers`

**Clone path:** Do not assume `~/.copilot/superpowers`. The `~/.copilot/` directory may conflict with GitHub Copilot's own data directories (`~/.config/github-copilot/` on Linux, `%APPDATA%\GitHub Copilot\` on Windows). Verify a non-conflicting convention (e.g., `~/.copilot-superpowers/superpowers` or `~/.local/share/superpowers`) before documenting install steps.

Rationale:
- Matches Codex/Claude-style native discovery behavior.
- Keeps skills source-of-truth in this repository.

### 3) Copilot tool mapping reference

Create:

- `skills/using-superpowers/references/copilot-tools.md`

Must include:
- Verified tool name mappings
- Subagent/delegation capability status (supported vs unsupported) and fallback behavior
- Windows PowerShell notes and path guidance

Also update `skills/using-superpowers/SKILL.md`: the platform reference line currently only mentions `codex-tools.md` and Gemini. Add a reference to `copilot-tools.md` for Copilot users.

### 4) Copilot platform docs

Create:

- `docs/README.copilot.md`

Include:
- Prerequisites
- Install via clone + symlink/junction
- Hook setup
- Verification steps
- Update/uninstall
- Troubleshooting

Create (if Copilot supports remote-fetch install pattern like Codex):

- `.copilot/INSTALL.md` — self-bootstrapping entry point so users can say "fetch and follow instructions from raw.githubusercontent.com/.../INSTALL.md"

Update:
- `README.md` (Copilot section)
- `RELEASE-NOTES.md` (parity-first Copilot support)

### 5) Optional extension path (non-blocking)

If extension approach is included, it is explicitly secondary:

- `.github/extensions/superpowers/extension.mjs` may be added only as optional enhancement.
- Do not make parity depend on extension startup context injection.
- If extension startup context API behavior is uncertain, document limitation and keep hook path primary.

**Important:** GitHub Copilot Extensions require a registered GitHub App — this is not a file-drop enhancement. Do not begin extension work without confirming the app registration and OAuth flow requirements. Document clearly in user-facing docs that the extension requires a registered app to function.

## Capability Verification Requirements (before mapping claims)

1. Verify Copilot tool inventory names in real session context.
2. Verify whether subagent/multi-agent delegation exists; if absent, define Gemini-style fallback guidance.
3. Verify hook payload shape consumed by Copilot for session-start context.
4. Verify whether a user-level global hooks config exists; determine the global install story before writing install docs.

No mapping or parity claims should be made without these checks.

## Risks and Mitigations

1. **Hook payload mismatch across Copilot versions**
   - Mitigation: add tests for hook output schema and concise troubleshooting docs.

2. **Unverified tool mapping drift**
   - Mitigation: add mapping integrity tests and require verified examples in docs.

3. **Windows setup friction**
   - Mitigation: include explicit PowerShell junction commands and path examples.

4. **Over-claiming parity**
   - Mitigation: define parity checklist and explicitly mark unsupported features with fallback behavior.

5. **Per-repo-only hooks limit global install story**
   - If Copilot has no user-level hooks config, the bootstrap context only fires in repos with local hook config, unlike Claude Code where the plugin install is global. Mitigation: document clearly that skills are globally discoverable (symlink) but bootstrap context requires per-repo opt-in, and provide both a "global skills only" and "per-repo full parity" setup path.

## Acceptance Criteria (parity-close)

1. Copilot install docs provide clone + native skills discovery setup (symlink/junction) using a verified, non-conflicting clone path.
2. Session-start bootstrap is documented and works via hooks path; `hooks/session-start` detects Copilot env var (if one exists).
3. `copilot-tools.md` exists with verified mappings and capability/fallback notes.
4. `skills/using-superpowers/SKILL.md` references `copilot-tools.md` for Copilot users.
5. Automated tests validate hook/bootstrap + mapping + install-path assumptions and **all tests pass**.
6. README/release notes reflect Copilot support without unsupported claims.
7. If subagent support is absent, fallback to `executing-plans` is documented (matching `gemini-tools.md` pattern).
8. Troubleshooting docs cover: skill discovery verification, hook execution verification, common symlink/junction errors, and Copilot version compatibility.
9. Global install story is documented: either a global hooks config path is provided, or the per-repo-only limitation is stated with a "global skills only" install option as the default recommendation.

## Out of Scope

- Rewriting all skills for Copilot-only semantics
- Guaranteeing feature parity for capabilities Copilot does not expose (if any)
- Replacing existing platform integrations

