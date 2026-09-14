# GWS for Dummies — static site

This folder is the static site served at **https://gws-for-dummies.vercel.app**. It has no
framework and no build step: Vercel serves the files exactly as they are.

- `index.html` — the one-page manual (semantic HTML).
- `styles.css` — the paper design system (no framework, no external fonts).
- `flow.css` + `flow.js` — the AgenticFlowFigure (the page's one signature animation).
- `site.js` — progressive enhancement only (copy feedback, active nav, reveal, progress).
- `assets/avatar.jpg` — the contact portrait (local, optimized).
- `llms.txt` — the agent-readable setup runbook (the key file at `/llms.txt`).
- `vercel.json` — deployment config; sets `Content-Type: text/plain; charset=utf-8`
  and a `Cache-Control` for `/llms.txt`.

> **On imagery:** the design brief prefers real product screenshots and up to two
> licensed editorial photos. None were available under a clear license, so the page uses
> an honest **rendered terminal** (CSS) for product proof and one **original inline SVG**
> illustration for pacing — no hotlinked or unlicensed assets. Drop real screenshots into
> `assets/` later and swap them in if you want.

**No build command and no output directory are needed.** If Vercel asks, leave the
build command empty and set the output directory to `.` (or just leave it unset).

## Deploy

### Primary: Vercel Git integration

Import the repo in Vercel and set **Root Directory = `site`**; then every push
redeploys automatically and PRs get preview URLs. (Vercel → Project → Settings → Git.)

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

## Custom domain (optional)

The site is served for free at **https://gws-for-dummies.vercel.app** — nothing else is
required. To use a domain **you own** instead:

1. In Vercel → Project → **Settings → Domains**, add the domain (apex and/or `www`).
2. Create the DNS records Vercel shows at your registrar:
   - Apex: an **A** record to Vercel's IP (e.g. `76.76.21.21`), or an **ALIAS/ANAME**
     to `cname.vercel-dns.com`.
   - `www`: a **CNAME** to `cname.vercel-dns.com`.
   - (Or point the domain's nameservers at `ns1.vercel-dns.com` / `ns2.vercel-dns.com`.)
3. Propagation is minutes to 48h; Vercel then issues TLS automatically.

Confirm the runbook resolves (substitute your domain):

```bash
curl -I https://gws-for-dummies.vercel.app/llms.txt
# expect: content-type: text/plain; charset=utf-8
```
