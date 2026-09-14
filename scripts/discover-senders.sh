#!/usr/bin/env bash
# discover-senders.sh — read-only "email pathways" discovery helper.
# ============================================================================
# Prints the most common sender domains and the most common subject words in a
# window of your inbox. Deterministic and read-only: it NEVER writes anything.
# Use it to see your real email pathways before curating scripts/label-rules.tsv
# (the label-rules-curator agent runs it, then edits the rules file).
#
# USAGE
#   discover-senders.sh [WINDOW] [MAX]
#     WINDOW   Gmail search window appended to "in:inbox" (default newer_than:90d)
#     MAX      max messages to sample                              (default 300)
#
# Requires: gws (authenticated), jq on PATH.
# ============================================================================
set -uo pipefail
# Platform PATH fixup — same pattern as nightly-label.sh.
for d in \
  "/c/Users/${USERNAME:-}/AppData/Roaming/npm" \
  "/c/Users/${USERNAME:-}/AppData/Local/Microsoft/WinGet/Links" \
  "${HOME:-}/.npm-global/bin"; do
  [ -n "$d" ] && [ -d "$d" ] && export PATH="$d:$PATH"
done

WINDOW="${1:-newer_than:90d}"
MAX="${2:-300}"

command -v jq >/dev/null 2>&1 || { echo "discover-senders: jq not found on PATH" >&2; exit 1; }

RAW="$(gws gmail +triage --query "in:inbox $WINDOW" --max "$MAX" --format json 2>/dev/null)"
if [ -z "$RAW" ] || ! printf '%s' "$RAW" | jq -e . >/dev/null 2>&1; then
  echo "discover-senders: no data — gws returned empty or non-JSON." >&2
  echo "  Is gws installed and authenticated? Try: gws auth login -s gmail" >&2
  exit 1
fi

echo "=== Sender & subject discovery — window: $WINDOW (max $MAX) ==="
echo

echo "## Top sender domains (count  domain  example)"
printf '%s' "$RAW" | jq -r '.messages[]?.from // empty' \
  | sed -E 's/.*<([^>]+)>.*/\1/' \
  | tr 'A-Z' 'a-z' \
  | tr -d ' \r' \
  | awk -F@ 'NF>1 && $NF!="" { d=$NF; c[d]++; if(!(d in ex)) ex[d]=$0 }
             END { for (d in c) printf "%d\t%s\t%s\n", c[d], d, ex[d] }' \
  | sort -rn -k1,1 \
  | head -40
echo

echo "## Top subject words"
printf '%s' "$RAW" | jq -r '.messages[]?.subject // empty' \
  | tr 'A-Z' 'a-z' \
  | tr -cs 'a-z0-9' '\n' \
  | grep -v '^$' \
  | grep -vwE 'the|and|for|you|your|with|from|this|that|are|was|were|have|has|had|not|but|our|out|new|now|all|any|can|will|just|its|it|to|of|in|on|at|as|by|or|be|is|an|a|we|me|my|he|she|they|them|us|do|did|does|if|then|than|so|no|yes|re|fwd|via|per|about|up|when|what|who|how' \
  | sort | uniq -c | sort -rn | head -40
