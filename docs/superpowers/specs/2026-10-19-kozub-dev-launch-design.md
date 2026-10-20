# Design — kozub.dev launch

Date: 2026-10-19
Owner: Pavlo Kozub

## Intent

Pavlo owns `kozub.dev` (registered at GoDaddy, DNS currently parked — host does not resolve). A nearly-ready landing page already exists on disk at `~/projects/persononomo/assistant/kozub-dev/index.html`. The goal of this project is to publish that page as the actual https://kozub.dev/, with a visible link to his umbrella brand inakshe.com (and reserved room for future projects: `kidflow`, `quiet-cove`). The site should read as **senior engineer first, personal brand alongside**, with no "open to work" signals — Pavlo is still in industry but running a quiet side-search.

## Why now

- inakshe.com is public and growing. People curious about "who made this?" currently have no backref.
- Pavlo is in a quiet job search. Recruiters coming from LinkedIn need a credible, sober one-pager landing.
- kozub.dev was bought and sitting idle. The landing page was built in May 2026 and never deployed.
- The current folder lives inside `~/projects/persononomo/assistant/<project>/`, which the Pavlo-wide convention reserves for *operational artifacts of the assistant*. kozub.dev is a *public standalone project* and belongs alongside `inakshe/`, `kidflow/`, `quiet-cove/` under `~/projects/persononomo/`.

## Goals

1. Live, HTTPS-served site at `https://kozub.dev/` (apex) and `https://www.kozub.dev/` (redirect to apex)
2. Visible outbound link to `inakshe.com` in a dedicated section titled `ALSO BUILDING`, placed between the existing highlights block and the contact row, with structural room for `kidflow` and `quiet-cove` when they mature
3. A `WORKED AT` logo strip reinforcing engineering credibility, placed between the `about` text and the `highlights` list, containing 6 logos: PrivatBank, Perfsys, Oversecured, Infosys, KeyUA, Phoenix365. Default rendering monochrome in the site ink color; hover reveals the original brand colors.
4. Project moved to `~/projects/persononomo/kozub-dev/` as its own git repo
5. Published to GitHub as `persononomo/kozub-dev` (public), connected to Cloudflare Pages
6. Domain managed by Cloudflare (DNS at a minimum; registrar transfer from GoDaddy preferred, nameserver change acceptable as interim)
7. Push to `main` → Cloudflare Pages → live, with no manual deploy step
8. `contact@kozub.dev` works (forwards to `pavlo.kozub@gmail.com`)

## Non-goals

- Multi-page site, CMS, blog, analytics — single `index.html` stays single
- Interactive UI beyond the existing light/dark toggle
- Any "hire me" / "open to work" / public rates / Calendly / availability signals
- Visual/typographic overhaul — existing cream/terracotta palette, Fraunces/Newsreader/JetBrains Mono stack stays
- GitHub profile-level cleanup — tracked as a separate task, does not block launch
- A real work mailbox beyond simple forwarding (no Google Workspace, no "reply from domain")
- Any kind of build step — no bundler, no framework, no npm

## Anti-goals (would be failure even if it technically works)

- Page reads as "startup founder, hire my OÜ" instead of "senior engineer with a brand on the side"
- Any public rate card, availability flag, or `hireable` signal
- Private areas of life (family, migration, health, children's diagnoses) leak onto the page
- Logo strip reads as loud/corporate — must stay quiet by default (monochrome, hover-only color reveal), fit the typographic mood of the page
- Whois leaks real residential address or phone (privacy must be on at Cloudflare, same as current GoDaddy state — verify)

## Constraints

- Must not disrupt `inakshe.com` DNS; only `kozub.dev` records change
- Email `contact@kozub.dev` must forward reliably — this is the recruiter touchpoint; a bounce would be worse than not advertising it
- Single self-contained HTML file — no build step, no bundler
- `cv.pdf` is a *generated artifact* with source in `~/projects/persononomo/assistant/devops-side-job/variants/`. The move must not break that regeneration workflow — keep the copy-in step documented in `CLAUDE.md`.

## Decisions (locked)

### Content & layout

Final section order:

```
hero  →  about  →  WORKED AT  →  highlights (01-03)  →  ALSO BUILDING  →  contact row  →  footer
```

**About text — unmask current employer.** Current line reads *"Currently on the platform team at a global iGaming product running multi-region Kubernetes..."* — rewritten to name **Phoenix365** by name: *"Currently on the platform team at **Phoenix365** — multi-region Kubernetes, 5 EKS clusters, 5 AWS accounts, 400+ microservices."* Conscious tradeoff: the logo strip surfaces Phoenix365 anyway, so matching the About text keeps the page honest.

**New section — `WORKED AT`** inserted between `.about` and `.highlights`:

- Section label: JetBrains Mono, uppercase, `0.18em` letter-spacing, terracotta — same `KRAKOW`-style treatment
- Strip: 6 logos horizontally, flex-wrap on mobile, consistent height (≈28px desktop, ≈22px mobile), equal visual weight
- Default state: monochrome in `var(--ink-soft)` via SVG `currentColor` (or `filter: grayscale(1) opacity(0.66)` for raster fallbacks)
- Hover state: original brand colors + full opacity + subtle `transform: translateY(-1px)`, 240ms transition; `prefers-reduced-motion` disables the transform
- Each logo is an `<a>` to the company's public site, `target="_blank" rel="noopener noreferrer"`, with `aria-label` and a visually-hidden company name
- Order (current → oldest, left-to-right): **Phoenix365 · Oversecured · Infosys · KeyUA · Perfsys · PrivatBank**. Builder may re-order during execution if a specific sequence reads better.
- Logo acquisition: builder sources SVGs from each company's brand kit / Wikipedia / official site. For companies without a published SVG (likely KeyUA, possibly Perfsys), builder either traces at low complexity from a public PNG or asks Pavlo for a clean source. All logos stay inline as SVG in `index.html` (single-file principle).

**New section — `ALSO BUILDING`** inserted between `.highlights` and `.contact`:

- Section label: same `KRAKOW`-style treatment
- Row: `grid-template-columns: auto 1fr`, link in terracotta on the left, italic descriptor on the right
- Structural room for 2–3 more rows (kidflow, quiet-cove) without re-layout
- One row shipped: `inakshe ↗ A catalog of specialists who work well with neurodivergent people.`

Everything else on the page (hero, highlights 01-03, contact row, footer, light/dark toggle, animation timing, Google Fonts) is unchanged.

### Where it lives

- Move `~/projects/persononomo/assistant/kozub-dev/` → `~/projects/persononomo/kozub-dev/`
- Items moved: `CLAUDE.md`, `index.html`, `cv.pdf`, `docs/` (this document)
- `.superpowers/` directory from the brainstorming session is excluded (gitignored, not needed in the public repo)
- `~/projects/persononomo/assistant/CLAUDE.md` is updated: `kozub-dev/` row removed from the "Активные роли" table, replaced by a one-line pointer under "Стандалоны"

### Git & GitHub

- Initialize git in the new location
- Create `persononomo/kozub-dev` on GitHub — **public** (see builder calls)
- First commit = the moved files; subsequent commit adds the `ALSO BUILDING` section
- `main` branch, no PRs needed — direct commits are fine for a single-maintainer static site
- `.gitignore` covers `.superpowers/`, `.DS_Store`, standard editor junk

### Hosting

- Cloudflare Pages, git-connected to `persononomo/kozub-dev`
- No build command, no output directory override — serve the repo root
- Both `kozub.dev` and `www.kozub.dev` bound; `www` redirects to apex via a Cloudflare Page Rule or Redirect Rule
- **Same Cloudflare account as `inakshe.com`** — `pavlo.kozub@gmail.com` is already a verified Email Routing destination on that account, so no destination re-verification needed when `kozub.dev` is added to the zone list

### DNS & registrar

- Primary path: **full registrar transfer** GoDaddy → Cloudflare Registrar (cheaper, cleaner, no renewal markup)
- Pre-flight check: domain is unlocked at GoDaddy, auth code retrievable, outside the 60-day post-registration/post-transfer window
- If the 60-day window or any lock blocks it: **nameserver change only** — point GoDaddy at Cloudflare's nameservers, do the full registrar transfer at next renewal
- DNS records (post-cutover):
  - Apex `kozub.dev` → Cloudflare Pages (via CNAME flattening, proxied)
  - `www.kozub.dev` → Cloudflare Pages, proxied
  - MX records → Cloudflare Email Routing
  - SPF (`v=spf1 include:_spf.mx.cloudflare.net ~all`)
  - DKIM / Email Routing automatic records
  - DMARC (`v=DMARC1; p=none; rua=mailto:pavlo.kozub@gmail.com`) at `p=none` first; raise to `quarantine` after a week of clean reports
- TLS: Full (strict), minimum TLS 1.2, HSTS on with 6-month max-age at launch, bump to 12 months after 2 weeks clean

### Email

- Cloudflare Email Routing enabled on the zone
- Destination: `pavlo.kozub@gmail.com` — already verified on this Cloudflare account (used by `inakshe.com`), so no new confirmation email needed
- Route: `contact@kozub.dev` → gmail
- Catch-all: initially **off** (reduce spam surface); enable only if `contact@` traffic looks sparse
- **No cutover-sequence risk.** `contact@kozub.dev` is not currently live anywhere (GoDaddy has no forwarding set up, address is not advertised publicly). Email Routing can be stood up any time around DNS cutover without a "mail-bouncing" window.

### CV

- `cv.pdf` stays in the repo root at `/cv.pdf`, served directly by Pages
- Regeneration workflow (copy from `devops-side-job/variants/`) is preserved and documented in the new `CLAUDE.md`

## Builder calls (settled by me unless flagged)

- **Repo visibility: public.** The site itself is public, so a public repo containing a public page is consistent, and it shows acceptably on the GitHub profile once the profile cleanup lands. Private would also work but would force Cloudflare Pages to use the GitHub App integration with repo-read grants — more permission surface for no gain.
- **`rel="me"`** added to the inakshe link and both LinkedIn/GitHub links in the contact row — standard identity hint, zero visual cost
- **Keep `mailto:contact@kozub.dev` as-is** — once Email Routing is live, the link works. No change needed.
- **No analytics, no third-party scripts.** Cloudflare Pages gives free aggregate request counts via its dashboard; that's enough.
- **`robots.txt`: allow all.** `sitemap.xml`: not generated — overkill for a single-page site.
- **Font loading:** keep the existing Google Fonts link with `preconnect`. Self-hosting the fonts is nicer but not worth the effort for a single page right now.
- **No `.well-known/security.txt`, no `humans.txt`.** Both are optional and empty of content for a single-maintainer landing.
- **Launch idempotency:** execution plan must be re-runnable — each step checks state before acting so a partial run (e.g. domain already in Cloudflare but Pages not yet connected) resumes cleanly.

## Open — needs Pavlo

Nothing. All open items from the first draft were resolved during the brainstorm:

- inakshe descriptor → *"A catalog of specialists who work well with neurodivergent people."*
- Cloudflare account → same account as `inakshe.com`
- `contact@kozub.dev` → not yet live anywhere → free cutover sequencing
- Logo strip composition → PrivatBank · Perfsys · Oversecured · Infosys · KeyUA · Phoenix365 (6 total, hover-reveal)
- Current employer (Phoenix365) → named explicitly in About + featured on `WORKED AT` strip

## What the plan has to cover

1. Pre-flight on the domain at GoDaddy: unlocked? auth code retrievable? outside 60-day window? current DNS snapshot taken?
2. Move folder `assistant/kozub-dev/` → `~/projects/persononomo/kozub-dev/`, carrying `CLAUDE.md`, `index.html`, `cv.pdf`, `docs/`; drop `.superpowers/`
3. `git init`, add `.gitignore` (`.superpowers/`, `.DS_Store`, editor junk), first commit of the moved tree
4. Logo acquisition: 6 SVGs (Phoenix365, Oversecured, Infosys, KeyUA, Perfsys, PrivatBank). Builder sources from brand kits / Wikipedia; traces at low complexity if no SVG exists; asks Pavlo if a company's clean source isn't findable.
5. HTML edit: rewrite About line to name Phoenix365; add `WORKED AT` section with 6 inline SVG logos + hover-reveal CSS; add `ALSO BUILDING` section with the inakshe row; verify in light + dark + mobile 375px (manual browser pass, including hover check on desktop)
6. Create `persononomo/kozub-dev` on GitHub (public), push `main`
7. Add zone `kozub.dev` to Cloudflare (same account as inakshe.com), let it discover existing DNS, verify snapshot matches
8. Switch nameservers at GoDaddy (interim) OR start full registrar transfer (preferred)
9. Create Pages project, connect to GitHub repo, deploy
10. Bind apex + www custom domains on Pages, verify HTTPS
11. Enable Cloudflare Email Routing, add `contact@kozub.dev` → gmail (no new verification needed), confirm delivery (send test from an external address)
12. Add SPF + DMARC records
13. Validation pass: `curl -I https://kozub.dev/`, `curl -I https://www.kozub.dev/`, mail-tester score for the forward, lighthouse / mobile 375px / dark mode sanity
14. Update `~/projects/persononomo/kozub-dev/CLAUDE.md` with new location, deploy mechanism, email flow, DNS owner
15. Update `~/projects/persononomo/assistant/CLAUDE.md` to remove the kozub-dev entry
16. Daily-log the launch in `~/knowledge/daily/YYYY-MM-DD.md` for the execution day
