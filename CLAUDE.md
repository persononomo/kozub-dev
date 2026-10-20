# Project Context — kozub.dev (personal landing)

Публичная landing page Pavlo по адресу `https://kozub.dev/`. Static single-file site (`index.html` + `cv.pdf`), hosted on Cloudflare Pages, DNS и email на Cloudflare (same account as inakshe.com).

## Расположение

`~/projects/persononomo/kozub-dev/` (own git repo, GitHub `persononomo/kozub-dev`, **public**). Переехало из `~/projects/persononomo/assistant/kozub-dev/` 2026-10-20 — публичным standalone проектам место рядом с `inakshe/`, `kidflow/`, `quiet-cove/`, не внутри `assistant/`.

## Файлы

- `index.html` — single-page, lang=en. Содержит все стили inline + inline SVG иконки. Шрифты через Google Fonts с preconnect. Темы — через `data-theme` + CSS vars (light + dark + system).
- `cv.pdf` — публичный CV, копия из `~/projects/persononomo/assistant/devops-side-job/variants/`. **Регенерируется** оттуда — при обновлении CV копируй свежий файл сюда и re-deploy.
- `docs/superpowers/specs/` — design document launch-а
- `docs/superpowers/plans/` — implementation plan
- `docs/launch-validation-*.md` — validation report launch-а
- `.gitignore` — скрывает `.superpowers/`, `preflight-godaddy-report.md`, `preflight-inakshe-snapshot.md` и редакторский мусор

## Workflow

### Правка контента
1. Edit `index.html` → `git add . && git commit -m "..." && git push`
2. **Deploy manual** (пока): `npx wrangler pages deploy . --project-name=kozub-dev --branch=main --commit-dirty=true`
3. Через ~30 сек изменения live на `https://kozub.dev/`

Git-connect to CF Pages → auto-deploy on push пока **не настроен** — unified Workers Builds UX дал токен без `Pages:Edit`. Можно подключить через Pages → kozub-dev → Settings → Builds уже внутри существующего проекта (отдельная задача).

### Обновление CV
1. Регенерируй PDF в `~/projects/persononomo/assistant/devops-side-job/variants/`
2. Скопируй: `cp ~/projects/persononomo/assistant/devops-side-job/variants/<latest>.pdf ~/projects/persononomo/kozub-dev/cv.pdf`
3. Commit + wrangler deploy

### Обновление логотипов `WORKED AT`
Все 6 — typographic wordmarks в JetBrains Mono, не SVG. Hover цвета заданы через `style="--brand: #..."` inline. Если захочется swap на реальные SVG — редактируй `<section class="worked-at">` в `index.html`.

## Деплой-инфраструктура

- **Registrar:** GoDaddy (DNS делегирован Cloudflare; full transfer на next renewal — отдельная задача)
- **DNS:** Cloudflare (same account as inakshe.com), NS `dahlia.ns.cloudflare.com` + `ed.ns.cloudflare.com`
- **Hosting:** Cloudflare Pages, project `kozub-dev`
- **Custom domains:** `kozub.dev` (apex, CNAME-flattened to Pages, proxied) + `www.kozub.dev` (proxied, 301 к apex через Redirect Rule)
- **TLS:** Full (strict), min TLS 1.2, HSTS `max-age=15552000` (6 месяцев)
- **Email:** Cloudflare Email Routing, `contact@kozub.dev → pavlo.kozub@gmail.com`, catch-all **disabled**
- **DMARC:** `p=none` (на 2026-10-20); план → `p=quarantine` через неделю чистых отчётов

## Связанное

- `~/projects/persononomo/assistant/devops-side-job/` — источник `cv.pdf`
- `inakshe.com` — ссылается на kozub.dev через ALSO BUILDING секцию (двусторонний cross-link)
- Design document: `docs/superpowers/specs/2026-10-19-kozub-dev-launch-design.md`
- Plan: `docs/superpowers/plans/2026-10-19-kozub-dev-launch.md`
- Launch validation: `docs/launch-validation-2026-10-20.md`

## Working Conventions

- HTML и CSS inline в `index.html` — не разбивать в отдельные файлы без необходимости
- Google Fonts с preconnect — сохранять для performance
- `rel="me"` на identity-линках (LinkedIn, GitHub, inakshe) — webmention/identity hint
- `prefers-reduced-motion: reduce` → только color-change на hover, без translateY
- **Sensitive:** `preflight-godaddy-report.md` в `.gitignore` потому что может содержать auth/EPP код для transfer; `pavlo.kozub@gmail.com` — публичный, в CV и mailto безопасен
- Перед deploy проверять в light + dark + mobile viewport

## TODO

- [ ] Wire git-connect to CF Pages (auto-deploy on push)
- [ ] HSTS max-age 6mo → 12mo после 2 недель clean (цель: 2026-11-03)
- [ ] DMARC `p=none` → `p=quarantine` после 1 недели clean (цель: 2026-10-27)
- [ ] Full registrar transfer GoDaddy → Cloudflare на следующий renewal
- [ ] Опционально: replace wordmarks на реальные SVG логотипы если найдутся чистые источники
- [ ] GitHub profile cleanup — отдельный трек, не блокирует landing
