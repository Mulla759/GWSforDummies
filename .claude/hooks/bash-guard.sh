#!/usr/bin/env bash
# PreToolUse(Bash) guard. Usage: bash-guard.sh <allowlist_file>
# Thin wrapper: parsing/validation lives in bash-guard.py (quote-aware,
# per-segment allowlist check) so pipelines into safe filters are permitted
# while substitution/redirects/non-allowlisted commands stay blocked.
exec python3 "$(dirname "$0")/bash-guard.py" "$@"
