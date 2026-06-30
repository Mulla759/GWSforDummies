#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""PreToolUse(Bash) guard — single GLOBAL hook, dispatches by agent_type.

Registered ONCE as a global PreToolUse(Bash) hook in settings.json (not per-agent
frontmatter hooks, which STACK: a subagent's call is checked against every
ancestor's hook, which forced the orchestrator allowlist to be a superset of all
subagents'). This guard instead reads `agent_type` from the hook payload and
enforces only that agent's allowlist — so each agent is governed independently.

Allowlist resolution:
  1. explicit path as argv[1]                  (back-compat / testing)
  2. agent_type -> .claude/agents/<agent_type>.allowlist
  3. no agent_type, or no matching file        -> ALLOW (exit 0)

So the top-level/dev session (no agent_type) and agents without an allowlist are
never blocked here; settings.json permissions still apply as the outer layer.

Within a resolved allowlist, validates EVERY command in a pipeline/chain: each
segment must match an allowlist prefix or be a read-only SAFE_FILTER. Quoting is
respected via shlex. Command substitution, subshells, redirects, and
backgrounding are always blocked.
"""
import sys
import os
import json
import shlex

# .claude/hooks/ -> .claude/agents/
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
AGENTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "agents")

# Read-only filters allowed as any segment of a pipeline. Deliberately excludes
# anything that can write files or exec (sed -w, awk, python, xargs, tee, ...).
SAFE_FILTERS = {
    "jq", "grep", "egrep", "fgrep", "head", "tail",
    "cut", "sort", "uniq", "wc", "tr", "cat", "rev", "nl", "column",
}

# Tokens that separate one command from the next. Each side is validated.
SEPARATORS = {"|", "|&", "&&", "||", ";"}

# Operators we refuse outright: subshell, redirect, backgrounding.
FORBIDDEN = {"&", "(", ")", "<", ">", ">>", "<<", "<<<", ">|", "<>", "{", "}"}


def block(msg):
    sys.stderr.write("Blocked by bash-guard: %s\n" % msg)
    sys.exit(2)


def main():
    # Read the whole hook payload once (need both agent_type and the command).
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        # Unparseable payload: don't brick bash — defer to settings.json permissions.
        sys.exit(0)

    # Resolve which allowlist governs this call.
    if len(sys.argv) >= 2 and sys.argv[1]:
        allowlist_file = sys.argv[1]                      # explicit (back-compat/testing)
    else:
        agent = payload.get("agent_type")
        if not agent:
            sys.exit(0)                                   # top-level/dev session -> allow
        allowlist_file = os.path.join(AGENTS_DIR, "%s.allowlist" % agent)

    if not os.path.isfile(allowlist_file):
        sys.exit(0)                                       # no allowlist for this agent -> allow

    prefixes = []
    with open(allowlist_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            prefixes.append(line.split())

    cmd = ((payload.get("tool_input") or {}).get("command") or "")
    if not cmd.strip():
        sys.exit(0)

    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    try:
        tokens = list(lex)
    except ValueError as e:
        block("could not parse command (%s) — check quoting" % e)

    # Walk tokens, splitting into command segments and rejecting dangerous ones.
    segments = [[]]
    for t in tokens:
        # Catches quoted substitution like "$(...)" that shlex keeps in-token.
        if "`" in t or "$(" in t:
            block("command substitution is not allowed")
        if t in FORBIDDEN:
            block("operator %r (subshell/redirect/background) is not allowed" % t)
        if t in SEPARATORS:
            segments.append([])
        else:
            segments[-1].append(t)

    def allowed(seg):
        if not seg:
            return False
        if seg[0] in SAFE_FILTERS:
            return True
        return any(seg[:len(p)] == p for p in prefixes)

    for seg in segments:
        if not seg:
            block("empty command segment (dangling operator)")
        if not allowed(seg):
            block("command not allowed: %r "
                  "(not an allowlist prefix or safe filter)" % " ".join(seg))

    sys.exit(0)


if __name__ == "__main__":
    main()
