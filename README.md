# kozub.dev

Personal landing page for Pavlo Kozub — Senior DevOps / Cloud Engineer, Krakow.

Live at [kozub.dev](https://kozub.dev).

## What's in the box

- `index.html` — the whole site in one file. HTML, CSS, inline SVG, a dash of JS for the theme toggle. No framework, no bundler, no build step.
- `cv-en.md` → `cv.pdf` — resume in markdown, built via `./build-cv.sh` (pandoc + typst).
- `.github/workflows/deploy.yml` — auto-deploy to Cloudflare Pages on push to `main`.

## Preview locally

```sh
python3 -m http.server
# open http://localhost:8000
```

## Rebuild the CV

```sh
./build-cv.sh
```

Requires `pandoc` and `typst` (both via Homebrew). Output: `cv.pdf`, A4, 2 pages.

## Stack

- Hosting: [Cloudflare Pages](https://pages.cloudflare.com/)
- DNS: Cloudflare (CNAME-flattened apex)
- CI: GitHub Actions + `cloudflare/wrangler-action`
- Email: Cloudflare Email Routing (`contact@kozub.dev` → Gmail)

## License

Code (HTML, CSS, JS, build script) is [MIT](./LICENSE). Content — bio, "How I work" principles, CV — is copyrighted; please don't reuse without asking.
