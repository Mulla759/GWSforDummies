#!/usr/bin/env bash
# weekly-digest.sh — a read-only weekly summary: this week's meetings, unread
# email count, and how much inbox mail got labeled in the last 7 days.
#
# This is the worked example of "add an automation by dropping a manifest":
# see actions/weekly-digest.json. No AI, no writes, only `gws` reads.
set -uo pipefail
# Portable PATH (mac + windows), same pattern as nightly-label.sh:
if [ -n "${HOME:-}" ] && [ -d "$HOME/AppData/Roaming/npm" ]; then
  export PATH="$HOME/AppData/Roaming/npm:$HOME/AppData/Local/Microsoft/WinGet/Links:$PATH"
fi

echo "=== Weekly digest — $(date +'%Y-%m-%d %H:%M %Z') ==="

# 1) Meetings this week + unread count (gws built-in helper, read-only)
gws workflow +weekly-digest 2>/dev/null | jq -r '
  "Window     : \(.periodStart[0:10]) -> \(.periodEnd[0:10])",
  "Unread     : \(.unreadEmails)",
  "Meetings   : \(.meetingCount)",
  ( .meetings[]? | "   • \(.start[0:16] | sub("T";" "))  \(.summary)" )
'

# 2) What got labeled in the last 7 days, by label (shows the automation working)
echo "Labeled (7d):"
for L in Finance Newsletters Shopping "Tech & Learning" Travel Events Security \
         "Job Alerts" Applications Personal School Priority; do
  n=$(gws gmail users messages list \
        --params "$(jq -n --arg q "in:inbox newer_than:7d label:\"$L\"" '{userId:"me",q:$q,maxResults:500}')" \
        --page-all 2>/dev/null | jq -s '[.[].messages[]?.id] | length')
  [ "${n:-0}" -gt 0 ] && printf '   %-22s %s\n' "$L" "$n"
done
echo "=== end digest ==="
