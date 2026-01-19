#!/usr/bin/env bash
# Helper script: genereert een semantic-release / Conventional Commit bericht met Copilot CLI
# Voorbeeld gebruik: ./scripts/copilot-commit.sh --staged > commit-message.txt
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
MAX_DIFF_CHARS=${MAX_DIFF_CHARS:-16000}  # voorkom te grote prompts

# Kies diff source: --staged of --all (werkboom)
MODE="staged"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) MODE="staged"; shift;;
    --all) MODE="all"; shift;;
    --help|-h) echo "Usage: $0 [--staged|--all]"; exit 0;;
    *) shift;;
  esac
done

if [[ "$MODE" == "staged" ]]; then
  DIFF="$(git diff --staged --no-color || true)"
else
  DIFF="$(git diff --no-color || true)"
fi

if [[ -z "$DIFF" ]]; then
  echo "No diff found (mode=$MODE)." >&2
  exit 1
fi

# Truncate if necessary
if [[ ${#DIFF} -gt $MAX_DIFF_CHARS ]]; then
  DIFF="${DIFF:0:$MAX_DIFF_CHARS}"
  DIFF="$DIFF
  ...[Truncated diff to $MAX_DIFF_CHARS chars]..."
fi

# Prompt template: vraag om een Conventional Commit-style message en alleen de message terug te geven
PROMPT=$(cat <<'EOF'
You are an assistant that writes a single git commit message in Conventional Commits format suitable for semantic-release.
Rules:
- Output only the commit message (first line = header; following paragraphs are body and then footer).
- Use Conventional Commits types (fix, feat, chore, docs, style, refactor, test, perf, build, ci).
- If a breaking change, include "BREAKING CHANGE: <description>" in the footer.
- Keep the header <= 72 chars and body lines <= 100 chars.
- Also return, on a new line after the commit message, a single word indicating the recommended semantic-release bump: major, minor, patch, or none.
Now generate the commit message and bump for this diff:
DIFF_START
{{DIFF}}
DIFF_END
EOF
)

# Inject diff safely (avoid issues with newlines)
export COPILOT_DIFF="$DIFF"

# Replace placeholder with actual diff
PROMPT_WITH_DIFF="${PROMPT//\{\{DIFF\}\}/$COPILOT_DIFF}"

# Ensure copilot CLI exists
if ! command -v copilot >/dev/null 2>&1; then
  echo "Error: copilot CLI not found in PATH. Install it or add to PATH." >&2
  exit 1
fi

# Build command (include prompt as a single argument)
COPILOT_CMD=(copilot -p "$PROMPT_WITH_DIFF" --add-dir "$REPO_ROOT" --allow-tool 'shell(git:*)')

# If you prefer fully non-interactive, you can enable --allow-all-tools (or set COPILOT_ALLOW_ALL=1)
# COPILOT_CMD+=(--allow-all-tools)

# Execute the command
"${COPILOT_CMD[@]}"
