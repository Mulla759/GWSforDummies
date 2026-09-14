# GWS for Dummies — email triage made easy

> **Note:** This is **not** an officially supported Google product. It's a personal,
> open-source project that builds on Google's
> [`gws` CLI](https://github.com/googleworkspace/cli).

A **layman-friendly email triage toolkit**. You type what you want in plain English —
*"triage my inbox and label everything"* — and it sorts, labels, and organizes your
Gmail for you. No code to write, no rules to memorize. Under the hood it drives the
[Google Workspace CLI (`gws`)](https://github.com/googleworkspace/cli) with a small team
of focused AI sub-agents, all running against **your own** Google account.

```bash
gws-do "triage my inbox"
gws-do "turn my action-required mail into tasks and calendar events"
gws-do "give me my weekly digest"
gws-do --list      # everything it can do      gws-do --status   # is it ready?
```

> This is the **simple, public, email-triage** edition. You describe a goal; it gets
> **routed** to the right sub-agent and run for you.

## Let your agent set it up

Don't want to read the steps? Give this line to Claude Code, Cursor, or any coding agent:

```text
set up gws for dummies — https://gwsfordummies.to/llms.txt
```

That page is a single agent-readable runbook covering the whole install: the toolchain,
the **Google Cloud project + OAuth consent + `client_secret.json`** process, `gws auth`,
cloning this repo, the first triage run, and the nightly GitHub Action.

## What it does

| You ask for… | It… |
|---|---|
| inbox triage / labeling | scans mail, flags phishing, labels by category & priority |
| tasks / calendar from email | turns action-required mail into Google Tasks & Calendar events (with your OK) |
| weekly digest | summarizes this week's meetings + unread + what got labeled |
| nightly labeling | applies your sender→label rules automatically, even with your PC off |

## Prerequisites

Before the quickstart, you'll need:

- A **Google account** — the inbox you want to triage.
- A **Google Cloud project** (free) — required for OAuth credentials so `gws` can reach
  your Gmail/Calendar/Tasks. Create one at
  [console.cloud.google.com](https://console.cloud.google.com/projectcreate); [`SETUP.md`](SETUP.md)
  walks through enabling the APIs and downloading your `client_secret.json`.
- **Node.js 18+** — to install the `gws` CLI.
- **`gws`** (Google Workspace CLI) + **`jq`** — `setup.sh` installs `gws` and checks `jq`.
- **Claude Code** (the default AI harness) and its credentials — or swap in another agent
  framework via `harness/`.

## Quickstart (~5 minutes, macOS + Windows + Linux)

```bash
git clone https://github.com/Mulla759/GWSforDummies.git && cd GWSforDummies
./setup.sh                                   # installs gws, checks jq/auth/harness
gws auth login -s "gmail,tasks,calendar"     # sign in to YOUR Google account (one-time)
export PATH="$PWD/bin:$PATH"                 # so `gws-do` is on your path
gws-do --status
gws-do "triage my inbox"
```

First-time Google OAuth (your own free GCP project + `client_secret.json`) is walked
through in [`SETUP.md`](SETUP.md) — or let an agent do it via
[`gwsfordummies.to/llms.txt`](https://gwsfordummies.to/llms.txt).

> **Windows note:** the safety hook ships as `python3` (macOS/Linux). On Windows, change
> it to `python` in `.claude/settings.json`, and run `gws-do` via `bin/gws-do.cmd`.

## Safe by design

Two enforcement layers mean it **reads and labels, but never sends, trashes, or deletes**:
`.claude/settings.json` permissions + a per-agent allowlist enforced by a `PreToolUse`
hook. Each sub-agent gets only the `gws` commands its job needs. Email bodies are treated
as untrusted (links are never auto-opened). See [`CLAUDE.md`](CLAUDE.md).

## How labeling works

Labeling is **deterministic and needs no AI at run time**. It runs off one small data
file — [`scripts/label-rules.tsv`](scripts/label-rules.tsv) — so the same inbox always
produces the same result.

- **Common pathways.** The default taxonomy maps mail to ~10 everyday buckets: Finance,
  Receipts & Orders, Newsletters, Shopping, Tech & Learning, Travel, Events, Security,
  Social — plus a **Priority** overlay. Each pathway is one row:
  `<label> <TAB> <from-domains> <TAB> <subject-terms>`.
- **Sender vs subject.** A row matches `from:(domain OR domain)`, a Gmail subject
  expression (e.g. `"action required" OR overdue`), or both — so "receipt"/"order shipped"
  mail from anywhere is caught even when the sender is new.
- **Curated for *your* inbox.** After you authenticate, the **`label-rules-curator`**
  agent runs [`scripts/discover-senders.sh`](scripts/discover-senders.sh) — a read-only
  helper that lists your top sender domains and subject words (last 90 days) — maps them
  onto the pathways, creates any missing labels, and writes `label-rules.tsv`. Then the
  nightly run just applies it:

  ```bash
  gws-do --action curate-labels       # one-time, after `gws auth` (runs the curator)
  bash scripts/discover-senders.sh    # or inspect the pathways yourself, read-only
  ```
- **Self-sufficient & idempotent.** [`scripts/nightly-label.sh`](scripts/nightly-label.sh)
  creates a missing label on the fly (from Gmail's palette), **adds** labels with
  `messages batchModify`, and re-labeling is a no-op. Preview without changing anything:

  ```bash
  bash scripts/nightly-label.sh --dry-run              # per-label counts, last 2 days
  bash scripts/nightly-label.sh --dry-run newer_than:30d
  ```
- **Only labels.** It never removes labels and never sends, trashes, or deletes. It needs
  only the Gmail `modify` + label scope (`gws auth login -s "gmail,tasks,calendar"`).

## Make it yours / extend it

- **Customize labeling:** run `gws-do --action curate-labels` (the `label-rules-curator`
  agent) to re-derive the rules from your inbox, or edit
  [`scripts/label-rules.tsv`](scripts/label-rules.tsv) by hand.
- **Add an automation:** drop a manifest in [`actions/`](actions/README.md) — no code changes.
- **Swap the AI engine:** one line in `harness/harness.config` (Claude Code is the
  default; bring any other agent framework). Architecture: [`ORCHESTRATOR.md`](ORCHESTRATOR.md).
- **Want more agents & skills?** The Google Workspace CLI ships 100+ agent skills
  (per-service helpers, recipes, personas). Browse and add them from the original repo →
  **[github.com/googleworkspace/cli](https://github.com/googleworkspace/cli)**.

## Project layout

| Path | Role |
|---|---|
| `bin/gws-do` (+ `.cmd`) | the top-level plain-English command |
| `orchestrator/router.sh` | registry + routing (agent-first, keyword + menu fallback) |
| `actions/*.json` | one manifest per automation (see [`actions/README.md`](actions/README.md)) |
| `.claude/agents/` | the isolated sub-agents + their `.allowlist`s |
| `scripts/` | deterministic, no-LLM helpers (nightly labeler, weekly digest) |
| `harness/` | the swappable AI-engine adapters |
| `SETUP.md` · `COMMANDS.md` · `GITHUB-ACTIONS.md` | setup, `gws` cheat-sheet, cloud nightly run |

## Credits

- **Author:** [@Mulla759](https://github.com/Mulla759)
- **Original concept:** [Justin Poehnelt](https://github.com/jpoehnelt) — this is modeled on
  his *subagent-email-triage* demonstration.
- **Engine:** the [Google Workspace CLI (`gws`)](https://github.com/googleworkspace/cli)
  by Google Workspace.

---
*Not an official Google product, and not affiliated with Google or the `gws` maintainers.
`gws` is pre-1.0 — expect occasional breaking changes. Provided as-is, MIT-style; use at
your own risk against your own account.*
