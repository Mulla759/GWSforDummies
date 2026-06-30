# gws Command Guide

A practical cheat-sheet of the `gws` (Google Workspace CLI) commands useful in this
project. Every action against your Google account is one of these. Use it to ask Claude
("label these as Work", "what's on my calendar tomorrow") or to run commands yourself.

> **Account:** all commands act on the authenticated account, `you@example.com`,
> addressed as `"userId": "me"`. You never type the email — it comes from `gws` auth.

---

## 0. How every command is shaped

```
gws <service> <resource> <method> --params '<JSON>' [--json '<JSON>'] [flags]
gws <service> +<helper> [--flag value]              # hand-written helper, prefixed with +
```

- **`--params`** = URL/path/query fields (ids, `userId`, `q`, `maxResults`, `range`).
- **`--json`** = the request *body* (a new label, event, task, message).
- Output is **always JSON** → pipe through `jq` to trim: `... | jq '.labels[].name'`.

### Universal helpers (work on any command)

| Flag / command | What it does |
|---|---|
| `gws <service> --help` | List every resource, method, and `+helper` for a service |
| `gws schema <method>` | Show a method's exact request/response schema, e.g. `gws schema gmail.users.messages.list` |
| `--dry-run` | Validate + show the request **without sending it** (use before any write) |
| `--format table\|yaml\|csv` | Change output format (default `json`) |
| `--page-all` / `--page-limit N` | Auto-paginate, one JSON line per page |

### Exit codes
`0` ok · `1` API error · `2` auth error · `3` bad arguments · `4` discovery error · `5` internal.

---

## 1. Windows / PowerShell gotchas (learned the hard way here)

1. **JSON quoting** — PowerShell mangles `--params '{"userId":"me"}'`. Run `gws` JSON
   commands through the **Bash tool / Git Bash**, where single-quoted JSON works cleanly.
   In PowerShell you must escape inner quotes, which is error-prone.
2. **Commas are array separators in PowerShell.** `gws auth login -s gmail,tasks,calendar`
   gets split into separate args and silently drops scopes. **Quote it:**
   `gws auth login -s "gmail,tasks,calendar"`.
3. `gws` prints results to stdout and a harmless `node.exe : ...` wrapper line to stderr in
   PowerShell — ignore the wrapper; the JSON is the result.
4. **Added a scope but still getting `403 insufficientPermissions`?** A stale access token
   is cached. Delete `~/.config/gws/token_cache.json` (Windows:
   `C:\Users\adelina\.config\gws\token_cache.json`) and retry — `gws` re-mints a fresh
   token from `credentials.enc`, which already holds the new scopes.

---

## 2. Auth

```bash
gws auth status                       # who am I, which scopes, where creds live
gws auth login -s "gmail"             # log in with just Gmail scope
gws auth login -s "gmail,tasks,calendar"   # Gmail + Tasks + Calendar (Phase 2)
gws auth logout                       # clear saved credentials
```
Testing-mode apps cap at ~25 scopes — always request only the services you need.

---

## 3. Gmail

### Read (safe, used constantly)
```bash
# List messages by Gmail search query
gws gmail users messages list --params '{"userId":"me","q":"in:inbox is:unread","maxResults":10}'

# Get one message (metadata only = cheap)
gws gmail users messages get --params '{"userId":"me","id":"<ID>","format":"metadata","metadataHeaders":["From","Subject","Date"]}'

# Decoded, readable body (base64 + HTML handled for you)
gws gmail +read --id <ID>
gws gmail +read --id <ID> --headers          # body prefixed with From/To/Subject/Date
gws gmail +read --id <ID> --html | grep -oE 'href="[^"]+"'   # just the links

# Unread inbox summary (sender / subject / date)
gws gmail +triage

# Threads
gws gmail users threads list --params '{"userId":"me","q":"in:inbox","maxResults":10}'
gws gmail users threads get  --params '{"userId":"me","id":"<THREAD_ID>"}'
```

### Labels (reversible writes — what triage uses)
```bash
gws gmail users labels list   --params '{"userId":"me"}'
gws gmail users labels create --params '{"userId":"me"}' --json '{"name":"triage/action-required","color":{"backgroundColor":"#ffad47","textColor":"#000000"}}'
gws gmail users labels patch  --params '{"userId":"me","id":"<LABEL_ID>"}' --json '{"color":{"backgroundColor":"#fb4c2f","textColor":"#ffffff"}}'

# Apply / remove labels on a message
gws gmail users messages modify --params '{"userId":"me","id":"<ID>"}' --json '{"addLabelIds":["<LABEL_ID>"],"removeLabelIds":[]}'
gws gmail users threads modify  --params '{"userId":"me","id":"<THREAD_ID>"}' --json '{"addLabelIds":["<LABEL_ID>"]}'
```

### Filters (standing rules — what the filter-curator makes)
```bash
gws gmail users settings filters list   --params '{"userId":"me"}'
gws gmail users settings filters create --params '{"userId":"me"}' --json '{"criteria":{"from":"news@example.com"},"action":{"addLabelIds":["<LABEL_ID>"]}}'
```

### Compose helpers — ⚠️ blocked in this project by design
These exist in `gws` but are **denied** by this project's safety rails (see §8). Listed so
you know they're available if you ever deliberately enable them (Phase 3 will add
**drafts only**):
```bash
gws gmail +send      --to a@b.com --subject "Hi" --body "..."   # DENIED here
gws gmail +reply     --message-id <ID> --body "..."            # DENIED here
gws gmail +reply-all --message-id <ID> --body "..."            # DENIED here
gws gmail +forward   --message-id <ID> --to a@b.com            # DENIED here
gws gmail +watch                                               # stream new mail as NDJSON
```

---

## 4. Calendar  *(needs the `calendar` scope — Phase 2)*

```bash
# Read
gws calendar +agenda                                  # upcoming events, your timezone
gws calendar +agenda --today --timezone America/New_York
gws calendar calendarList list                        # your calendars
gws calendar events list --params '{"calendarId":"primary","maxResults":10,"singleEvents":true,"orderBy":"startTime","timeMin":"2026-06-20T00:00:00Z"}'
gws calendar events get  --params '{"calendarId":"primary","eventId":"<ID>"}'

# Create (reversible — what email-calendar-creator does)
gws calendar events insert --params '{"calendarId":"primary"}' \
  --json '{"summary":"Dentist","start":{"dateTime":"2026-06-25T15:00:00-05:00"},"end":{"dateTime":"2026-06-25T15:30:00-05:00"}}' --dry-run
gws calendar events quickAdd --params '{"calendarId":"primary","text":"Lunch with Sam Friday 1pm"}'
gws calendar +insert --summary "Standup" --start "2026-06-21T09:00:00" --end "2026-06-21T09:15:00"
```

---

## 5. Tasks  *(needs the `tasks` scope — Phase 2)*

```bash
# Read
gws tasks tasklists list                              # your task lists
gws tasks tasks list --params '{"tasklist":"@default","showCompleted":false}'
gws tasks tasks get  --params '{"tasklist":"@default","task":"<TASK_ID>"}'

# Create (reversible — what email-task-creator does)
gws tasks tasks insert --params '{"tasklist":"@default"}' \
  --json '{"title":"Reply to landlord","notes":"From: <email link>","due":"2026-06-23T00:00:00.000Z"}' --dry-run

# Convert a Gmail message straight into a task (subject -> title, snippet -> notes)
gws workflow +email-to-task --message-id <ID>
gws workflow +email-to-task --message-id <ID> --tasklist <LIST_ID>
```

---

## 6. Drive

```bash
gws drive files list --params '{"pageSize":10,"q":"name contains '\''report'\''"}'
gws drive files list --params '{"pageSize":100}' --page-all | jq -r '.files[].name'
gws drive files get  --params '{"fileId":"<ID>"}'
gws drive +upload ./report.pdf --name "Q1 Report"
```

---

## 7. Sheets / Docs / Workflows (handy extras)

```bash
# Sheets — always single-quote ranges (the ! triggers bash history expansion)
gws sheets +read   --spreadsheet <ID> --range 'Sheet1!A1:C10'
gws sheets +append --spreadsheet <ID> --values "Alice,95"

# Docs
gws docs +write --document <ID> --text "Appended line."

# Cross-service workflows
gws workflow +standup-report     # today's meetings + open tasks
gws workflow +meeting-prep       # next meeting: agenda, attendees, linked docs
gws workflow +weekly-digest      # this week's meetings + unread count
```

---

## 8. This project's safety map

`gws` can do far more than this project allows. Two rails enforce least privilege:
`.claude/settings.json` (outer) and `.claude/hooks/bash-guard.py` (per-agent, inner).

| Category | Status here |
|---|---|
| Read mail, labels, threads, filters, calendar, tasks, drive | ✅ allowed |
| Create/modify **labels** | ✅ allowed (reversible) |
| Create standing **filters** | ⏸️ **asks first** — prompts for confirmation before creating (even in a loop) |
| Create **tasks**, **calendar events** | ✅ allowed, **after you confirm** (reversible) |
| **Send / reply / forward** email | ⛔ denied — both the raw API (`gws gmail users messages send`) and the helpers (`gws gmail +send` / `+reply` / `+reply-all` / `+forward`). Phase 3 will add **drafts only** |
| **Trash / delete** anything (mail, tasks, events, labels) | ⛔ denied (`gws * trash`, `gws * delete`) |

### Launch the project's agents
```bash
claude --agent email-triage-orchestrator   # Phase 1: triage + label the inbox
claude --agent email-action-orchestrator    # Phase 2: turn action-required mail into tasks/events
```

> Tip: you don't have to memorize JSON. Tell Claude what you want in plain English
> ("label everything from Jobright as Job Alerts", "add a task to reply to the landlord by
> Friday") and it builds the right `gws` command — within the rails above.
