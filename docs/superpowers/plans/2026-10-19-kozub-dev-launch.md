# kozub.dev Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `kozub.dev` as a live single-page site with a `WORKED AT` logo strip, an `ALSO BUILDING` row linking to inakshe.com, served from Cloudflare Pages via a GitHub repo at `persononomo/kozub-dev`, with `contact@kozub.dev` forwarding to gmail.

**Architecture:** Static single-file HTML served by Cloudflare Pages, git-connected to a public GitHub repo. DNS and email on Cloudflare in the same account as `inakshe.com`. Deploy = `git push origin main`. No build step, no framework, no bundler.

**Tech Stack:** HTML/CSS inline (`index.html`), inline SVG logos, Google Fonts (Fraunces / Newsreader / JetBrains Mono), git, GitHub, Cloudflare (Pages / DNS / Email Routing / Registrar).

**Spec:** `~/projects/persononomo/assistant/kozub-dev/docs/superpowers/specs/2026-10-19-kozub-dev-launch-design.md`

## Global Constraints

- Must not touch `inakshe.com` DNS records; only `kozub.dev` zone is modified.
- Single self-contained `index.html` — no build step, no bundler, no `npm`.
- Light + dark theme (CSS vars already in place) + mobile ≤640px breakpoint already defined; new additions must honor both.
- All logos inline as SVG inside `index.html` (no external image hosting).
- Hover animations respect `@media (prefers-reduced-motion: reduce)`.
- Whois privacy must stay on at Cloudflare (verify after any registrar/NS action).
- Content copy locked verbatim from the spec:
  - inakshe row: `A catalog of specialists who work well with neurodivergent people.`
  - About line names **Phoenix365** by name (not "a global iGaming product").
  - Logo order (left → right): **Phoenix365 · Oversecured · Infosys · KeyUA · Perfsys · PrivatBank**.
- `cv.pdf` served at `/cv.pdf`; regeneration workflow (from `assistant/devops-side-job/variants/`) preserved in `CLAUDE.md`.
- All risky external actions (GoDaddy writes, Cloudflare registrar transfer, DNS cutover) must be user-confirmed before executing — the plan runs the read-only pre-flight checks itself, then stops for Pavlo's go on writes.

## Review Focus

Five likely-to-bite failure modes the spec implies but no single task is naturally responsible for testing. For each, this plan assigns a verification step to the owning task.

1. **DNS cutover with no live site behind it.** If GoDaddy nameservers flip to Cloudflare before Pages has the custom domain bound, `https://kozub.dev/` serves a Cloudflare error / `522` / holding page for hours. Expected: visitors see the finished site, not a broken intermediate state. → Verification pinned in **Task 8** (bind Pages custom domain *before* Task 7 switches nameservers, re-verified at Task 10).
2. **Mailto in HTML before Email Routing exists.** The deployed page advertises `contact@kozub.dev` from day 1. If Email Routing isn't live when the first click happens, mail bounces at a recruiter touchpoint. Expected: by the moment NS is on Cloudflare, the `contact@` route is already in place. → Verification pinned in **Task 9** (route configured + end-to-end delivery test *before* Task 7 completes its DNS switchover).
3. **Inakshe DNS accidentally edited.** Working inside the same Cloudflare account means a wrong-zone click can wipe a live record on `inakshe.com`. Expected: inakshe records identical before/after. → Verification pinned in **Task 6** (snapshot inakshe zone before touching kozub, diff after).
4. **Reduced-motion users get a bouncing logo on hover.** `prefers-reduced-motion: reduce` must disable the translateY but keep the color reveal. Expected: no vertical motion, color still appears. → Verification pinned in **Task 4** (test with devtools emulation).
5. **Whois leaks real address on transfer / NS change.** GoDaddy currently has privacy-protect; Cloudflare must be set to redacted from the first moment the zone is active. Expected: public WHOIS shows Cloudflare's redacted contact. → Verification pinned in **Task 7**.

---

## Task 1: GoDaddy pre-flight — DNS snapshot & transfer eligibility

**Goal:** Produce a read-only report that tells the human (and later tasks) which cutover path to take and what records must survive.

**Files:**
- Create: `~/projects/persononomo/assistant/kozub-dev/docs/preflight-godaddy-report.md`

**Interfaces:**
- Consumes: nothing (pre-flight)
- Produces: a report file naming (a) current DNS records on the zone at GoDaddy, (b) domain-lock status and 60-day-window status, (c) auth/EPP code if retrievable, (d) existing email forwarding at GoDaddy if any, (e) chosen cutover path: `transfer` or `ns-change`. Later tasks read this file.

- [ ] **Step 1: Pavlo logs into GoDaddy and copies these fields into the report file**

Prompt the user (in chat) to supply, from GoDaddy's domain management for `kozub.dev`:
- Full DNS record list (type / name / value / TTL) — paste as a code block
- Lock status (`Locked` / `Unlocked`)
- Registration date and last transfer-in date (to compute 60-day window; today = 2026-10-19)
- Email forwarding section: list of forwards, or "none"
- WHOIS privacy status (`On` / `Off`)
- Does GoDaddy offer the auth/EPP code? If yes, paste it (treat as secret — place in the report under a `## auth-code (DO NOT COMMIT)` section)

Pavlo may answer "nothing set up / parked" — accept that as a valid snapshot (confirms the "parked" assumption in the spec).

- [ ] **Step 2: Write the report file**

Fill the following template:

```markdown
# GoDaddy pre-flight report — kozub.dev

Captured: 2026-10-19

## DNS records at GoDaddy
<paste>

## Domain state
- Lock: <Locked | Unlocked>
- Last registration/transfer-in date: <date>
- 60-day window ends: <date>
- Today (2026-10-19) outside window: <yes | no>
- Auth code retrievable now: <yes | no>

## Email forwarding at GoDaddy
<none | list>

## WHOIS privacy
<on | off>

## Chosen cutover path
<transfer | ns-change>

Reason: <one line>

## auth-code (DO NOT COMMIT)
<code or "not yet retrieved">
```

Decision rule for the cutover path:
- `transfer` if Lock=Unlocked AND 60-day window ended AND auth code retrievable AND Pavlo willing to pay the renewal fee at Cloudflare.
- `ns-change` otherwise.

- [ ] **Step 3: Verify report completeness**

Open the report. Confirm every field has a value (not `TBD`). Confirm `## auth-code` section is below the "chosen path" line.

Expected: file exists, is complete, declares one of `transfer` / `ns-change`.

- [ ] **Step 4: Add `preflight-godaddy-report.md` to the local `.gitignore` list**

Since it may contain the auth code, it stays out of git. Add the exact filename to a running note for Task 2 (which writes the real `.gitignore`).

No commit this task — the report lives inside the folder we're about to move, but will be `.gitignore`d in Task 2.

---

## Task 2: Local project migration

**Goal:** Move the folder out of `assistant/`, initialize git, make the first commit of the current (pre-logo, pre-section) state, update the parent assistant CLAUDE.md.

**Files:**
- Move: `~/projects/persononomo/assistant/kozub-dev/` → `~/projects/persononomo/kozub-dev/`
- Create: `~/projects/persononomo/kozub-dev/.gitignore`
- Modify: `~/projects/persononomo/assistant/CLAUDE.md`
- Delete (from the moved tree, before commit): `.superpowers/`

**Interfaces:**
- Consumes: `preflight-godaddy-report.md` from Task 1 (stays in the folder, but gitignored)
- Produces: a clean working tree at `~/projects/persononomo/kozub-dev/` on `main` branch with one commit; `assistant/CLAUDE.md` no longer lists kozub-dev as an active role

- [ ] **Step 1: Verify source and target state**

Run:
```bash
ls -la ~/projects/persononomo/kozub-dev 2>&1 || echo "target does not exist (expected)"
ls -la ~/projects/persononomo/assistant/kozub-dev
```

Expected: target does not exist; source contains at minimum `CLAUDE.md`, `index.html`, `cv.pdf`, `docs/`, `.superpowers/`, `preflight-godaddy-report.md`.

- [ ] **Step 2: Move the folder**

```bash
mv ~/projects/persononomo/assistant/kozub-dev ~/projects/persononomo/kozub-dev
```

Expected: `~/projects/persononomo/assistant/kozub-dev` gone, `~/projects/persononomo/kozub-dev` present with all contents.

- [ ] **Step 3: Remove the brainstorming session dir from the moved tree**

```bash
rm -rf ~/projects/persononomo/kozub-dev/.superpowers
```

- [ ] **Step 4: Write `.gitignore`**

Create `~/projects/persononomo/kozub-dev/.gitignore` with exactly:

```
.DS_Store
.superpowers/
preflight-godaddy-report.md
*.swp
.idea/
.vscode/
```

- [ ] **Step 5: `git init`, set default branch `main`**

```bash
cd ~/projects/persononomo/kozub-dev
git init -b main
```

Expected: `.git/` created, HEAD on `main`.

- [ ] **Step 6: Stage and verify no secrets staged**

```bash
git add .
git status
```

Expected: `preflight-godaddy-report.md` is **NOT** in the staged list. If it is, something is wrong with `.gitignore` — fix before continuing. Expected staged: `.gitignore`, `CLAUDE.md`, `cv.pdf`, `docs/...`, `index.html`.

- [ ] **Step 7: Commit the initial tree**

```bash
git commit -m "chore: initial import — move kozub-dev out of assistant tree"
```

- [ ] **Step 8: Update `~/projects/persononomo/assistant/CLAUDE.md`**

Remove the `kozub-dev/` row from the "Активные роли" table and the `assistant/kozub-dev/CLAUDE.md` reference in the "Архитектура" tree. Replace with a one-liner under the "Стандалоны (не-life)" list:

```
- `kozub-dev/` (moved to `~/projects/persononomo/kozub-dev/`) — personal landing page kozub.dev
```

Also delete the "kozub-dev" line from the file-tree code block at the top of that file.

- [ ] **Step 9: Verify**

Run `grep -n kozub-dev ~/projects/persononomo/assistant/CLAUDE.md`. Expected: at most 1-2 lines, all under "Стандалоны".

(No git commit in the assistant tree — assistant is not a git repo in this plan's scope.)

---

## Task 3: Acquire 6 brand logo SVGs

**Goal:** Produce 6 small, inline-ready SVG strings for the `WORKED AT` strip, each small enough to live inside `index.html` without bloating it.

**Files:**
- Create (temporary, used only in Task 4): `~/projects/persononomo/kozub-dev/docs/logos/<name>.svg` for each of: `phoenix365`, `oversecured`, `infosys`, `keyua`, `perfsys`, `privatbank`

**Interfaces:**
- Consumes: nothing
- Produces: 6 SVG files in `docs/logos/`, each a single `<svg>` element with `viewBox`, uses `currentColor` for fills/strokes so CSS can tint them, roughly ≤2 KB each (ideally ≤1 KB). Each file's `aria-label` is the clean company name as rendered on their site.

- [ ] **Step 1: Source each logo**

For each company, in this order, try:
1. Official brand/press kit page on their site
2. Wikipedia article's commons SVG
3. Simple-icons.org (CC0, pre-normalized)
4. If none available: trace a low-complexity version from an official PNG using a vector tool, or ask Pavlo to drop a cleaner source

Companies ranked by expected sourcing difficulty (hardest first): KeyUA, Perfsys, Phoenix365, Oversecured, PrivatBank, Infosys.

If after 10 minutes a logo is still not found cleanly, stop and ask Pavlo in chat.

- [ ] **Step 2: Normalize each SVG**

For each `svg` file:
- Replace hard-coded `fill="#..."` / `stroke="#..."` with `fill="currentColor"` / `stroke="currentColor"` so CSS can tint them
- Capture the **original brand color** (hex) as a comment at the top: `<!-- brand: #0033A0 -->` — Task 4 reads this to apply the hover-reveal color
- Add `aria-label="<Company Name>"` to the root `<svg>`
- Add `role="img"` to the root `<svg>`
- Strip XML preamble, DOCTYPE, metadata, Inkscape editor state, redundant groups
- Set a consistent intrinsic height via `viewBox` + no fixed `width/height` attributes — CSS handles sizing
- Target file size: ≤2 KB each; if >2 KB, run through SVGO logic (manual review of path precision)

- [ ] **Step 3: Verify**

Run:
```bash
cd ~/projects/persononomo/kozub-dev/docs/logos
ls -la
wc -c *.svg
```

Expected: 6 files present, each ≤2048 bytes.

Spot-check one in a browser (open directly): it renders. Change its `color` CSS or wrap in `<div style="color: red">`: it tints.

- [ ] **Step 4: Commit the logo working set**

```bash
cd ~/projects/persononomo/kozub-dev
git add docs/logos/
git commit -m "assets: add inline SVG logos for WORKED AT strip"
```

Note: `docs/logos/` stays in the repo as a working-set reference even though the HTML inlines them. Future updates (replacing a traced logo with an official one) work by editing the file in `docs/logos/` and re-inlining.

---

## Task 4: HTML edits — About rewrite, WORKED AT, ALSO BUILDING

**Goal:** The three content changes to `index.html` land in one editing pass, verified visually in light + dark + mobile with and without `prefers-reduced-motion`.

**Files:**
- Modify: `~/projects/persononomo/kozub-dev/index.html`

**Interfaces:**
- Consumes: 6 SVGs from `docs/logos/` (Task 3), their original brand colors from the `<!-- brand: -->` comments
- Produces: a committed `index.html` with the three new/changed sections, section order `hero → about → WORKED AT → highlights → ALSO BUILDING → contact → footer`

- [ ] **Step 1: Rewrite the About line (name Phoenix365)**

In the `.about` section (`index.html:347`), replace:

> `Currently on the platform team at a global iGaming product running multi-region Kubernetes — <strong>5 EKS clusters, 5 AWS accounts, 400+ microservices</strong>.`

with:

> `Currently on the platform team at <strong>Phoenix365</strong> — multi-region Kubernetes, 5 EKS clusters, 5 AWS accounts, 400+ microservices.`

Nothing else in the paragraph changes.

- [ ] **Step 2: Add `rel="me"` to identity links**

In the `.contact` section, add `rel="me noopener noreferrer"` to the LinkedIn and GitHub links (replacing existing `rel="noopener noreferrer"`). Leave `mailto:` and `/cv.pdf` as-is.

- [ ] **Step 3: Add CSS for `.worked-at` and `.also-building`**

In the `<style>` block, after the existing `/* — highlights — */` rule and before `/* — contact — */`, add two rules.

`.worked-at`:
- Margin bottom matching `.highlights` (88px desktop)
- Section `.label` sibling (reuses the `.loc` typographic treatment — JetBrains Mono, uppercase, 0.18em letter-spacing, terracotta, 12px — but as `.worked-at .label`)
- `.logos` flexbox: `display: flex; flex-wrap: wrap; gap: 20px 32px; align-items: center; margin-top: 20px;`
- `.logos a`: `display: inline-flex; align-items: center; color: var(--ink-soft); transition: color 240ms ease, transform 240ms cubic-bezier(0.65,0,0.35,1), opacity 240ms ease; opacity: 0.72;`
- `.logos a svg`: `height: 28px; width: auto; display: block;` (mobile override `height: 22px`)
- `.logos a:hover`: sets `opacity: 1`, `transform: translateY(-1px)`, and sets `color: var(--brand)` where `--brand` is a per-link custom property set inline from Step 4
- Inside `@media (prefers-reduced-motion: reduce)`: `.logos a:hover { transform: none; }` (color + opacity still change)
- Inside the `@media (max-width: 640px)` block: `.worked-at { margin-bottom: 64px; } .logos { gap: 16px 24px; } .logos a svg { height: 22px; }`
- Animation: `animation: rise 900ms cubic-bezier(0.16, 1, 0.3, 1) 450ms both;` — slot between `.about` (380ms) and `.highlights` (which keeps 520ms)
- Visually-hidden utility if not already present: `.visually-hidden { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0 0 0 0); white-space:nowrap; border:0; }`

`.also-building`:
- Margin bottom matching `.highlights` (88px desktop, 64px mobile)
- `.label` same JetBrains Mono / uppercase / 0.18em / terracotta treatment
- `.rows`: `display: grid; grid-template-columns: auto 1fr; gap: 10px 24px; margin-top: 20px; border-top: 1px solid var(--clay); padding-top: 20px;`
- `.rows a`: terracotta link, Fraunces 500, 20px, same underline-slide hover as `.contact a` (reuse the terracotta sweep pattern)
- `.rows .descriptor`: Newsreader italic, 17px, color `var(--ink-soft)`
- Animation: `animation: rise 900ms cubic-bezier(0.16, 1, 0.3, 1) 580ms both;` — slot after `.highlights` (520ms)
- Must also adjust `.contact` animation delay from 660ms → 720ms, and `footer` from 800ms → 860ms, to keep the staggered rise sequence intact.

- [ ] **Step 4: Add the `WORKED AT` markup**

Immediately after the closing `</section>` of `.about` and before the opening `<section class="highlights">`, insert:

```html
<section class="worked-at" aria-label="Companies I've worked at">
  <p class="label">Worked at</p>
  <div class="logos">
    <!-- Order: current → oldest -->
    <a href="https://phoenix365.com/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="Phoenix365">
      <!-- inline SVG from docs/logos/phoenix365.svg -->
      <span class="visually-hidden">Phoenix365</span>
    </a>
    <a href="https://oversecured.com/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="Oversecured">
      <!-- inline SVG from docs/logos/oversecured.svg -->
      <span class="visually-hidden">Oversecured</span>
    </a>
    <a href="https://www.infosys.com/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="Infosys">
      <!-- inline SVG from docs/logos/infosys.svg -->
      <span class="visually-hidden">Infosys</span>
    </a>
    <a href="https://keyua.org/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="KeyUA">
      <!-- inline SVG from docs/logos/keyua.svg -->
      <span class="visually-hidden">KeyUA</span>
    </a>
    <a href="https://perfsys.com/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="Perfsys">
      <!-- inline SVG from docs/logos/perfsys.svg -->
      <span class="visually-hidden">Perfsys</span>
    </a>
    <a href="https://www.privatbank.ua/" target="_blank" rel="noopener noreferrer" style="--brand: #<from logo comment>;" aria-label="PrivatBank">
      <!-- inline SVG from docs/logos/privatbank.svg -->
      <span class="visually-hidden">PrivatBank</span>
    </a>
  </div>
</section>
```

For each `<a>`:
- Replace the inline-SVG comment with the full contents of the corresponding file in `docs/logos/`
- Replace `--brand: #<from logo comment>` with the hex from the file's `<!-- brand: -->` top comment
- If the official site URL above is wrong for any company (builder judgment), use the correct one; prefer the English-language landing page

- [ ] **Step 5: Add the `ALSO BUILDING` markup**

Immediately after the closing `</section>` of `.highlights` and before the opening `<section class="contact">`, insert:

```html
<section class="also-building" aria-label="Also building">
  <p class="label">Also building</p>
  <div class="rows">
    <a href="https://inakshe.com/" target="_blank" rel="me noopener noreferrer">inakshe ↗</a>
    <p class="descriptor">A catalog of specialists who work well with neurodivergent people.</p>
  </div>
</section>
```

(The arrow glyph is `↗` U+2197. Pavlo picked it in the brainstorm.)

- [ ] **Step 6: Visual verification — light theme, desktop**

Open `~/projects/persononomo/kozub-dev/index.html` in a real browser (not just view-source). Verify:
- Section order is hero → about → **Worked at** → highlights 01-03 → **Also building** → contact → footer
- About paragraph names Phoenix365
- Logo strip renders, logos visibly monochrome (ink-soft color)
- Hovering any logo: it brightens AND goes to brand color AND lifts 1px
- `Also building` row shows inakshe link + the italic descriptor
- Contact row still has the four original links
- No layout shift, no horizontal scroll

- [ ] **Step 7: Visual verification — dark theme**

Toggle the moon/sun button. Verify same checklist as Step 6 in dark theme. Logos should remain legible (ink-soft on dark is `rgba(237,226,210,0.66)`), and hover-color should still read.

- [ ] **Step 8: Visual verification — mobile 375px viewport**

Open devtools responsive mode at 375×812 (iPhone 13 size). Verify:
- Logo strip wraps gracefully (likely 3+3 or 2+2+2)
- Logo height is ~22px, not 28px
- `Also building` row stays grid-aligned, not stacked oddly
- All spacing still breathable

- [ ] **Step 9: Visual verification — `prefers-reduced-motion`**

In Chrome devtools: Rendering panel → Emulate CSS media feature `prefers-reduced-motion: reduce`. Hover any logo. Verify:
- Color still changes (ink → brand)
- Opacity still changes (0.72 → 1.0)
- `translateY` is **suppressed** — no vertical motion

- [ ] **Step 10: Commit**

```bash
cd ~/projects/persononomo/kozub-dev
git add index.html
git commit -m "feat: add WORKED AT logo strip and ALSO BUILDING row, name Phoenix365 in about"
```

---

## Task 5: GitHub repo creation and first push

**Goal:** The committed `main` branch lives at `https://github.com/persononomo/kozub-dev`, public.

**Files:**
- No local file changes
- Creates: GitHub remote `persononomo/kozub-dev`

**Interfaces:**
- Consumes: committed git history from Tasks 2, 3, 4
- Produces: pushed `main` at `github.com/persononomo/kozub-dev`

- [ ] **Step 1: Verify gh is authenticated for `persononomo`**

```bash
gh auth status
```

Expected: logged in as `persononomo` with `repo` scope. If not, run `gh auth login` (user-interactive — have Pavlo complete it).

- [ ] **Step 2: Check repo doesn't already exist**

```bash
gh repo view persononomo/kozub-dev 2>&1 | head -1
```

Expected: `Could not resolve to a Repository`. If the repo already exists, stop and ask Pavlo how to proceed (don't blindly push).

- [ ] **Step 3: Create the public repo (no description content leak)**

```bash
gh repo create persononomo/kozub-dev \
  --public \
  --description "Personal landing — kozub.dev" \
  --source ~/projects/persononomo/kozub-dev \
  --remote origin \
  --push
```

`--push` pushes the current `main` immediately.

- [ ] **Step 4: Verify the push**

```bash
gh repo view persononomo/kozub-dev --json url,visibility,defaultBranchRef
curl -sS -o /dev/null -w "%{http_code}\n" https://raw.githubusercontent.com/persononomo/kozub-dev/main/index.html
```

Expected: visibility=`PUBLIC`, defaultBranch=`main`, HTTP 200 on the raw HTML.

- [ ] **Step 5: Confirm `preflight-godaddy-report.md` is NOT on GitHub**

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://raw.githubusercontent.com/persononomo/kozub-dev/main/preflight-godaddy-report.md
```

Expected: 404. If 200, the auth code / secrets leaked — immediately rotate at GoDaddy, force-push a tree without that file, and investigate the `.gitignore`.

---

## Task 6: Add kozub.dev zone to Cloudflare (inakshe-safe)

**Goal:** The `kozub.dev` zone exists in the same Cloudflare account as `inakshe.com`, populated with the records from the GoDaddy snapshot, with inakshe DNS verifiably untouched. Nameservers at GoDaddy are *not yet* changed in this task.

**Files:**
- Create: `~/projects/persononomo/kozub-dev/docs/preflight-inakshe-snapshot.md` (DNS records before + after; gitignored since it reveals infra)
- Append pre-cutover record list into the audit trail

**Interfaces:**
- Consumes: `preflight-godaddy-report.md` DNS records (Task 1), confirmation that this is the correct Cloudflare account (same one that hosts inakshe)
- Produces: Cloudflare zone `kozub.dev` with records matching GoDaddy snapshot (minus future additions); inakshe zone untouched; Cloudflare-assigned nameservers written to a note for Task 7

- [ ] **Step 1: Snapshot inakshe DNS**

Pavlo (or via API if credentials available) exports the inakshe.com DNS record list from Cloudflare. Save to `docs/preflight-inakshe-snapshot.md` with a `## before` section. Add `preflight-inakshe-snapshot.md` to `.gitignore`.

- [ ] **Step 2: Add kozub.dev zone**

In the Cloudflare dashboard (same account):
- Add a new site → `kozub.dev`
- Plan: Free
- Let Cloudflare attempt automatic record import if GoDaddy exposes a scan — but **do not accept destructive changes**; cross-check against Task 1 snapshot and manually re-add anything missed
- Note the two assigned Cloudflare nameservers (e.g. `tim.ns.cloudflare.com`, `laila.ns.cloudflare.com`) — exact names vary per account

Record these nameservers in a step-6 note (not in the git repo).

- [ ] **Step 3: Populate records**

Enter the records from Task 1's snapshot. For each: match type, name, value, TTL. Set `Proxy status` to **DNS only** (grey cloud) for every record **until Task 8 binds Pages** — this prevents Cloudflare from front-proxying a nonexistent site in the window between NS change and Pages binding.

If the GoDaddy snapshot was "parked / no records", enter nothing yet. Task 8 will add the apex and www CNAMEs. Task 9 will add MX/SPF/DMARC.

- [ ] **Step 4: Verify inakshe DNS unchanged**

Re-export inakshe.com records → save as `## after` section in the inakshe snapshot file. `diff` the two sections.

Expected: empty diff. If **any** inakshe record changed, stop and investigate before proceeding — do not run Task 7.

- [ ] **Step 5: Verify kozub.dev zone shows pending**

Cloudflare dashboard should show `kozub.dev` with status `Pending nameserver update` (expected — NS still at GoDaddy).

---

## Task 7: DNS cutover at GoDaddy (RISKY — needs Pavlo's explicit go)

**Goal:** `kozub.dev` nameservers point to Cloudflare. One of two paths from Task 1's report is executed.

**Files:**
- None local.

**Interfaces:**
- Consumes: `preflight-godaddy-report.md` → chosen path, Cloudflare nameserver names from Task 6, confirmation that Task 8 and Task 9 are *staged and ready* (Pages built but not yet domain-bound; Email Routing not yet enabled — because MX records flip on with NS)
- Produces: `whois kozub.dev` shows Cloudflare NS; registrar status updated

**Pre-requisite before this task starts:** Tasks 2–6 and 9 complete, Task 8 ready to run immediately after.

- [ ] **Step 1: Stop and get explicit confirmation from Pavlo**

Message in chat: "About to switch nameservers at GoDaddy. This is the irreversible step. Pages build is ready, Email Routing is ready. Say GO or NO."

Wait for explicit `GO` before proceeding.

- [ ] **Step 2: Execute the chosen path**

**Path A — nameserver change only (common case):**
Pavlo logs into GoDaddy → Domain Settings for `kozub.dev` → Nameservers → change to the two Cloudflare NS from Task 6. Save.

**Path B — full registrar transfer:**
Pavlo logs into GoDaddy → unlock (if locked) → get auth/EPP code → log into Cloudflare → Domains → Transfer Domains → enter `kozub.dev` + auth code → pay the one-year renewal fee at Cloudflare → confirm initiation emails from both GoDaddy and Cloudflare (approve on both sides). Transfer typically completes in 5-7 days; nameserver propagation starts within hours once both sides acknowledge.

- [ ] **Step 3: Verify WHOIS privacy**

Wait 15 minutes for propagation, then:

```bash
whois kozub.dev | grep -i -E "(registrar|name server|registrant|admin|tech|privacy)" | head -30
```

Expected: Registrar shows Cloudflare (path B) or still GoDaddy (path A); nameservers list Cloudflare; registrant / admin / tech contact fields show privacy/redacted strings (something like "Domains By Proxy" at GoDaddy, "DATA REDACTED" at Cloudflare), **never Pavlo's home address or phone**.

If any field leaks real contact info, pause and flip privacy on at the current registrar before anything else.

- [ ] **Step 4: Verify Cloudflare sees activation**

Cloudflare dashboard: `kozub.dev` zone status moves from `Pending nameserver update` to `Active` (can take minutes to a few hours).

Expected: `Active`. If stuck >6 hours, check NS actually changed:
```bash
dig NS kozub.dev @8.8.8.8 +short
```

---

## Task 8: Cloudflare Pages — deploy, bind, verify

**Goal:** `https://kozub.dev/` and `https://www.kozub.dev/` both serve the site over HTTPS with TLS Full (strict); www redirects to apex.

**Files:**
- None local.

**Interfaces:**
- Consumes: GitHub repo from Task 5 (must be reachable from Cloudflare Pages via GitHub App), activated Cloudflare zone from Task 7
- Produces: Pages project `kozub-dev` with production deployment on `main`, custom domains `kozub.dev` + `www.kozub.dev` bound; `www→apex` 301 in place

**Note:** Steps 1–3 can run *before* Task 7 (project built, no custom domain bound). Step 4 onward requires NS at Cloudflare.

- [ ] **Step 1: Create the Pages project**

Cloudflare dashboard → Pages → Create project → Connect to Git → authorize GitHub App for `persononomo` (one-time) → pick `persononomo/kozub-dev`.

Build settings:
- Framework preset: `None`
- Build command: *(empty)*
- Build output directory: `/`
- Root directory: *(empty / default)*
- Environment variables: *(none)*

- [ ] **Step 2: Trigger first production deploy**

Save. Pages runs the first build (which is a no-op copy) and produces a `*.pages.dev` URL (e.g. `kozub-dev.pages.dev`).

- [ ] **Step 3: Verify the pages.dev URL serves the site correctly**

```bash
curl -sS -o /dev/null -w "status=%{http_code}\n" https://kozub-dev.pages.dev/
curl -sS https://kozub-dev.pages.dev/ | grep -c "Pavlo Kozub"
curl -sS -o /dev/null -w "status=%{http_code}\n" https://kozub-dev.pages.dev/cv.pdf
```

Expected: HTML 200, "Pavlo Kozub" count ≥1, cv.pdf 200.

- [ ] **Step 4: Bind custom domains (runs AFTER Task 7's NS cutover)**

In the Pages project → Custom domains → add `kozub.dev` and `www.kozub.dev`. Cloudflare automatically creates the apex CNAME-flattened record and the www CNAME, both proxied (orange cloud) and pointing to the Pages project.

- [ ] **Step 5: Set `www → apex` redirect**

Cloudflare dashboard → Rules → Redirect Rules → create a new rule:
- When incoming requests match: Hostname equals `www.kozub.dev`
- Then: Dynamic → Expression: `concat("https://kozub.dev", http.request.uri.path)`, Status 301, Preserve query string ON

Save and deploy.

- [ ] **Step 6: TLS & HSTS**

Cloudflare dashboard → SSL/TLS:
- Encryption mode: `Full (strict)`
- Minimum TLS Version: `1.2`
- Edge Certificates → HSTS → enable with max-age = 15552000 (6 months), include subdomains OFF initially, preload OFF initially. (Spec: raise to 12 months after 2 weeks clean.)

- [ ] **Step 7: Verify the production domain**

```bash
curl -sS -o /dev/null -w "status=%{http_code}  final=%{url_effective}\n" -L https://kozub.dev/
curl -sS -o /dev/null -w "status=%{http_code}  final=%{url_effective}\n" -L https://www.kozub.dev/
curl -sSI https://kozub.dev/ | grep -iE "(strict-transport|server|content-type)"
curl -sS https://kozub.dev/ | grep -c "Phoenix365"
```

Expected: both URLs return 200 (www after 301 redirect), `Strict-Transport-Security` header present with the 6-month max-age, content-type `text/html`, Phoenix365 string count ≥1 (sanity that the latest commit shipped).

---

## Task 9: Email Routing — contact@kozub.dev + SPF + DMARC

**Goal:** Mail sent to `contact@kozub.dev` from an arbitrary external sender arrives at `pavlo.kozub@gmail.com`.

**Files:**
- None local.

**Interfaces:**
- Consumes: active Cloudflare zone from Task 7 (so MX/TXT records can be added), the already-verified destination `pavlo.kozub@gmail.com` on this account (confirmed in brainstorm — same account as inakshe.com)
- Produces: `contact@kozub.dev` route active, SPF + DKIM + DMARC in zone

**Note:** This task can be set up before Task 7's NS cutover (records go in the zone but don't resolve externally until NS flips). The verified-destination step is a no-op since gmail is already confirmed on this account.

- [ ] **Step 1: Enable Email Routing on `kozub.dev`**

Cloudflare dashboard → zone `kozub.dev` → Email → Email Routing → Get started. Cloudflare proposes to add MX records + a TXT SPF record automatically — accept the propose. This writes:
- `MX kozub.dev route1.mx.cloudflare.net` (priority 11)
- `MX kozub.dev route2.mx.cloudflare.net` (priority 36)
- `MX kozub.dev route3.mx.cloudflare.net` (priority 90)
- `TXT kozub.dev "v=spf1 include:_spf.mx.cloudflare.net ~all"`

- [ ] **Step 2: Add the `contact@` route**

Routes → Create → Custom address → `contact@kozub.dev` → Action: Send to an email → Destination: `pavlo.kozub@gmail.com` (already verified → shown as a selectable chip, no re-verification email). Save.

Catch-all: leave **Disabled**.

- [ ] **Step 3: Add DMARC**

Zone → DNS → add TXT:
- Name: `_dmarc`
- Content: `v=DMARC1; p=none; rua=mailto:pavlo.kozub@gmail.com; ruf=mailto:pavlo.kozub@gmail.com; adkim=r; aspf=r`
- TTL: Auto

(`p=none` for the first week — monitor. Spec: upgrade to `p=quarantine` after a clean week.)

- [ ] **Step 4: End-to-end delivery test (runs AFTER Task 7)**

From an external mailbox (any gmail, outlook, etc. that is **not** `pavlo.kozub@gmail.com`), send a plain-text email to `contact@kozub.dev` with subject `kozub.dev routing test <YYYY-MM-DD>`.

Pavlo checks `pavlo.kozub@gmail.com` within 2 minutes.

Expected: email arrives in the primary inbox (not spam). Headers show Cloudflare Email Routing in the delivery path.

- [ ] **Step 5: Mail-tester score**

Go to https://www.mail-tester.com/ → copy the generated test address → send a message to that address via `contact@kozub.dev`... wait: this requires Pavlo to *reply from* `contact@kozub.dev`, which Email Routing doesn't support (forwarding only). Instead: run the inverse — send **from** `pavlo.kozub@gmail.com` to the mail-tester address to confirm gmail SPF/DMARC alignment, and separately check inbound reputation by sending from a disposable address and reading full headers.

Spot-check manually in the test email from Step 4: full headers → `Authentication-Results` line should show `spf=pass` for Cloudflare and `dmarc=pass` (or `dmarc=bestguesspass`).

If `dmarc=fail`: the DMARC record propagated but SPF alignment is off — recheck SPF record exact string.

---

## Task 10: Launch validation pass

**Goal:** One end-to-end validation that reports go/no-go for calling the project done.

**Files:**
- Create: `~/projects/persononomo/kozub-dev/docs/launch-validation-<YYYY-MM-DD>.md`

**Interfaces:**
- Consumes: everything from Tasks 1–9
- Produces: a signed-off validation report; or a list of blocking issues

- [ ] **Step 1: Site reachability**

```bash
curl -sSI https://kozub.dev/ | head -5
curl -sSI https://www.kozub.dev/ | head -5
curl -sS -o /dev/null -w "%{http_code}\n" https://kozub.dev/cv.pdf
curl -sS https://kozub.dev/ | grep -oE "(Phoenix365|inakshe|Oversecured)" | sort -u
```

Expected: apex 200, www 301 → apex 200, cv.pdf 200, all three strings present in the HTML.

- [ ] **Step 2: TLS & headers**

```bash
curl -sSI https://kozub.dev/ | grep -iE "(strict-transport|content-security|x-content-type|server)"
echo | openssl s_client -connect kozub.dev:443 -servername kozub.dev 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

Expected: HSTS header present with the 6-month max-age; cert issuer = Cloudflare's chosen CA; NotAfter at least 60 days in future.

- [ ] **Step 3: DNS sanity**

```bash
dig +short NS kozub.dev @8.8.8.8
dig +short A kozub.dev @1.1.1.1
dig +short CNAME www.kozub.dev @1.1.1.1
dig +short MX kozub.dev @1.1.1.1
dig +short TXT kozub.dev @1.1.1.1 | head -3
dig +short TXT _dmarc.kozub.dev @1.1.1.1
```

Expected: NS = Cloudflare pair; A for apex resolves (CNAME-flattened); CNAME for www; three MX records to `routeN.mx.cloudflare.net`; SPF includes `_spf.mx.cloudflare.net`; DMARC starts with `v=DMARC1`.

- [ ] **Step 4: Visual pass in Pavlo's browser (both themes, mobile)**

Pavlo opens `https://kozub.dev/` in Safari (or his default browser), confirms:
- Light theme renders as expected, section order correct
- Dark theme after toggle looks right
- Mobile view (devtools or real phone) wraps correctly
- Hovering a logo tints it to brand color + lifts 1px
- `prefers-reduced-motion` disables the lift but keeps color (optional check if Pavlo has access to the toggle)

- [ ] **Step 5: Email round-trip (final)**

Repeat Task 9 Step 4 if more than 24 hours have passed. Confirm fresh test mail arrives.

- [ ] **Step 6: WHOIS privacy final check**

```bash
whois kozub.dev | grep -iE "(privacy|redact|registrant name|registrant organization|registrant street|registrant phone)" | head
```

Expected: all registrant identifier fields show the registrar's privacy proxy, not Pavlo's real info.

- [ ] **Step 7: Write the validation report**

```markdown
# Launch validation — kozub.dev — <YYYY-MM-DD>

- Site reachable: <✓/✗>
- TLS + HSTS: <✓/✗>  (cert expires <date>)
- DNS: <✓/✗>  (NS at Cloudflare, MX via Email Routing, SPF/DMARC in zone)
- Visual pass (light / dark / mobile / reduced-motion): <✓/✗>
- Email round-trip: <✓/✗>  (test sent <time>, arrived <time>)
- WHOIS privacy: <✓/✗>

## Open issues
<list, or "none">

## Follow-ups (not blocking)
- Raise HSTS max-age 6mo → 12mo after 2 weeks clean (target: <date>)
- Raise DMARC p=none → p=quarantine after 1 week clean (target: <date>)
- (If Task 7 took Path A) Full registrar transfer at next renewal.
```

- [ ] **Step 8: Commit the report**

```bash
cd ~/projects/persononomo/kozub-dev
git add docs/launch-validation-*.md
git commit -m "docs: launch validation report"
git push
```

---

## Task 11: Project documentation sync

**Goal:** `CLAUDE.md` inside the new location reflects reality (new path, deploy mechanism, email flow); vault daily log notes the launch; parent assistant tree already updated in Task 2.

**Files:**
- Modify: `~/projects/persononomo/kozub-dev/CLAUDE.md`
- Create: `~/knowledge/daily/YYYY-MM-DD.md` entry (or append if the file exists)

**Interfaces:**
- Consumes: everything about final state (deploy path, email route, DNS owner)
- Produces: project CLAUDE.md matches reality; daily log entry wikilinks to the project

- [ ] **Step 1: Update `~/projects/persononomo/kozub-dev/CLAUDE.md`**

Replace the file's content with a version that reflects post-launch reality. Required updates:
- Location: `~/projects/persononomo/kozub-dev/` (not `assistant/kozub-dev/`)
- Files list: add `docs/logos/`, `docs/superpowers/`, `.gitignore`, `docs/launch-validation-*.md`
- Workflow:
  - Edit `index.html` → `git commit` → `git push` → Cloudflare Pages auto-deploy
  - Logo updates: edit the file in `docs/logos/` AND the inlined copy in `index.html` (both)
- Deploy section: Cloudflare Pages, same account as inakshe.com, custom domains apex + www
- Email: `contact@kozub.dev` → `pavlo.kozub@gmail.com` via Cloudflare Email Routing
- DNS owner: Cloudflare (full), registrar = <Cloudflare | GoDaddy depending on Path A/B of Task 7)
- Sensitive section: note that `preflight-godaddy-report.md` is gitignored because it may contain the auth code
- Remove the "TODO uncertain hosting" entry — resolved.

- [ ] **Step 2: Daily log entry**

Append to `~/knowledge/daily/<today>.md` (create the file with frontmatter if it doesn't exist — per vault CLAUDE.md convention):

```markdown
## kozub.dev launched

- Moved `assistant/kozub-dev/` → `~/projects/persononomo/kozub-dev/`
- New sections on landing: `WORKED AT` (6 logos, hover-reveal) + `ALSO BUILDING` (inakshe row)
- Deploy: GitHub `persononomo/kozub-dev` → Cloudflare Pages
- Email: `contact@kozub.dev` → gmail via Cloudflare Email Routing
- Registrar: <Cloudflare | GoDaddy (transfer at renewal)>
- See [[projects/kozub-dev]] (if a vault note exists) and the launch validation report in the repo
```

- [ ] **Step 3: Commit CLAUDE.md**

```bash
cd ~/projects/persononomo/kozub-dev
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md to reflect launched state"
git push
```

---

## Self-review notes

- **Spec coverage:** Every spec Goal (1–8) has an owning task. Every "What the plan has to cover" bullet (1–16) maps to a step in a task. Explicit map: spec-#1 (live site) → T8/T10. spec-#2 (inakshe link) → T4. spec-#3 (WORKED AT) → T3+T4. spec-#4 (folder move) → T2. spec-#5 (GitHub) → T5. spec-#6 (Cloudflare DNS) → T6+T7. spec-#7 (push-to-deploy) → T5+T8. spec-#8 (email) → T9. Non-goals and anti-goals are negatively enforced via Review Focus items 1–4.
- **Order & dependencies:** T1 pre-flight read-only; T2–T5 local + GitHub; T6 (Cloudflare zone) prepped before T7 (NS switch — the risky one); T9 (Email Routing) can land in-zone before T7 since DNS isn't propagated yet; T8 Pages project pre-built before T7, custom-domain binding happens *after* T7; T10 validation last; T11 docs last.
- **Risky steps gated:** T7 Step 1 is a hard stop with explicit `GO/NO` from Pavlo. T5 Step 3 touches GitHub but is low-blast-radius (public one-file site). All other external writes are confined to Cloudflare dashboard clicks that are easily reversible.
- **Review Focus pinning:** DNS cutover race → T8 (bind-before-switch) + T10 Step 1. Mailto-before-mail → T9 ordering before T7. Inakshe untouched → T6 Steps 1 and 4. Reduced-motion → T4 Step 9. Whois privacy → T7 Step 3 + T10 Step 6.
