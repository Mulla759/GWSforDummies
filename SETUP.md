# Setup

One-time setup to make this folder ready to triage **your own Gmail account**
(`you@example.com` below is a placeholder — you never type your address anywhere; `gws`
gets it from the login). Work top to bottom — the project does nothing until steps 1–3
are done.

> **Prefer an agent do it?** Point your AI assistant at
> [`https://gws-for-dummies.vercel.app/llms.txt`](https://gws-for-dummies.vercel.app/llms.txt) — the same steps
> below, written as a single agent-readable runbook (install → Google OAuth → auth →
> triage → nightly Action).

## 0. Toolchain

| Tool | macOS | Windows | Linux |
|---|---|---|---|
| Claude Code | `npm i -g @anthropic-ai/claude-code` | same | same |
| `gws` 0.22.5+ | `npm i -g @googleworkspace/cli` | same | same |
| Node.js 18+ | `brew install node` | `winget install OpenJS.NodeJS` | distro `nodejs`/`npm` |
| `jq` | `brew install jq` | `winget install jqlang.jq` | `sudo apt-get install jq` |
| Python 3.10+ | pre-installed (`python3`) | `python` or `py` on PATH | distro `python3` |

To verify: `gws --version` · `jq --version` · `python3 --version` (or `python --version`).

## 1. Platform-specific hook config

The bash guard hook in `.claude/settings.json` uses `python3` (macOS/Linux) or `python`
(Windows). Check that the command matches your platform:

```json
"command": "python3 .claude/hooks/bash-guard.py"   // macOS / Linux
"command": "python .claude/hooks/bash-guard.py"     // Windows
```

Also check `.claude/hooks/bash-guard.sh`:
```bash
exec python3 "$(dirname "$0")/bash-guard.py" "$@"   # macOS / Linux
exec python "$(dirname "$0")/bash-guard.py" "$@"     # Windows (Git Bash)
```

## 2. Create a Google Cloud project + OAuth client

`gws` needs OAuth credentials of your own. There is nothing to reuse — create your own
free project once:

1. **Create/pick a GCP project** at
   [console.cloud.google.com/projectcreate](https://console.cloud.google.com/projectcreate).
   Note the **project ID** (looks like `my-project-123456`).
2. **Enable the three APIs** for that project (APIs & Services → Library, or the links):
   - Gmail API — `https://console.cloud.google.com/apis/library/gmail.googleapis.com`
   - Google Calendar API — `https://console.cloud.google.com/apis/library/calendar-json.googleapis.com`
   - Google Tasks API — `https://console.cloud.google.com/apis/library/tasks.googleapis.com`

   Or with `gcloud`:
   ```bash
   gcloud services enable gmail.googleapis.com calendar-json.googleapis.com tasks.googleapis.com --project <YOUR_PROJECT_ID>
   ```
3. **Configure the OAuth consent screen** (APIs & Services → OAuth consent screen):
   - User type **External** (testing mode is fine for personal use).
   - Add your own Gmail address under **Test users**.
   - You do **not** need to add scopes manually — `gws` requests them at login.
4. **Create an OAuth client**: Credentials → **Create credentials** → **OAuth client ID**
   → application type **Desktop app** → **Create**, then **Download JSON**.
5. **Place the downloaded file** at:
   ```
   ~/.config/gws/client_secret.json                                   # macOS / Linux
   %USERPROFILE%\.config\gws\client_secret.json                       # Windows
   ```
   (`.gitignore` already blocks `client_secret*.json`, so it can never be committed.)

> **Doing cloud/CI later?** Before step 6, also publish the app to **Production**
> (OAuth consent screen → **Audience → Publish app**). In testing mode Google expires the
> refresh token after **7 days**; publishing stops that. See [`GITHUB-ACTIONS.md`](GITHUB-ACTIONS.md).

## 3. Log in with all scopes

```bash
gws auth login -s "gmail,tasks,calendar"
```

> **Quote the scope list.** In PowerShell, commas are array separators — unquoted
> `-s gmail,tasks,calendar` is split into separate args and scopes are silently dropped.

Approve in the browser. If you see "Google hasn't verified this app" → **Advanced** →
**continue** (safe for personal use — you are the developer).

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

### Or the one-command interface (`gws-do`)

`gws-do` describes → routes → delegates, so you don't have to remember agent names:

```bash
export PATH="$PWD/bin:$PATH"        # so `gws-do` is on your path (add to your shell rc)
gws-do --status                     # readiness check
gws-do --list                       # everything it can do
gws-do "triage my inbox and label everything"
gws-do "turn my action-required mail into tasks and calendar events"
gws-do "give me my weekly digest"
```

On Windows, run it via `bin/gws-do.cmd`.

## 5. (Optional) Nightly auto-labeler

A deterministic labeler runs nightly and tags new inbox mail by sender→label rules.
No LLM needed. Edit the example rules in `scripts/nightly-label.sh` to match your mail.

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

### macOS / Linux

```bash
# Or just run manually:
bash scripts/nightly-label.sh
```

### GitHub Actions (cloud — PC can be off)

See [`GITHUB-ACTIONS.md`](GITHUB-ACTIONS.md). Requires a `GWS_CREDENTIALS` repo secret
and a **private** repo.

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
| "Access blocked" / 403 at login | Add your address as a **Test user** on the consent screen. |
| Too many scopes error | Log in with `-s gmail` (don't use the full preset). |
| `accessNotConfigured` 403 | Enable the Gmail/Calendar/Tasks API for the project. |
| Hook error about `python` | Ensure `python3` (macOS/Linux) or `python` (Windows) is on PATH; edit `.claude/settings.json` hook command accordingly. |
| `jq: command not found` | Install `jq` — agents pipe JSON through it. |
| `403 insufficientPermissions` after adding scopes | Stale access token cached. Delete `~/.config/gws/token_cache.json` and retry. |
| `Using keyring backend: keyring` breaks jq | Pipe through `sed '/^Using keyring backend:/d'` before `jq`. |
