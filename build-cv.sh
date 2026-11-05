#!/usr/bin/env bash
# Build cv.pdf from cv-en.md (pandoc + typst).
# Source of truth: ./cv-en.md in this repo.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PANDOC_VARS=(
  -V papersize=a4
  -V mainfont="Helvetica Neue"
  -V fontsize=9pt
  -V margin-top=1.4cm
  -V margin-bottom=1.4cm
  -V margin-left=1.6cm
  -V margin-right=1.6cm
)

pandoc cv-en.md -f markdown+hard_line_breaks -o cv.pdf --pdf-engine=typst "${PANDOC_VARS[@]}"

pages=$(pdfinfo cv.pdf 2>/dev/null | awk '/^Pages:/ {print $2}')
echo "✓ cv.pdf  (${pages} pages)"
