# Interactive explorers

Two ways to explore how the return envelopes respond to the model's parameter
assumptions. Same math; different delivery.

## `public_envelope_explorer.html` — zero-install, open in any browser

A **single self-contained HTML file** (~2.2 MB): the primitives are baked in as a
quantised, base64-embedded binary blob, and a small JS engine recomputes the
envelopes and redraws the map on every slider move. No Python, no server, no network
— double-click it, or host it anywhere static. This is the version to hand to a
coauthor or an investor.

Sliders for allocation, carbon price, MRV, delivered cost, CDR rate (on gross
removal), net-export λ, yield, and solar haulage, plus Central / Conservative /
Optimistic / 2×-CDR presets and a light/dark toggle. Also:

- **Show: Private / Public / Both.** Private and Public draw a single envelope in one
  colour (everything where that stream alone covers the cost); Both draws the full
  five-way typology (intersection, private-only, public-only, combined-only, neither).
- **National boundaries (GADM level 0)** as a toggleable overlay.
- **By-country table** that re-aggregates to the shown envelope on every change —
  deployable Mha and durable Mt CO₂ per country, sorted, with a total.

Displayed areas are on a 2×-aggregated grid for size and speed and track the canonical
`erw-12` numbers to ~2–3% (the file states the fine-resolution figures).

**Regenerate** it from the current rasters. The country IDs and boundaries come from
[`../analysis/build_explorer_geo.R`](../analysis/build_explorer_geo.R) (run once; needs
`data/gadm_ssa.gpkg`), then
[`../analysis/build_explorer_html.py`](../analysis/build_explorer_html.py) bakes
everything into the HTML from
[`../analysis/explorer_template.html`](../analysis/explorer_template.html):

```bash
Rscript paper/analysis/build_explorer_geo.R           # -> data/country_id_grid.tif, explorer_gadm0.geojson, codes
ERW_ROOT=$(pwd) python3 paper/analysis/build_explorer_html.py
```

## `public_envelope_explorer.ipynb` — full resolution, in Jupyter

Slider-driven exploration of how the private / public / intersection / combined
return envelopes remap under the model's economic and CDR parameter assumptions,
on the headline equilibrium net-export basis.

Backed by [`../analysis/erw_envelope_primitives.py`](../analysis/erw_envelope_primitives.py),
which builds the five separable per-pixel primitives (`AGRO`, `BAS`, `GROSS`, `LCA`,
`S`) once per allocation from the `data/economics_erw` rasters. Every slider move is a
closed-form re-evaluation — no model re-run. The math matches
[`../../erw/erw-12-public-envelope-sensitivity.R`](../../erw/erw-12-public-envelope-sensitivity.R)
and is validated against it (central case reproduces the paper's 1.65 / 3.16 Mha
public envelope for targeted / uniform-20).

### Run

```bash
# from the repo root
python3 -m venv .venv && source .venv/bin/activate
pip install rasterio numpy matplotlib ipywidgets jupyterlab
ERW_ROOT=$(pwd) jupyter lab paper/notebooks/public_envelope_explorer.ipynb
```

Run all cells; the last cell shows the slider panel and a live map. `ERW_ROOT` only
needs setting if you launch Jupyter from somewhere other than the repo root (the
notebook falls back to two levels up from `paper/notebooks/`).

### Levers

carbon price, MRV cost, delivered-cost ×, CDR-rate × (on **gross** removal),
net-export λ, yield ×, and a solar-haulage transport cut. The CDR-rate slider scales
gross removal before the acidity-sink deduction — the physically correct order, which
`erw_provisional_engine`'s stored net-CDR band cannot do, which is why this module
exists separately.

### Requires

The committed `data/economics_erw/{alloc}/{crop}_equilibrium.tif` rasters plus
`data/grid_CI_kg_per_kWh.tif`, `data/basalt_transport_km.tif`,
`data/basalt_transport_cost_usd_t.tif`, and the regime acidity sink
(`data/caco3_merlos_maintenance.tif`). All are produced by the R pipeline
(`erw-7`, `erw-energy-country`, `erw-basalt-access`, `erw-3`).
