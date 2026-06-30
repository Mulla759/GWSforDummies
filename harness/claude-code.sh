#!/usr/bin/env bash
# Harness adapter: Claude Code (the default engine).
# Implements the 4-function contract that orchestrator/router.sh depends on.
# Swap to another agent framework by writing a sibling adapter and setting
# HARNESS in harness.config — nothing else in the system needs to change.

harness_name() { echo "Claude Code"; }

# Ready if the `claude` CLI is installed AND credentials exist (an interactive
# login or ANTHROPIC_API_KEY). We don't hard-fail on the key — `claude` may be
# logged in interactively — so we only require the CLI to be present.
harness_check() {
  command -v claude >/dev/null 2>&1 || { echo "harness[claude-code]: 'claude' CLI not found — install Claude Code" >&2; return 1; }
  return 0
}

# Route: ask the model to pick the single best action id for the goal.
# Prints ONLY the id (or empty on failure, so the caller can fall back).
harness_route() { # $1=goal  $2=catalog JSON (array of {id,title,description})
  local goal="$1" catalog="$2" prompt out
  prompt=$(cat <<EOF
You are a command router for a Google Workspace automation toolkit.
Choose the SINGLE best action for the user's goal from the catalog.
Reply with ONLY the action "id" string — no quotes, no prose, no punctuation.
If nothing fits, reply exactly: none

User goal: ${goal}

Catalog (JSON): ${catalog}
EOF
)
  out=$(claude -p "$prompt" 2>/dev/null | tr -d '[:space:]')
  [ "$out" = "none" ] && out=""
  printf '%s' "$out"
}

# Run a named sub-agent against the goal.
harness_run_agent() { # $1=agent  $2=goal  $3=interactive(true/false)
  local agent="$1" goal="$2" interactive="$3"
  if [ "$interactive" = "true" ]; then
    # Seed an interactive session with the goal (dispatcher keeps the conversation).
    claude --agent "$agent" "$goal"
  else
    # Headless one-shot.
    claude --agent "$agent" -p "$goal"
  fi
}
