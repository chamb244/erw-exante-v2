#!/usr/bin/env bash
# Build docs/erw-cdr-calculations.tex + .pdf from docs/erw-cdr-calculations.md.
#
# The Markdown file is the canonical source of truth — edit the .md, not the
# .tex (regenerated each run). Dependencies: pandoc, xelatex, pdfinfo (poppler).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

MD="erw-cdr-calculations.md"
TEX="erw-cdr-calculations.tex"
PDF="erw-cdr-calculations.pdf"

[[ -f "$MD" ]] || { echo "error: $MD not found in $HERE" >&2; exit 1; }

echo "==> pandoc: $MD -> $TEX"
pandoc -f markdown -t latex "$MD" \
  -o "$TEX" \
  --standalone \
  --toc \
  --pdf-engine=xelatex \
  --top-level-division=section \
  -V documentclass=article \
  -V fontsize=11pt \
  -V geometry:margin=2.3cm \
  -V colorlinks=true \
  -V linkcolor=NavyBlue \
  -V urlcolor=NavyBlue \
  -V toccolor=NavyBlue \
  -V mainfont="Helvetica Neue" \
  -V monofont="Menlo" \
  -V title="Carbon Dioxide Removal --- Technical Derivation" \
  -V subtitle="Per-pixel CDR calculation in the ex-ante ERW pipeline, with sourced mechanisms and constants" \
  -V date="$(date +%Y-%m-%d)" \
  --include-in-header="erw-model-header.tex"

echo "==> xelatex pass 1"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null
echo "==> xelatex pass 2"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null

rm -f erw-cdr-calculations.aux erw-cdr-calculations.log erw-cdr-calculations.out erw-cdr-calculations.toc

pages=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ {print $2}')
size=$(du -h "$PDF" | cut -f1)
echo "==> wrote $PDF (${pages:-?} pages, $size)"
