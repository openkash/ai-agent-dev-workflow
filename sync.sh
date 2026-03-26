#!/usr/bin/env bash
# sync.sh — Copy skills from this ecosystem repo to individual repos.
# Run manually before tagging a release.
#
# Usage:
#   ./sync.sh [--dry-run]
#
# Assumes individual repos are checked out as siblings:
#   ../ai-agent-tdd-skill/
#   ../ai-agent-spec-skill/

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TDD_REPO="${SCRIPT_DIR}/../ai-agent-tdd-skill"
SPEC_REPO="${SCRIPT_DIR}/../ai-agent-spec-skill"

sync_file() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $src -> $dst"
  else
    cp "$src" "$dst"
    echo "  copied: $src -> $dst"
  fi
}

sync_dir() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $src/ -> $dst/"
  else
    cp -r "$src"/* "$dst"/
    echo "  copied: $src/ -> $dst/"
  fi
}

echo "=== Syncing TDD skill ==="
if [[ -d "$TDD_REPO" ]]; then
  sync_file "$SCRIPT_DIR/skills/tdd/SKILL.md" "$TDD_REPO/SKILL.md"
  sync_file "$SCRIPT_DIR/skills/tdd/PROJECT.md" "$TDD_REPO/PROJECT.md"
  sync_dir  "$SCRIPT_DIR/skills/tdd/references" "$TDD_REPO/references"
  echo "  Done. Review changes: cd $TDD_REPO && git diff"
else
  echo "  SKIP: $TDD_REPO not found"
fi

echo ""
echo "=== Syncing Spec skill ==="
if [[ -d "$SPEC_REPO" ]]; then
  sync_file "$SCRIPT_DIR/skills/spec/SKILL.md" "$SPEC_REPO/SKILL.md"
  sync_file "$SCRIPT_DIR/skills/spec/PROJECT.md" "$SPEC_REPO/PROJECT.md"
  sync_dir  "$SCRIPT_DIR/skills/spec/references" "$SPEC_REPO/references"
  echo "  Done. Review changes: cd $SPEC_REPO && git diff"
else
  echo "  SKIP: $SPEC_REPO not found"
fi

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. No files were copied."
else
  echo "Sync complete. Review diffs in each repo before committing."
fi
