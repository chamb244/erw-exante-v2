# Interactive notebooks

## `public_envelope_explorer.ipynb`

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
