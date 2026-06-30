# Setup

One-time setup to make this folder ready to triage **you@example.com**.
Work top to bottom — the project does nothing until steps 1–3 are done.

## 0. Toolchain

| Tool | macOS | Windows |
|---|---|---|
| Claude Code | `npm i -g @anthropic-ai/claude-code` | same |
| `gws` 0.22.5+ | `npm i -g @googleworkspace/cli` | same |
| `jq` | `brew install jq` | `winget install jqlang.jq` |
| Node.js 18+ | `brew install node` | `winget install OpenJS.NodeJS` |
| Python 3.10+ | pre-installed (`python3`) | `python` or `py` on PATH |

To verify: `gws --version` · `jq --version` · `python3 --version` (or `python --version`).

## 1. Platform-specific hook config

The bash guard hook in `.claude/settings.json` uses `python3` (macOS) or `python` (Windows).
Check that the command matches your platform:

```json
"command": "python3 .claude/hooks/bash-guard.py"   // macOS
"command": "python .claude/hooks/bash-guard.py"     // Windows
```

Also check `.claude/hooks/bash-guard.sh`:
```bash
exec python3 "$(dirname "$0")/bash-guard.py" "$@"   # macOS
exec python "$(dirname "$0")/bash-guard.py" "$@"     # Windows (Git Bash)
```

## 2. Create a Google Cloud project + OAuth client

`gws` needs OAuth credentials. The project already exists: **<YOUR_PROJECT_ID>**.

If setting up from scratch:

1. Create/pick a GCP project, enable the **Gmail API**, **Calendar API**, **Tasks API**.
2. OAuth consent screen -> **External** (testing mode is fine) -> add
   **you@example.com** under **Test users**.
3. Credentials -> Create OAuth client -> type **Desktop app** -> download the JSON.
4. Place it at `~/.config/gws/client_secret.json`
   (Windows: `%USERPROFILE%\.config\gws\client_secret.json`).

## 3. Log in with all scopes

```bash
gws auth login -s gmail,tasks,calendar
```

Approve in the browser. If you see "Google hasn't verified this app" -> Advanced ->
continue (safe for personal use).

Confirm it works:

```bash
gws gmail users messages list --params '{"userId":"me","maxResults":1}'
gws tasks tasklists list
gws calendar calendarList list
```

## 4. Run the agents

### Email Triage (Phase 1)

```bash
claude --agent email-triage-orchestrator
```

Then say **"Triage my inbox."** Start small — triage 5 messages first.

### Email Actions (Phase 2)

```bash
claude --agent email-action-orchestrator
```

Proposes tasks/events for `triage/action-required` mail. Confirms before creating.

## 5. (Optional) Nightly auto-labeler

A deterministic labeler runs nightly and tags new inbox mail by sender->label rules.
No LLM needed. See `scripts/nightly-label.sh`.

### Windows Task Scheduler

```powershell
# Register (one-time):
$action = New-ScheduledTaskAction -Execute "C:\Program Files\Git\bin\bash.exe" `
  -Argument "-lc `"<repo-path>/scripts/nightly-label.sh >> <repo-path>/scripts/nightly-label.log 2>&1`""
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
Register-ScheduledTask -TaskName gws-nightly-label -Action $action -Trigger $trigger

# Manage:
Get-ScheduledTaskInfo -TaskName gws-nightly-label
Start-ScheduledTask   -TaskName gws-nightly-label
```

### macOS launchd

```bash
# Or just run manually:
bash scripts/nightly-label.sh
```

### GitHub Actions (cloud — PC can be off)

See [`GITHUB-ACTIONS.md`](GITHUB-ACTIONS.md). Requires a `GWS_CREDENTIALS` repo secret.

---

## Safety recap

- **Nothing sends, trashes, or deletes.** Those verbs are denied in
  `.claude/settings.json` and absent from every agent allowlist.
- Each subagent is limited to the exact `gws` commands its job needs, enforced by
  `.claude/hooks/bash-guard.py` per `agent_type`.
- Email bodies and links are treated as untrusted; links are never auto-opened.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `gws` not found | Reopen terminal; confirm `npm` global bin is on PATH. |
| "Access blocked" / 403 at login | Add you@example.com as a **Test user** on the consent screen. |
| Too many scopes error | Log in with `-s gmail` (don't use the full preset). |
| `accessNotConfigured` 403 | Enable the Gmail/Calendar/Tasks API for the project. |
| Hook error about `python` | Ensure `python3` (macOS) or `python` (Windows) is on PATH; edit `.claude/settings.json` hook command accordingly. |
| `jq: command not found` | Install `jq` — agents pipe JSON through it. |
| `403 insufficientPermissions` after adding scopes | Stale access token cached. Delete `~/.config/gws/token_cache.json` and retry. |
| `Using keyring backend: keyring` breaks jq | Pipe through `sed '/^Using keyring backend:/d'` before `jq`. |
