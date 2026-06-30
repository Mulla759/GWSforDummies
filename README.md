# GWS for Dummies — email triage made easy

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

## What it does

| You ask for… | It… |
|---|---|
| inbox triage / labeling | scans mail, flags phishing, labels by category & priority |
| tasks / calendar from email | turns action-required mail into Google Tasks & Calendar events (with your OK) |
| weekly digest | summarizes this week's meetings + unread + what got labeled |
| nightly labeling | applies your sender→label rules automatically, even with your PC off |

## Quickstart (~5 minutes, macOS + Windows)

```bash
git clone https://github.com/Mulla759/GWSforDummies.git && cd GWSforDummies
./setup.sh                                   # installs gws + jq, checks readiness
gws auth login -s "gmail,tasks,calendar"     # sign in to YOUR Google account (one-time)
export PATH="$PWD/bin:$PATH"
gws-do --status
gws-do "triage my inbox"
```

First-time Google OAuth (your own free GCP project + `client_secret.json`) is walked
through in [`SETUP.md`](SETUP.md).

> **Windows note:** the safety hook ships as `python3` (macOS). On Windows, change it to
> `python` in `.claude/settings.json`, and run `gws-do` via `bin/gws-do.cmd`.

## Safe by design

Two enforcement layers mean it **reads and labels, but never sends, trashes, or deletes**:
`.claude/settings.json` permissions + a per-agent allowlist enforced by a `PreToolUse`
hook. Each sub-agent gets only the `gws` commands its job needs. Email bodies are treated
as untrusted (links are never auto-opened). See [`CLAUDE.md`](CLAUDE.md).

## Make it yours / extend it

- **Customize labeling:** edit the example sender→label rules in `scripts/nightly-label.sh`.
- **Add an automation:** drop a manifest in [`actions/`](actions/README.md) — no code changes.
- **Swap the AI engine:** one line in `harness/harness.config` (Claude Code is the
  default; bring any other agent framework). Architecture: [`ORCHESTRATOR.md`](ORCHESTRATOR.md).

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
