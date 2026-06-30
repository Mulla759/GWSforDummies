#!/usr/bin/env bash
# Harness adapter TEMPLATE — copy to "<your-harness>.sh", implement the four
# functions, then set HARNESS=<your-harness> in harness.config. That is the only
# change needed to drive this toolkit with a different agent framework
# (an open-source agent, a remote service, a local model runner, etc.).
#
# Contract (the orchestrator depends ONLY on these four functions):

# Human-readable name, shown in `gws-do --status`.
harness_name() { echo "My Harness"; }

# Return 0 when your CLI/SDK is installed and AI credentials are present.
# Print a helpful message to stderr and return non-zero otherwise.
harness_check() {
  : # e.g. command -v my-agent >/dev/null && [ -n "${MY_API_KEY:-}" ]
  return 1
}

# Given the user's goal and a JSON catalog of actions ([{id,title,description}]),
# print the single best action "id" to stdout (empty string if none).
# This is the "describe -> route via agent" step.
harness_route() { # $1=goal  $2=catalog JSON
  : # call your model with a routing prompt; echo just the chosen id
  printf ''
}

# Run the chosen sub-agent against the goal.
# $3 is "true" for interactive/conversational agents, "false" for one-shot.
# Map "agent name" to however your framework launches a named agent/skill.
harness_run_agent() { # $1=agent  $2=goal  $3=interactive
  : # e.g. my-agent run --profile "$1" --input "$2"
  echo "harness[_template]: not implemented — copy this file and fill in the 4 functions" >&2
  return 1
}
