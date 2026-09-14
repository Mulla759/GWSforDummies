# gws-do — the modular command harness

A single top-level interface for every GWS automation. You **describe a goal**, it gets
**routed through an AI agent**, and **delegated to the right sub-agent** — all running on
the local `gws` CLI as the shared engine. It is deliberately **harness-agnostic** and
**plug-and-play** so others can replicate the exact workflow with their own credentials,
and so the AI engine can be swapped (Claude today, an open-source agent tomorrow).

```
  gws-do "triage my inbox and label everything"
        │
        ▼
  ┌─────────────┐   reads    ┌──────────────┐
  │  router.sh  │──────────▶ │ actions/*.json│   (the registry — what's possible)
  └─────┬───────┘            └──────────────┘
        │ route THROUGH the harness (describe → choose action id)
        ▼
  ┌──────────────────────┐   swap one line   ┌───────────────────────────┐
  │ harness/<HARNESS>.sh │ ◀──────────────── │ harness/harness.config    │
  │  (Claude Code = dflt)│                   │   HARNESS=claude-code      │
  └─────┬────────────────┘                   └───────────────────────────┘
        │ delegate to the designated sub-agent / script
        ▼
  .claude/agents/<sub-agent>   or   scripts/<script>     ── all call `gws` ──▶ Google
```

## Layout

| Path | Role |
|---|---|
| `bin/gws-do` (+ `.cmd`) | the top-level command you run; no slash commands involved |
| `orchestrator/router.sh` | registry + routing (agent-first, keyword + menu fallback) + dispatch |
| `harness/harness.config` | **the one line you change to swap the AI engine** |
| `harness/claude-code.sh` | default adapter (Claude Code) |
| `harness/_template.sh` | copy this to add any other agent framework |
| `actions/*.json` | the registry — one manifest per automation (see `actions/README.md`) |
| `setup.sh` | new-user bootstrap (engine + Google auth + harness check) |

## The 4-function harness contract

Everything AI-specific lives behind four shell functions, so the rest of the system never
mentions Claude (or any vendor):

- `harness_name` — display name
- `harness_check` — are the CLI + AI credentials ready?
- `harness_route goal catalog` — print the best action `id` for a goal
- `harness_run_agent agent goal interactive` — run a named sub-agent

To drive this with a different agent framework: `cp harness/_template.sh harness/foo.sh`,
implement the four functions, set `HARNESS=foo`. **Nothing else changes.**

## Routing precedence

1. `--action <id>` explicit override
2. **Agent route** — the harness picks the action from your description (the "additional
   logic" layer). Default `ROUTER=agent`.
3. **Keyword route** — deterministic, works with no AI (good for scripts / offline).
4. **Menu** — pick from the list.

## Replicate it (plug & play)

Anyone can get this exact workflow:

```bash
git clone https://github.com/Mulla759/GWSforDummies.git && cd GWSforDummies
./setup.sh                 # installs gws + jq, checks Google auth + AI harness
gws auth login -s "gmail,tasks,calendar"   # their own Google account (one-time OAuth)
# bring your own AI credentials for the harness (e.g. Claude login or ANTHROPIC_API_KEY)
bin/gws-do --status
bin/gws-do "triage my inbox and label everything"
```

- **Google auth is unchanged** — still `gws auth` against the user's own account.
- **AI auth is theirs** — set per the chosen harness; `setup.sh` tells them what's missing.
- **Swappable engine** — change `harness.config` to use a non-Claude agent.
- **Extensible** — drop a manifest in `actions/` to add automations (`actions/README.md`).

## Examples

```bash
gws-do "give me my weekly digest"           # -> weekly-digest
gws-do "turn my action-required mail into tasks"  # -> email-action-orchestrator
gws-do --action nightly-label               # -> runs the deterministic labeler (no AI)
gws-do --dry-run "clean up my inbox"        # show routing, run nothing
gws-do --list                               # everything available
```
