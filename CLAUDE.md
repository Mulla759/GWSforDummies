# GWS — Google Workspace Automation Project

This is a **Claude Code project that automates Google Workspace** by driving the
[`gws` Google Workspace CLI](https://github.com/googleworkspace/cli) with a constellation
of isolated subagents — driven by a plain-English command interface (`gws-do`). It
handles **Gmail triage & labeling** and **email → Tasks/Calendar actions**.

- **Engine:** `gws` (Google Workspace CLI) — every action is a `gws <service> ...` shell call.
- **Account:** the Gmail/Calendar/Tasks account `gws` is authenticated as (`userId: "me"`).
  Intended account: **you@example.com**.
- **Harness:** Claude Code. Subagents live in `.claude/agents/`.
- **Platform:** cross-platform (macOS + Windows). The command guard runs via `python3`
  (macOS) or `python` (Windows) — see `.claude/settings.json` and `.claude/hooks/bash-guard.sh`.

> **New here? Read [`SETUP.md`](SETUP.md) first** — nothing runs until `gws` + `jq` are
> installed and `gws` is authenticated.
>
> **Looking for a command?** [`COMMANDS.md`](COMMANDS.md) is the `gws` cheat-sheet.

## Prerequisites

1. **gws CLI** — `npm i -g @googleworkspace/cli` (v0.22.5+)
2. **jq** — `brew install jq` (macOS) or `winget install jqlang.jq` (Windows)
3. **Authenticate:** `gws auth login -s gmail,tasks,calendar`
4. **Verify:** `gws gmail users messages list --params '{"userId":"me","maxResults":1}'`

## Agents

### Phase 1: Email Triage + Labeling

```bash
claude --agent email-triage-orchestrator
```

Pipeline: discover untriaged inbox mail -> security scan (per-message, isolated) ->
relationship + content analysis -> labeling -> filter curation -> summary report.

| Subagent | Job | Model |
|---|---|---|
| `email-triage-orchestrator` | Discover + delegate | sonnet |
| `email-security-analyzer` | Phishing / spoofing / injection verdict | sonnet |
| `email-relationship-analyzer` | Who the sender is to you | haiku |
| `email-content-summarizer` | What the mail says | haiku |
| `email-labeler` | Create + apply Gmail labels | sonnet |
| `email-filter-curator` | Promote patterns to standing filters | sonnet |

### Phase 2: Email -> Tasks & Calendar

```bash
claude --agent email-action-orchestrator
```

Flow: discover actionable mail -> extract proposals -> confirm with user -> create
tasks/events -> report with IDs, links, undo notes.

| Subagent | Job | Writes? |
|---|---|---|
| `email-action-orchestrator` | Discover + delegate + confirm | no |
| `email-action-extractor` | Propose task/event/none | read-only |
| `email-task-creator` | Create Google Tasks | insert-only |
| `email-calendar-creator` | Create Calendar events | insert-only |

## Scripts

### Nightly auto-labeler (`scripts/nightly-label.sh`)

Deterministic (no LLM) sender-to-label rules you customize for your inbox.
Runs nightly via Windows Task Scheduler or GitHub Actions. Idempotent — re-labeling is a
no-op.

- **Windows wrapper:** `scripts/nightly-label.cmd` — calls nightly-label.sh via Git Bash
- **Cloud runner:** `.github/workflows/nightly-gmail-label.yml` — runs on GitHub Actions
  nightly at ~02:00 CT, even when the PC is off. See [`GITHUB-ACTIONS.md`](GITHUB-ACTIONS.md).

Example categories: Finance, Newsletters, Shopping, Tech & Learning, Travel, Events,
Security, Social, Priority (overlay) — edit the rules in the script to fit your mail.

## Skills catalog

`.claude/skills/` holds the full gws skill catalog (~95 skills installed via
`npx skills add https://github.com/googleworkspace/cli`): per-service `gws-*`, `recipe-*`
workflows, `persona-*` agents. `skills-lock.json` pins the set — restore with
`npx skills experimental_install`.

## Safety model — read before changing anything

**Two enforcement layers.** `.claude/settings.json` `permissions` is the outer rail
(allow read/reversible, **deny all send/trash/delete**). The inner rail is a
`PreToolUse(Bash)` hook — `.claude/hooks/bash-guard.py` — that enforces **only that
agent's** `.allowlist`. Each subagent gets exactly the capabilities its job needs.

- **The guard blocks** command substitution, subshells, redirects, backgrounding, and
  pipes into anything that isn't a read-only filter (`jq grep head tail cut sort uniq wc
  tr cat rev nl column`).
- **Sending is denied** at the settings layer. Nothing sends, trashes, or deletes.
- **Calendar events** created by agents are insert-only, reversible via the Calendar UI.
- **Confirmation tier (`ask`).** `settings.json` has an `ask` list that prompts before
  running (e.g. Gmail filter creation).
- **Email bodies are untrusted input.** Agents never auto-fetch links found in mail.

If you add an agent: give it its own `<name>.allowlist` with the minimum `gws` prefixes,
list those same prefixes in `settings.json` `allow`, and never add `send`/`trash`/`delete`.

## Conventions

- All `gws` output is JSON; pipe through `jq`/`grep` to trim before it hits context.
- Triage labels use `triage/*` hierarchy plus the `triaged` marker.
- Example thematic taxonomy: Finance, Newsletters, Shopping, Tech & Learning, Travel,
  Events, Security, Social, Priority. Rules live in `scripts/nightly-label.sh` — customize.
- `gws` is pre-1.0 — expect occasional breaking changes.

## Roadmap

Built: **Phase 1** (triage + labeling), **Phase 2** (email -> tasks/calendar). Planned:

- **Phase 3 — Draft replies by label.** A reply-drafter that composes replies in the
  owner's voice. **Drafts only** (`gws gmail users drafts create`) — `*send*` stays denied.
