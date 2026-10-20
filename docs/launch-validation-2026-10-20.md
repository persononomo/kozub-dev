# Launch validation — kozub.dev — 2026-10-20

## Site reachability — ✓
- `https://kozub.dev/` → HTTP/2 200, `content-type: text/html; charset=utf-8`
- `https://www.kozub.dev/` → HTTP/2 301, `location: https://kozub.dev/`, HSTS header present
- `https://kozub.dev/cv.pdf` → HTTP/2 200, `content-type: application/pdf`, `content-length: 100803` (matches local file)

## TLS + headers — ✓
- `Strict-Transport-Security: max-age=15552000` (6 months) on both apex and www
- `Server: cloudflare`, `x-content-type-options: nosniff`
- TLS: Full (strict) at CF edge. Certificate issued by Google Trust Services, CN `kozub.dev`, NotBefore `2026-10-20 09:12 UTC`, NotAfter `2027-01-18 10:11 UTC` (90-day auto-rotation, standard CF behavior).

## DNS — ✓
- NS: `dahlia.ns.cloudflare.com`, `ed.ns.cloudflare.com`
- Apex A: `104.21.80.218`, `172.67.187.71` (CNAME-flattened to Pages, proxied)
- Apex AAAA: `2606:4700:3030::6815:50da`, `2606:4700:3034::ac43:bb47`
- `www.kozub.dev` → CNAME to Pages, proxied (resolves to the same IPs)
- MX: 10 route2, 15 route3, 30 route1 — `*.mx.cloudflare.net`
- SPF: `v=spf1 include:_spf.mx.cloudflare.net ~all`
- DMARC: `v=DMARC1; p=none; rua=mailto:pavlo.kozub@gmail.com; ruf=mailto:pavlo.kozub@gmail.com; adkim=r; aspf=r`
- `www→apex` 301 redirect rule deployed (stub proxied record for www created via dashboard — later became redundant once www was bound as a Pages custom domain)

## Visual pass — ✓ (self-check by Pavlo in browser)
- Light theme: section order hero → about → WORKED AT → highlights → ALSO BUILDING → contact → footer
- About names Phoenix365 explicitly
- Six wordmarks render monochrome, hover tints to brand color
- `prefers-reduced-motion`: color still changes, translateY suppressed (wrapped in `@media (prefers-reduced-motion: no-preference)`)
- Mobile 375px viewport: logos wrap, also-building stacks

## Email round-trip — ✓
- Sent from `pavlo.kozub@phoenix365.tech` at 12:39:03 — bounced with `550 5.1.1 Address does not exist` because CF Email Routing service was still in Syncing status (~60s after route creation)
- Retry after service flipped to Active → delivered to `pavlo.kozub@gmail.com` inbox successfully
- DKIM signature path through Email Routing confirmed in headers

## Content strings on live site — ✓
All of these present on `curl https://kozub.dev/`:
- "Pavlo Kozub"
- "Phoenix365"
- "Oversecured"
- "inakshe"
- "Worked at"
- "Also building"
- "catalog of specialists"

## Open issues

None blocking.

## Follow-ups (not blocking)

- Raise HSTS max-age 6mo → 12mo after 2 weeks clean (target: 2026-11-03)
- Raise DMARC `p=none` → `p=quarantine` after 1 week of clean aggregate reports (target: 2026-10-27)
- Wire Cloudflare Pages git-connect to the existing project so GitHub pushes auto-deploy — currently every HTML update needs `npx wrangler pages deploy . --project-name=kozub-dev --branch=main --commit-dirty=true`.
- Full registrar transfer GoDaddy → Cloudflare at next renewal (Path A executed — nameservers only).
- Brand hex colors for the WORKED AT hover-reveal are reasonable guesses — Pavlo can swap any that don't match his sense of the brand.
- Replace typographic wordmarks with inline SVG logos (per original design) if clean SVG sources ever surface.
- WHOIS privacy check: not run against GoDaddy post-cutover (registrar still GoDaddy); privacy was ON there pre-change, assumed still ON. Verify on first renewal when checking the account.
