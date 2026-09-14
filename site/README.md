# GWS for Dummies — static site

This folder is the static site served at **https://gwsfordummies.to**. It has no
framework and no build step: Vercel serves the files exactly as they are.

- `index.html` — the landing page (self-contained; inline CSS/JS).
- `llms.txt` — the agent-readable setup runbook (the key file at `/llms.txt`).
- `vercel.json` — deployment config; sets `Content-Type: text/plain; charset=utf-8`
  and a `Cache-Control` for `/llms.txt`.

**No build command and no output directory are needed.** If Vercel asks, leave the
build command empty and set the output directory to `.` (or just leave it unset).

## Deploy

### Primary: Vercel Git integration

Import the repo in Vercel and set **Root Directory = `site`**; then every push
redeploys automatically and PRs get preview URLs. (Vercel → Project → Settings → Git.)

### Fallback: GitHub Action

`.github/workflows/deploy-site.yml` deploys `site/` to production on push (and via
manual dispatch). It needs **one secret**:

1. Create a Vercel token at https://vercel.com/account/tokens.
2. Add it to the repo as `VERCEL_TOKEN` (Settings → Secrets and variables → Actions).

The Vercel org/project IDs are already hard-coded in the workflow (they are not secret).

### Option A — Vercel CLI, from inside this folder

```bash
cd site
vercel            # first run: link/create the project
vercel --prod     # promote to production
```

### Option B — import the repo

1. In Vercel, **Add New → Project** and import the Git repository.
2. Set **Root Directory = `site`**.
3. Framework Preset: **Other**. Leave Build Command and Output Directory empty.
4. Deploy. Every push to the default branch redeploys; PRs get preview URLs.

## Custom domain: gwsfordummies.to

1. Open the project in Vercel → **Settings → Domains**.
2. Add `gwsfordummies.to` (and `www.gwsfordummies.to` if you want the `www` variant).
3. Vercel shows the DNS records to create at your registrar:
   - Apex (`gwsfordummies.to`): an **A** record to Vercel's IP (or an **ALIAS/ANAME**
     to `cname.vercel-dns.com` if your registrar supports it).
   - Subdomain (`www`): a **CNAME** to `cname.vercel-dns.com`.
4. Add those records at your DNS provider. Propagation is usually minutes but can
   take up to 48 hours.
5. Once verified, Vercel issues the TLS certificate automatically.

After the domain is live, confirm the key file resolves correctly:

```bash
curl -I https://gwsfordummies.to/llms.txt
# expect: content-type: text/plain; charset=utf-8
```
