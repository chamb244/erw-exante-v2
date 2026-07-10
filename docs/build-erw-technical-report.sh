#!/usr/bin/env bash
# Build docs/erw-technical-report.pdf from the hand-authored
# docs/erw-technical-report.tex (Bisrat house style: book class, apacite APA
# citations against docs/references.bib).
#
# The .tex is the canonical source of truth and is edited by hand.
# xelatex is required for inline Unicode (micro sign, degree, arrows).
# Build sequence: xelatex -> bibtex -> xelatex -> xelatex.
# Dependencies: xelatex, bibtex, pdfinfo (poppler).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

TEX="erw-technical-report.tex"
PDF="erw-technical-report.pdf"
STEM="erw-technical-report"

[[ -f "$TEX" ]] || { echo "error: $TEX not found in $HERE" >&2; exit 1; }

echo "==> xelatex pass 1"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null
echo "==> bibtex";        bibtex "$STEM" > /dev/null
echo "==> xelatex pass 2"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null
echo "==> xelatex pass 3"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null

rm -f "$STEM".aux "$STEM".log "$STEM".out "$STEM".toc "$STEM".lof "$STEM".lot \
      "$STEM".bbl "$STEM".blg

pages=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ {print $2}')
size=$(du -h "$PDF" | cut -f1)
echo "==> wrote $PDF (${pages:-?} pages, $size)"
