#!/usr/bin/env bash
# nightly-label.sh — deterministic (no LLM) sender/subject -> Gmail labeler.
# ============================================================================
# WHAT IT DOES
#   Reads a curated rules file (TAB-separated) and applies each rule's label to
#   matching NEW inbox mail. Idempotent: re-applying a label already on a
#   message is a no-op, so running it repeatedly (or over an overlapping window)
#   is safe.
#
# USAGE
#   nightly-label.sh [--dry-run] [WINDOW]
#     --dry-run   Report how many messages each rule WOULD label; change nothing.
#                 May appear anywhere in the argument list.
#     WINDOW      Gmail search window appended to "in:inbox"; default
#                 "newer_than:2d" so a skipped night is still covered next run.
#
# RULES FORMAT (default: scripts/label-rules.tsv, override with $RULES)
#   <label> <TAB> <from-domains> <TAB> <subject-terms>
#     * label         : Gmail label name (created here if missing).
#     * from-domains  : space-separated bare domains; "-" for subject-only.
#     * subject-terms : a raw Gmail subject expression, already OR-joined and
#                       quoted, e.g.  "action required" OR overdue ; empty for sender-only.
#     * "#" comments and blank lines are ignored.
#
# SCOPES / PERMISSIONS
#   Needs Gmail read+modify (gmail.modify) to list and label messages, and the
#   label-create capability (same gmail scope) to create missing labels.
#
# SEE ALSO
#   scripts/discover-senders.sh  — read-only helper to discover real senders.
#   `label-rules-curator` agent  — writes this rules file after `gws auth`.
#
# Requires: gws (authenticated), jq on PATH.
# ============================================================================
set -uo pipefail
# Platform PATH fixup — only prepend when the dirs exist, so this one script works
# on Windows (Git Bash via Task Scheduler), macOS, and Linux (GitHub Actions).
for d in \
  "/c/Users/${USERNAME:-}/AppData/Roaming/npm" \
  "/c/Users/${USERNAME:-}/AppData/Local/Microsoft/WinGet/Links" \
  "${HOME:-}/.npm-global/bin"; do
  [ -n "$d" ] && [ -d "$d" ] && export PATH="$d:$PATH"
done

DRY_RUN=0
WINDOW=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) WINDOW="$arg" ;;
  esac
done
WINDOW="${WINDOW:-newer_than:2d}"

RULES="${RULES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/label-rules.tsv}"
SCOPE="in:inbox $WINDOW"

if [ ! -f "$RULES" ]; then
  echo "[nightly-label] ERROR: rules file not found: $RULES" >&2
  echo "  Run scripts/discover-senders.sh, then have the label-rules-curator" >&2
  echo "  agent write the rules file. Refusing to silently do nothing." >&2
  exit 1
fi

# Resolve a label NAME -> id at runtime (robust to id changes / new accounts).
lid(){ gws gmail users labels list --params '{"userId":"me"}' 2>/dev/null \
        | jq -r --arg n "$1" '.labels[] | select(.name==$n) | .id'; }

# Resolve a label NAME -> id, creating the label if it does not exist.
# Prints the id on stdout; notes/diagnostics go to stderr so callers can capture.
ensure_label(){ # $1=label name
  local id bg fg
  id="$(lid "$1")"
  if [ -z "$id" ]; then
    case "$1" in
      Priority) bg="#ffad47"; fg="#000000" ;;
      Security) bg="#fb4c2f"; fg="#ffffff" ;;
      *)        bg="#4a86e8"; fg="#ffffff" ;;
    esac
    echo "  + new label: $1" >&2
    id="$(gws gmail users labels create --params '{"userId":"me"}' \
          --json "$(jq -n --arg n "$1" --arg bg "$bg" --arg fg "$fg" \
                   '{name:$n,color:{backgroundColor:$bg,textColor:$fg}}')" 2>/dev/null \
          | jq -r '.id // empty')"
    if [ -z "$id" ]; then
      # Some accounts reject colors — retry without them.
      id="$(gws gmail users labels create --params '{"userId":"me"}' \
            --json "$(jq -n --arg n "$1" '{name:$n}')" 2>/dev/null \
            | jq -r '.id // empty')"
    fi
  fi
  printf '%s' "$id"
}

apply(){ # $1=label name  $2=from-domains  $3=subject-terms (optional)
  local label="$1" from="$2" subject="${3:-}" id q ids cnt

  q="$SCOPE"
  if [ -n "$from" ] && [ "$from" != "-" ]; then
    q="$q from:($(printf '%s' "$from" | sed -E 's/[[:space:]]+/ OR /g'))"
  fi
  if [ -n "$subject" ]; then
    q="$q subject:($subject)"
  fi

  ids="$(gws gmail users messages list \
           --params "$(jq -n --arg q "$q" '{userId:"me",q:$q,maxResults:500}')" \
           --page-all 2>/dev/null \
         | jq -s '[.[].messages[]?.id]')"
  cnt="$(printf '%s' "$ids" | jq 'length' 2>/dev/null)"
  [ -z "$cnt" ] && cnt=0

  if [ "$DRY_RUN" = 1 ]; then
    echo "  $label: $cnt (dry-run)"
    return
  fi

  id="$(ensure_label "$label")"
  [ -z "$id" ] && { echo "  ! could not resolve/create label: $label" >&2; return; }

  if [ "$cnt" -gt 0 ]; then
    gws gmail users messages batchModify --params '{"userId":"me"}' \
      --json "$(jq -n --argjson ids "$ids" --arg l "$id" '{ids:$ids,addLabelIds:[$l]}')" \
      >/dev/null 2>&1 \
      && echo "  $label: +$cnt" || echo "  $label: ERR"
  else
    echo "  $label: 0"
  fi
}

echo "[nightly-label] $(date) -- window: $WINDOW$([ "$DRY_RUN" = 1 ] && echo ' (dry-run)')"

while IFS=$'\t' read -r label from subject; do
  case "$label" in ''|'#'*) continue ;; esac
  apply "$label" "$from" "${subject:-}"
done < "$RULES"

echo "[nightly-label] done"
