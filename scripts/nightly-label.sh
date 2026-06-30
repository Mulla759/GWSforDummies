#!/usr/bin/env bash
# Nightly auto-labeler (deterministic, no LLM)
# -----------------------------------------------------
# Applies sender->label rules to NEW inbox mail. Needs only the `gmail.modify`
# scope (no filters / settings scope). Idempotent: re-labeling an already-labeled
# message is a no-op.
#
# Schedule it (see SETUP.md). Default window = last 2 days so a daily run never
# misses mail even if one night is skipped.
#
# Requires: gws (authenticated), jq on PATH.
set -uo pipefail
# Platform PATH fixup — only prepend when the dirs exist, so this one script works
# on Windows (Git Bash via Task Scheduler), macOS, and Linux (GitHub Actions).
for d in \
  "/c/Users/${USERNAME:-}/AppData/Roaming/npm" \
  "/c/Users/${USERNAME:-}/AppData/Local/Microsoft/WinGet/Links" \
  "${HOME:-}/.npm-global/bin"; do
  [ -n "$d" ] && [ -d "$d" ] && export PATH="$d:$PATH"
done

WINDOW="${1:-newer_than:2d}"     # override e.g. ./nightly-label.sh newer_than:7d
SCOPE="in:inbox $WINDOW"

# Resolve a label NAME -> id at runtime (robust to id changes / new accounts).
lid(){ gws gmail users labels list --params '{"userId":"me"}' 2>/dev/null \
        | jq -r --arg n "$1" '.labels[] | select(.name==$n) | .id'; }

apply(){ # $1=label name   $2=from-list (domains, OR-separated)   [$3=subject-query]
  local id; id="$(lid "$1")"
  [ -z "$id" ] && { echo "  ! label not found (create it in Gmail first): $1"; return; }
  local q
  if [ -n "${3:-}" ]; then q="$SCOPE $3"; else q="$SCOPE from:($2)"; fi
  local params ids cnt body
  params="$(jq -n --arg q "$q" '{userId:"me",q:$q,maxResults:500}')"
  ids="$(gws gmail users messages list --params "$params" --page-all 2>/dev/null | jq -s '[.[].messages[]?.id]')"
  cnt="$(echo "$ids" | jq 'length')"
  if [ "$cnt" -gt 0 ]; then
    body="$(jq -n --argjson ids "$ids" --arg l "$id" '{ids:$ids,addLabelIds:[$l]}')"
    gws gmail users messages batchModify --params '{"userId":"me"}' --json "$body" >/dev/null 2>&1 \
      && echo "  $1: +$cnt" || echo "  $1: ERR"
  else echo "  $1: 0"; fi
}

echo "[nightly-label] $(date) -- window: $WINDOW"

# ── CUSTOMIZE THESE RULES FOR YOUR OWN INBOX ─────────────────────────────────
# Each line:  apply "<Gmail label>" "<from-domain OR from-domain OR ...>"
# The label must already exist in Gmail (create it once, or let the triage agent
# make it). The domains below are ILLUSTRATIVE EXAMPLES — replace them with the
# senders you actually receive. Run the email-triage agent first to discover them.
apply "Finance"         "chase.com OR bankofamerica.com OR citibank.com OR discover.com OR amex.com OR ally.com"
apply "Newsletters"     "substack.com OR mailchimp.com OR beehiiv.com OR medium.com OR morningbrew.com"
apply "Shopping"        "amazon.com OR ebay.com OR etsy.com OR target.com OR walmart.com OR shopify.com"
apply "Tech & Learning" "github.com OR stackoverflow.com OR coursera.org OR udemy.com OR openai.com OR notion.so"
apply "Travel"          "delta.com OR united.com OR airbnb.com OR booking.com OR expedia.com OR amtrak.com"
apply "Events"          "eventbrite.com OR meetup.com OR calendly.com OR lu.ma OR hopin.com"
apply "Security"        "accounts.google.com OR login.gov"
apply "Social"          "linkedin.com OR facebookmail.com OR x.com OR reddit.com"

# Importance overlay (subject-based) — the 3rd arg switches to a subject query:
apply "Priority" "" 'subject:("action required" OR "past due" OR overdue OR fraud OR "security alert" OR "unusual sign-in" OR "payment failed" OR "verify your account" OR "final notice")'
echo "[nightly-label] done"
