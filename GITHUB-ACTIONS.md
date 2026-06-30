# Run the nightly labeler in the cloud (PC can be off)

This runs `scripts/nightly-label.sh` on GitHub's servers every night, so labeling
happens even when your computer is powered off. Workflow: `.github/workflows/nightly-gmail-label.yml`.

> **Cost:** free (GitHub Actions free tier easily covers one short nightly run).

---

## ⚠️ Two hard prerequisites — read first

1. **Publish your OAuth app to Production.** In testing mode, Google **expires the
   refresh token after 7 days**, which would break the cloud job (and your local task)
   weekly. Fix it once:
   - Open https://console.cloud.google.com/auth/overview?project=<YOUR_PROJECT_ID>
   - **Audience → Publish app → Confirm** (status becomes *In production*). The
     "unverified app" notice stays — that's fine for personal use; it just stops the
     7-day token expiry.

2. **Use a PRIVATE GitHub repo.** The credential you'll store grants read/modify access
   to your mailbox. Never put it in a public repo. `.gitignore` already blocks
   `credentials*.json` so the raw file can't be committed by accident — the secret goes
   in GitHub's encrypted **Secrets**, not the repo files.

---

## Steps

### 1. Put this project in a private GitHub repo
```powershell
cd D:\googlecli
git init
git add .
git commit -m "Gmail automation project"
gh repo create gmail-automation --private --source=. --push
# (or create a private repo in the GitHub UI and: git remote add origin <url>; git push -u origin main)
```

### 2. Export your gws credentials (this is the secret value)
```powershell
gws auth export --unmasked
```
Copy the **entire JSON output**. It contains your refresh token — treat it like a password.

### 3. Save it as a repo secret named `GWS_CREDENTIALS`
- GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
- **Name:** `GWS_CREDENTIALS` · **Value:** paste the JSON from step 2 → **Add secret**

*(Do this yourself in the browser — never paste the token into chat or a file.)*

### 4. Test it
- Repo → **Actions** tab → **nightly-gmail-label** → **Run workflow** (the
  `workflow_dispatch` trigger). Watch the log — the "Run the labeler" step should print
  `Finance: +N`, etc. If it errors with an auth/scope message, re-check steps 1–3.

### 5. Done
It now runs automatically at **~02:00 America/Chicago** nightly (the `cron` line; UTC, so
it shifts 1h at daylight-saving — edit the cron if you care). The 2-day window means a
delayed or skipped run is harmless.

---

## Keeping local + cloud in sync
The workflow runs the **same** `scripts/nightly-label.sh` as your Windows task, so any
sender→label rule you add there is picked up by both — just commit & push the change.
Pick **one** to avoid double work: either keep the local Task Scheduler job *or* the
cloud workflow (both labeling is harmless/idempotent, but redundant). To retire the local
one: `Unregister-ScheduledTask -TaskName gws-nightly-label -Confirm:$false`.

## Caveats
- GitHub disables scheduled workflows after **60 days of repo inactivity** — a push or a
  manual run resets that.
- If you ever re-auth gws (new scopes, token reset), re-export and update the
  `GWS_CREDENTIALS` secret.
- Rotating/revoking access: delete the secret, and/or revoke the app at
  https://myaccount.google.com/permissions.
