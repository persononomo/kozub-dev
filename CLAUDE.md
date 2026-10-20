# Project Context — kozub.dev (personal landing)

Личная landing page Pavlo. Static site: один `index.html` + `cv.pdf`.

## Файлы

- `index.html` — single-page, lang=en. Heading: "Pavlo Kozub — Engineering cloud platforms at scale". Тёмная/светлая тема через CSS variables + theme override через query param/localStorage. Шрифты — Google Fonts (Fraunces, Newsreader, JetBrains Mono)
- `cv.pdf` — публичный CV (1-page вероятно). Источник — в `~/projects/persononomo/assistant/devops-side-job/variants/`. **Этот PDF — копия для публикации**, обновляется когда меняется source

## Workflow

1. Правишь содержимое — в `index.html` (HTML/CSS inline) или регенерируешь `cv.pdf` из `devops-side-job/`
2. Деплой — TBD (предположительно GitHub Pages / Vercel / Netlify на `kozub.dev`. Уточнить когда нужно пушить)

## Связанное

- `~/projects/persononomo/assistant/devops-side-job/` — markdown source CV → PDF, отсюда копируется в kozub-dev
- Pavlo's day job — DevOps/SRE; этот сайт = публичная карточка для recruiters / клиентов

## Working Conventions

- HTML и CSS — inline в `index.html` (одностраничник, не разбивать в отдельные файлы без необходимости)
- Шрифты Google Fonts: preconnect → preload в head — сохранять для performance
- **Sensitive:** контакты в CV/landing — публичные (email pavlo.kozub@gmail.com уже в global CLAUDE.md). Других секретов нет.
- Перед коммитом/деплоем — проверить рендеринг в light + dark, проверить mobile viewport

## TODO

- [ ] Уточнить где хостится (домен, провайдер) — добавить в этот файл деплой-команду
- [ ] Если есть analytics / contact form — задокументировать
- [ ] При смене вакансии / роли — синхронизировать с `devops-side-job/variants/`
