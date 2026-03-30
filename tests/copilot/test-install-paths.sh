#!/usr/bin/env bash
# Test: Install Paths
# Verifies that install docs are complete: symlink, junction, clone path, global/per-repo install
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
README="$REPO_ROOT/docs/README.copilot.md"
INSTALL="$REPO_ROOT/.copilot/INSTALL.md"

echo "=== Test: Install Paths ==="

# Test 1: docs/README.copilot.md exists
echo "Test 1: Checking docs/README.copilot.md exists..."
if [ -f "$README" ]; then
    echo "  [PASS] docs/README.copilot.md exists"
else
    echo "  [FAIL] docs/README.copilot.md not found"
    exit 1
fi

# Test 2: README includes Unix symlink command
echo "Test 2: Checking README includes Unix symlink command..."
if grep -q "ln -s" "$README"; then
    echo "  [PASS] Unix symlink command present"
else
    echo "  [FAIL] Unix symlink command missing"
    exit 1
fi

# Test 3: README includes Windows junction command
echo "Test 3: Checking README includes Windows junction command..."
if grep -qi "mklink.*\/J\|mklink /J" "$README"; then
    echo "  [PASS] Windows junction command present"
else
    echo "  [FAIL] Windows junction command missing"
    exit 1
fi

# Test 4: README documents a safe clone path (not ~/.copilot/)
echo "Test 4: Checking README uses safe clone path (not ~/.copilot/)..."
if grep -q "copilot-superpowers" "$README"; then
    echo "  [PASS] Safe clone path documented"
else
    echo "  [FAIL] Safe clone path not documented (must not use ~/.copilot/)"
    exit 1
fi

# Test 5: README documents global skill install (symlink is global)
echo "Test 5: Checking README documents global nature of skill symlink..."
if grep -qi "global" "$README"; then
    echo "  [PASS] Global install documented"
else
    echo "  [FAIL] Global install not documented"
    exit 1
fi

# Test 6: README documents per-repo hook limitation
echo "Test 6: Checking README documents per-repo hooks limitation..."
if grep -qi "per.repo\|per repo" "$README"; then
    echo "  [PASS] Per-repo hooks limitation documented"
else
    echo "  [FAIL] Per-repo hooks limitation not documented"
    exit 1
fi

# Test 7: .copilot/INSTALL.md exists (self-bootstrapping entry point)
echo "Test 7: Checking .copilot/INSTALL.md exists..."
if [ -f "$INSTALL" ]; then
    echo "  [PASS] .copilot/INSTALL.md exists"
else
    echo "  [FAIL] .copilot/INSTALL.md not found"
    exit 1
fi

# Test 8: INSTALL.md includes both Unix and Windows steps
echo "Test 8: Checking INSTALL.md includes Unix and Windows steps..."
if grep -q "ln -s" "$INSTALL" && grep -qi "mklink\|junction\|powershell" "$INSTALL"; then
    echo "  [PASS] INSTALL.md has both Unix and Windows steps"
else
    echo "  [FAIL] INSTALL.md is missing Unix or Windows steps"
    exit 1
fi

# Test 9: README.md (root) has Copilot section
echo "Test 9: Checking root README.md has Copilot section..."
ROOT_README="$REPO_ROOT/README.md"
if grep -qi "copilot" "$ROOT_README"; then
    echo "  [PASS] Root README.md has Copilot section"
else
    echo "  [FAIL] Root README.md is missing Copilot section"
    exit 1
fi

echo ""
echo "=== All install path tests passed ==="
