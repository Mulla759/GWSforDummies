#!/usr/bin/env bash
# setup.sh — one-shot bootstrap so anyone can clone this repo and get the same
# workflow. Install engine + deps, authenticate Google (gws), and verify the AI
# harness. Idempotent; safe to re-run.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf "\n\033[1m== %s ==\033[0m\n" "$*"; }

say "1/4  Engine: gws (Google Workspace CLI) + jq"
if ! command -v gws >/dev/null 2>&1; then
  echo "installing gws..."; npm install -g @googleworkspace/cli
else echo "gws present: $(gws --version 2>/dev/null | head -1)"; fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq missing — install it:"
  echo "  macOS:   brew install jq"
  echo "  Windows: winget install jqlang.jq   (reopen terminal after)"
else echo "jq present: $(jq --version)"; fi

say "2/4  Google auth (gws) — this stays exactly as the project already uses it"
if gws auth status >/dev/null 2>&1 && [ -n "$(gws auth status 2>/dev/null | jq -r '.account // empty' 2>/dev/null)" ]; then
  echo "already authenticated: $(gws auth status 2>/dev/null | jq -r '.account')"
else
  echo "Run:  gws auth login -s \"gmail,tasks,calendar\""
  echo "(First-time users also need an OAuth client_secret.json — see SETUP.md.)"
fi

say "3/4  AI harness (bring your own credentials)"
# shellcheck disable=SC1091
source "$ROOT/harness/harness.config"
adapter="$ROOT/harness/${HARNESS}.sh"
if [ -f "$adapter" ]; then
  # shellcheck disable=SC1090
  source "$adapter"
  echo "harness: ${HARNESS} ($(harness_name))"
  if harness_check 2>/dev/null; then
    echo "harness ready."
  else
    echo "harness NOT ready. Provide credentials for it, e.g. set \$${AI_CREDENTIAL_ENV:-AI_API_KEY}"
    echo "(For claude-code: install Claude Code and log in, or export ANTHROPIC_API_KEY.)"
  fi
else
  echo "No adapter at $adapter — copy harness/_template.sh and set HARNESS in harness.config."
fi

say "4/4  Make the command runnable"
chmod +x "$ROOT/bin/gws-do" "$ROOT/setup.sh" 2>/dev/null || true
echo "Add to PATH (optional):  export PATH=\"$ROOT/bin:\$PATH\""
echo
echo "Done. Try:"
echo "  $ROOT/bin/gws-do --status"
echo "  $ROOT/bin/gws-do --list"
echo "  $ROOT/bin/gws-do \"triage my inbox\""
