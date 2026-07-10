#!/usr/bin/env bash
# Build docs/erw-cdr-calculations.pdf from the hand-authored
# docs/erw-cdr-calculations.tex (Bisrat house style: book class, apacite
# APA citations against docs/references.bib).
#
# The .tex is now the canonical source of truth and is edited by hand —
# it is NO LONGER regenerated from the .md by pandoc. Citations come from
# references.bib, so the build runs xelatex -> bibtex -> xelatex -> xelatex.
# Dependencies: xelatex, bibtex, pdfinfo (poppler). xelatex is required for
# the inline Unicode (CO2 subscripts, degree/micro signs, arrows, charges).
#
# The previous pandoc-from-Markdown recipe is preserved at the bottom of
# this file, commented out, in case the .md workflow is ever restored.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

TEX="erw-cdr-calculations.tex"
PDF="erw-cdr-calculations.pdf"
STEM="erw-cdr-calculations"

[[ -f "$TEX" ]] || { echo "error: $TEX not found in $HERE" >&2; exit 1; }

echo "==> xelatex pass 1"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null
echo "==> bibtex";        bibtex "$STEM" > /dev/null
echo "==> xelatex pass 2"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null
echo "==> xelatex pass 3"; xelatex -interaction=nonstopmode -halt-on-error "$TEX" > /dev/null

rm -f "$STEM".aux "$STEM".log "$STEM".out "$STEM".toc "$STEM".lot \
      "$STEM".bbl "$STEM".blg

pages=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ {print $2}')
size=$(du -h "$PDF" | cut -f1)
echo "==> wrote $PDF (${pages:-?} pages, $size)"

# ------------------------------------------------------------------
# Former recipe — regenerated the .tex from erw-cdr-calculations.md via
# pandoc. Kept for reference; do not run alongside the hand-authored .tex,
# it will overwrite it.
#
# pandoc -f markdown -t latex erw-cdr-calculations.md \
#   -o "$TEX" --standalone --toc --pdf-engine=xelatex \
#   --top-level-division=section \
#   -V documentclass=article -V fontsize=11pt -V geometry:margin=2.3cm \
#   -V colorlinks=true -V linkcolor=NavyBlue -V urlcolor=NavyBlue \
#   -V toccolor=NavyBlue -V mainfont="Helvetica Neue" -V monofont="Menlo" \
#   -V title="Carbon Dioxide Removal --- Technical Derivation" \
#   -V subtitle="Per-pixel CDR calculation in the ex-ante ERW pipeline, with sourced mechanisms and constants" \
#   -V date="$(date +%Y-%m-%d)" \
#   --include-in-header="erw-model-header.tex"
# ------------------------------------------------------------------
