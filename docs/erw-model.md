# Ex-Ante ERW Model — Living Documentation

**Geospatial profitability model for Enhanced Rock Weathering with basalt in Sub-Saharan Africa.**
This document is the single source of truth for the *current* state of the model. Update it whenever
anything material changes — the **Status at a glance** section, the **Changelog**, the affected block
under §6, and the affected output under §7.

Companion documents that this file points to (do not duplicate):

| File | Purpose |
|---|---|
| `docs/erw-review.md` | Evidence review (literature on ERW chemistry, feedstocks, trials, agronomy, risks). |
| `docs/erw-parameters.md` | Catalogue of every constant and assumption with citations and units. |
| `docs/erw-README.md` | Runbook: file inventory, run order, output schema, known portability issues. |
| `docs/erw-conceptual-framework.{svg,pdf,tex}` | Scientific framework figure — three streams converging on the gross-margin equation. |
| `docs/erw-pipeline-flow.{svg,pdf,tex}` | Pipeline architecture figure — how the code implements the framework. |
| `docs/maps/*.png` | Rendered indicator and outcome maps (12 currently). |
| `flows.html` | Browser-rendered view of this whole thing. |

---

## 0. Status at a glance

**Last updated:** 2026-09-01
**Geographic scope:** Sub-Saharan Africa, 47 countries, GADM v4 boundaries
**Working grid:** SoilGrids-Africa 30 arc-sec aggregated 10× → ~0.083° (≈9 km) — 746 × 828 cells
**Currency:** USD; **CO₂ in tonnes; year-1 / NPV @ 10% / equilibrium regimes**
**Defaults (refreshed 2026-09-01):** grain size **50 µm**, MRV **\$20 / tCO₂** (Mercer et al. 2024 EW MRV range \$15–71), temperature factor **Arrhenius** (Ea = 68.8 kJ/mol, White & Blum 1995; normalized to 1 at Tᵣₑf = 11 °C, clamped [0.3, 3.0]; linear MAT/Tᵣₑf retained as sensitivity variant), pH factor **triangular peak at 6.0**, year-1 agronomic return **summed over 5-yr basalt residency**, pedogenic deduction via **CGIAR-CSI Global Aridity Index**, EcoCrop max-pH cliff **per-crop optima (5.5–8.0)**.

### Pipeline-block status

| Block | Stage(s) | Status | Notes |
|---|---|---|---|
| B1. Working grid | `erw-1`, `erw-2` | **REAL** | SoilGrids properties + SPAM v2 (23 crops) co-registered on the 10× grid |
| B2. Basalt rate | `erw-3` | **REAL** | LiTAS / Kamprath / Cochrane / maintenance + uniform 10/20/50 t·ha⁻¹ |
| B3. CDR surface | `erw-9` | **REAL** (refreshed 2026-09-01) | Arrhenius temperature factor (Ea = 68.8 kJ/mol) × moisture × pH peak-6.0 × pedogenic-C deduction; CGIAR-CSI AI when present (else MAP fallback); 50 µm grain default; mean cumulative CDR under LiTAS-targeted 4.4 t CO₂/ha gross, 3.3 t/ha net-export. |
| B4. Logistics | `erw-basalt-access` | **REAL** (since 2026-05-15) | Friction surface fetched, mask expanded to vb+pb, end-to-end delivered price computed |
| B5. Energy | `erw-energy-country` | **REAL** | Country tariff + grid CI rasters |
| B6. Crop response — EcoCrop | `erw-4`, `erw-5` | **REAL** (refreshed 2026-05-26) | Per-crop max_ph cliffs (5.5 tea → 8.0 chickpea, was flat 5.5); all 23 crops × 2 responses |
| B6. Crop response — Bayesian | `erw-yield-fit`, `erw-yield-predict` | **NOT RUN** | Trial-anchored brms model not fit; erw-7 falls back to EcoCrop |
| B7. Profitability | `erw-7` | **REAL** (refreshed 2026-09-01) | 276 gross-margin rasters regenerated on the Arrhenius + pH-6.0 basis; year-1 regime sums agronomic return over 5-yr horizon; MRV $20 |
| B8. Supply ranking | `erw-supply` | **REAL** (refreshed 2026-09-01) | Three supply curves + nine deployment masks; year-1 peak GM \$16.2B @ 250 Mt/yr; NPV peak \$3.9B @ 100 Mt/yr; equilibrium peak \$3.0B @ 50 Mt/yr |
| B9. Sensitivity | `erw-8` | **REAL** (run 2026-09-01) | Full default-scope sweep at the new defaults; yield-uplift sweep capped at 1.8× (was 2.5×) per the 1.7× field-trial envelope |

### Headline numbers (current run)

| Metric | Value | Source raster / table |
|---|---|---|
| Mafic source pixels (vb+pb in SSA) | **1,399,005** (1.9 % of SSA cropland-context cells) | `basalt_source_mask.tif` |
| Mean delivered basalt price | **$40.8 / t** (range $10 – $50, cap binds for ~half of pixels) | `basalt_delivered_price_usd_t.tif` |
| Mean travel time to source | **815 min** (capped at 1000 min ≈ 1000 km @ 60 km/h) | `basalt_traveltime_min.tif` |
| Delivered basalt incl. grinding + spreading | **~$53 / t mean** (slightly higher than 100 µm due to grinding cost +$1/t) | `erw-7` setup print |
| Per-tonne CDR at reference climate | **88 kg CO₂ / t basalt** (was 62 at 100 µm) | `basalt_feedstock_chemistry.csv` |
| Mean cumulative CDR (LiTAS-targeted, TAS=0) | **4.45 t CO₂ / ha gross; 3.30 t/ha net-export** (Arrhenius + pH-6.0 basis) | `cdr_yield_merlos.tif`, `cdr_yield_merlos_netexport.tif` |
| Top crop by total GM (targeted) | **Common bean: +\$4.9 B year-1, +\$1.0 B equilibrium** (then groundnut, potato) | `docs/tables/output-crop-ranking.csv` |
| Crops with positive total GM, targeted | **Year-1 13/23; NPV 4/23; Equilibrium 14/23** | `docs/tables/output-crop-ranking.csv` |
| Break-even supply cap (year-1) | **≈250 Mt basalt / yr** (marginal pixel +\$5 / t) | `supply_curve_year1.csv` |
| Break-even supply cap (NPV) | **≈100 Mt basalt / yr** (marginal pixel +\$4 / t) | `supply_curve_npv.csv` |
| Break-even supply cap (equilibrium) | **between 50 and 100 Mt / yr** (slips +\$18 / t → −\$16 / t) | `supply_curve_equilibrium.csv` |
| Peak total gross margin (year-1) | **\$16.2 B at 250 Mt/yr cap** with 68.4 Mt CDR/yr | `supply_curve_year1.csv` |
| Peak total gross margin (NPV) | **\$3.9 B at 100 Mt/yr cap** with 28.6 Mt CDR/yr | `supply_curve_npv.csv` |
| Peak total gross margin (equilibrium) | **\$3.0 B at 50 Mt/yr cap** with 13.7 Mt CDR/yr | `supply_curve_equilibrium.csv` |
| Unconstrained SSA capacity (targeted) | **443 Mt basalt/yr** (year-1, NPV) / **145 Mt/yr** (equilibrium maintenance) | `supply_curve_*.csv` (row `Inf`) |
| Deployment envelopes (targeted, equilibrium net-export, \$150/tCO₂, \$20 MRV) | **Private 4.31 / public 1.95 / intersection 1.32 / combined 7.61 Mha** | `docs/tables/output-envelope-summary.csv` |
| Uniform-20 public envelope | **3.95 Mha, 20.4 Mt durable CDR** at \$150/tCO₂ | `docs/tables/output-envelope-summary.csv`, `output-public-mac-price-ladder.csv` |
| Area-weighted median MAC (equilibrium net-export) | **\$276/tCO₂ uniform-20; \$330 targeted** | `docs/tables/output-public-mac-price-ladder.csv` |
| Robust priority tiers (targeted) | **Core (≥50 % of the 180-point robustness grid) 0.65 Mha; candidate (≥33 %) 1.22 Mha** | `docs/tables/output-core-priority-summary.csv` |

### Supply curves at a glance — marginal $/t basalt vs annual cap (refreshed 2026-09-01)

| Regime | 1 Mt | 5 Mt | 10 Mt | 25 Mt | 50 Mt | **100 Mt** | **250 Mt** | 500 Mt | Peak total GM (M$) | Peak CDR (Mt) |
|---|---|---|---|---|---|---|---|---|---|---|
| year-1 | +279 | +203 | +173 | +133 | +104 | +66 | **+5** | −60 | **16,241 (@250 Mt)** | 68.4 |
| NPV @ 10 % | +108 | +92 | +76 | +57 | +34 | **+4** | −27 | −64 | **3,894 (@100 Mt)** | 28.6 |
| equilibrium | +196 | +122 | +89 | +44 | **+18** | −16 | −61 | −61 | **3,008 (@50 Mt)** | 13.7 |

Values are the marginal pixel's GM per tonne basalt at each supply cap; bold columns flag
the most profitable supply level for each regime. The year-1 regime peaks at the 250 Mt/yr
cap thanks to the horizon-summed agronomic return; the equilibrium peak has moved down to the
50 Mt/yr cap (marginal GM slips negative between 50 and 100 Mt/yr on the Arrhenius + pH-6.0
net-export basis). Equilibrium saturates at 145 Mt/yr (the targeted-deployable-cropland
ceiling at maintenance rate).

---

## 1. Changelog

Reverse chronological. One bullet per material change. Reference the block(s) affected so it
is obvious which section under §6 also moved.

### 2026-09-01 — ESROC-anchored citation review; Arrhenius temperature factor; pH peak → 6.0; full B3 / B7 / B8 / B9 re-run

Outcome of the ESROC-anchored citation review (`litrature/citation-review.md`) —
every load-bearing citation was checked against the published record and the
two v1 empirical proxies in the climate factor were re-anchored to the
literature-supported forms:

- **B3 temperature factor** `erw/erw-9-cdr-yield.R` §3: the headline form is
  now **Arrhenius**, $\exp(-(E_a/R)(1/T - 1/T_{\mathrm{ref}}))$ with
  Ea = **68.8 kJ/mol** (White & Blum 1995 GCA), normalized to 1 at
  Tᵣₑf = 11 °C and clamped to [0.3, 3.0]. The former linear MAT/Tᵣₑf is
  retained as a conservative sensitivity variant. Area-weighted, Arrhenius
  raises SSA gross CDR ~27 % (capped) over linear.
- **B3 pH factor** `erw/erw-9-cdr-yield.R` §3: triangular peak moved
  **5.0 → 6.0** (floor 0.5 below pH 4 and above pH 8; linear 0.5→1.0 over
  4–6; 1.0→0.5 over 6–8). Rationale: the factor is the product of
  acid-catalysed dissolution kinetics (rising below pH ~5.5; Palandri &
  Kharaka 2004, Bandstra & Brantley 2008) and the **carbon-capture efficiency
  of the generated alkalinity, which collapses below pH 5** (Bertagni &
  Porporato 2022; Holden et al. 2024; Power et al. 2025) — the product peaks
  between the pH-5 capture-collapse threshold and carbonic-acid pKa₁ = 6.35.
  See `litrature/citation-review.md` #4.1.
- **B9 yield sweep** `erw/erw-8-sensitivity-analysis.R`: yield-uplift sweep
  capped at **1.8×** (was 2.5×), per the 1.7× field-trial envelope.
- **B7 MRV citation**: the \$20/tCO₂ default is re-anchored to
  **Mercer et al. 2024** (LSE Grantham Research Institute; EW MRV
  \$15–71/tCO₂). The prior attribution to Levy 2024 was a misattribution
  and has been removed.
- **B4 friction-surface citation**: corrected to **Weiss et al. 2020**
  (*Nature Medicine*), the actual source of the MAP 2019 motorised friction
  surface (was cited as Weiss 2018).
- **Full re-run**: `erw-9` → `erw-7` (276 rasters) → `erw-10` → `erw-11` →
  `erw-12` + `erw-supply` + `erw-8`, all outputs, maps and
  `docs/tables/*.csv` regenerated 2026-09-01. The `erw-12` §0 accounting
  check passes: on-disk rasters carry net-export (residual 4.7e-7).
- **Pedogenic ∩ acidity overlap check**: pixels that are both arid (pedogenic
  deduction) and acid (acidity-sink deduction) are **1.28 % of pixels**; the
  sequential ordering over-deducts F·S·p there. Conservative, documented,
  not restructured.

**Headline effect:** on the Arrhenius + pH-6.0 net-export basis, the
supply peaks move to **year-1 \$16.2 B at the 250 Mt/yr cap**, **NPV
\$3.9 B at 100 Mt/yr**, and **equilibrium \$3.0 B at 50 Mt/yr** (the
equilibrium marginal pixel now slips negative between 50 and 100 Mt/yr).
The equilibrium net-export deployment envelopes (targeted, \$150/tCO₂,
\$20 MRV) are **private 4.31 / public 1.95 / intersection 1.32 /
combined 7.61 Mha**; the uniform-20 public envelope is **3.95 Mha with
20.4 Mt durable CDR**; area-weighted median MAC is **\$276/tCO₂
(uniform-20) / \$330 (targeted)**; the robust core tier is **0.65 Mha**
and the candidate tier **1.22 Mha**. See §0 status, §6 blocks and §7
outputs for the refreshed numbers.

### 2026-05-26 — Round-1 conservatism review; five defaults re-anchored; B3 / B6 / B7 / B8 re-run

Outcome of a structural review of the model's conservatism (see also the
"Why we were under-estimating profit" review below in §8). Five fixes
landed, all backed by the parameter audit and the cited literature:

- **B2 / B3 grain size** `erw/erw-3-basalt-requirements.R`: `grain_size_um`
  100 → **50 µm** (Strefler 2018 grinding-curve anchor). Per-tonne CDR at
  the reference climate rose from 62 → **88 kg CO₂ / t basalt**; effective
  NV from 0.0704 → 0.10; basalt-to-lime ratio from 14.20 → 10.04 t/t.
- **B6 EcoCrop max-pH cliff** `erw/erw-4-crop-parameters.R`: was a
  hard-coded flat 5.5 for every crop; now per-crop EcoCrop optima
  (5.5 tea / 6.0 cocoa / 6.5 acid-loving / 7.0–8.0 cereals & legumes).
  This unlocks non-zero agronomic credit across the pH 5.5–7.0 belt
  covering most SSA savanna / Sahel cropland; previously the model
  returned exactly zero agronomic uplift on those pixels.
- **B7 year-1 regime** `erw/erw-7-profitability-function.R`: agronomic
  return now scaled by `PROJECT_HORIZON_YR` (5 yr) to put it on the same
  cumulative basis as `cdr_tha`. Prior behaviour silently credited a
  single season of agronomy against five years of CDR — a unit
  mismatch dragging year-1 GM artificially negative.
- **B7 MRV cost** `erw/erw-7-profitability-function.R`: `MRV_COST_USD_T_CO2`
  30 → **20 \$/tCO₂**. Midpoint of Levy et al. 2024 first-of-kind pilot
  benchmark and the at-scale aggregator-pooled forecast.
- **B3 pedogenic deduction** `erw/erw-9-cdr-yield.R`: now consumes the
  CGIAR-CSI Global Aridity Index (Zomer et al. 2022, `ai_v31_yr.tif` or
  `cgiar_aridity_index.tif`) when present; with 65535-as-nodata masking
  and auto-detected integer scaling. Falls back to the MAP-only proxy
  otherwise. The CGIAR path relieves cool highlands (Ethiopia, Kenya,
  Rwanda, Burundi) where the MAP proxy over-deducted.

**Headline effect:** under LiTAS-targeted allocation, the number of
crops with positive pixel-mean gross margin rose from **1 → 12** in
year-1, **0 → 8** in NPV, and **1 → 19** in equilibrium. Year-1 supply
peak total GM rose from **\$2.0 B → \$19.6 B** (at the 250 Mt/yr cap).
The deep-tail picture also became more honest: NPV at unconstrained
deployment is now −\$1.1 B (was −\$9.8 B), still net-negative but no
longer catastrophic. See §0 status, §6 block descriptions, and §7
outputs for the refreshed numbers.

### 2026-05-19 — B7 / B8 first end-to-end run; B6 + B3 refreshed; B9 patched

- **B7** First end-to-end run of `erw/erw-7-profitability-function.R`. Wrote 276 gross-margin
  rasters: `data/economics_erw/{targeted,uniform_10,uniform_20,uniform_50}/{crop}_{year1,npv,equilibrium}.tif`.
  Mean delivered basalt cost $52 / t (range $18 – $61); mean LCA 52.8 kg CO₂ / t basalt.
  Pixel-mean gross margin is negative everywhere except **equilibrium / targeted / WHEA** at
  **+$57 / ha** — basalt cost ($1.3 – $2.7 k / ha at the LiTAS rate) swamps the carbon credit
  and agronomic uplift at the pixel mean.
- **B8** First end-to-end run of `erw/erw-supply.R`. Wrote three supply curves and nine
  deployment masks. Break-even marginal pixel sits at **≈100 Mt / yr** for year-1 and NPV,
  **≈50 Mt / yr** for equilibrium. Peak total gross margin **$3.8 B** at the 100 Mt/yr NPV
  cap with 22.7 Mt CDR/yr. The model finds **profitable top-decile pixels** even though
  the SSA-wide mean is negative.
- **Fix** `erw/erw-7-profitability-function.R:114–117, 134–137`: removed redundant
  `terra::aggregate(..., 10, ...)` on `electricity_usd_kWh.tif`, `grid_CI_kg_per_kWh.tif`,
  `basalt_transport_cost_usd_t.tif`, `basalt_transport_km.tif`. Those four are already at the
  working 0.0833° grid; the extra factor-10 aggregation collapsed them to 0.833° on a
  slightly shifted extent and threw `extents do not match` on the first crop of the main loop.
- **Fix** `erw/erw-8-sensitivity-analysis.R:166–174`: grain sweep referenced scalar
  `ELECTRICITY_USD_KWH` / `GRID_CI_KG_PER_KWH`, which do not exist in `erw-7` (the
  per-pixel rasters are `electricity_raster` / `grid_ci_raster`, the fallback constants are
  the `*_FB` suffixed). Rewired both the cost-side and LCA-side grinding swap to use the
  per-pixel rasters. Script not run end-to-end yet — default-scope sweep is ≈6–8 h wall time
  (≈14k `profit()` calls).
- **B6 (EcoCrop)** Re-ran `erw/erw-5-crop-yield-loss-function.R` after the user populated
  `data/ecocrop_parameters_hp.csv` with all 23 crops (previously only MAIZ + SORG had
  `ac_sat` / `max_ac_sat` rows). Now 46 rasters under `data/ecocrop_f/` — `hp_*` and `ph_*`
  for each of the 23 crops.
- **B3** Re-ran `erw/erw-9-cdr-yield.R`. The previous `cdr_yield_*.tif` files predated the
  latest `basalt_*.tif` write (16:50 vs 18:00 on 2026-05-13), so layers 5–9 of
  `cdr_yield_merlos.tif` (the LiTAS variants with `ac_sat ≥ 20`, i.e. most crops) were
  silently all zero. Refreshed against the latest basalt rasters; mean CDR yield now non-zero
  on every layer (e.g. `merlos_20` mean 1.38 t CO₂ / ha). Downloaded WorldClim v2 tavg + prec
  to `data/worldclim/`.

### 2026-05-15 — B4 logistics first end-to-end run; feedstock filter extended

- **B4** Fetched MAP motorised friction surface (2019), 72.5 MB SSA-clipped, via
  `malariaAtlas::getRaster(dataset_id = "Explorer__2020_motorized_friction_surface")`.
  Wrote `data/access/friction_surface_2019.tif`.
- **B4** Ran `erw/erw-basalt-access.R` end-to-end. Mean delivered price $40.8 / t, mean travel
  time 815 min. Outputs: `basalt_traveltime_min.tif`, `basalt_transport_km.tif`,
  `basalt_transport_cost_usd_t.tif`, `basalt_delivered_price_usd_t.tif`.
- **Fix** `erw/erw-basalt-access.R:127`: original call passed the basalt mask as `target=` to
  `terra::costDist`; `target` must be the *value* in `x` that marks sources, not a separate
  raster. Now writes a sentinel −1 into a copy of `friction` at source cells and calls
  `costDist(friction_src, target = -1)`.
- **Fix** `malariaAtlas` 1.6.0 deprecated the `surface=` argument of `getRaster()`; new
  helper `erw/erw-fetch-friction-surface.R` resolves the `dataset_id` from `listRaster()`,
  forces `EPSG:4326`, and converts SSA to `sf` (the package's internal `vect()` dispatch
  does not accept `SpatVector`).
- **B2 feedstock** Extended GLiM filter from `c('vb')` to `c('vb', 'py', 'pb')` in both
  `erw/erw-build-basalt-mask.R` and `erw/erw-basalt-access.R`. SSA polygons 5,266 → 6,455;
  source-mask cells 1,321,857 → 1,399,005. New categorical raster
  `data/basalt_source_class.tif` (1 = basalt s.s., 3 = gabbro; pyroclastics absent in SSA at
  GLiM v1 resolution).
- **Maps** Added `docs/maps/10-basalt-traveltime.png`, `11-basalt-delivered-price.png`,
  `12-feedstock-class.png`. Refreshed `09-basalt-sources.png`. Gallery now 12 maps.

### 2026-05-14 — Conceptual framework + pipeline figures

- **Docs** TikZ-rendered figures: `docs/erw-pipeline-flow.{tex,pdf,svg,png}` (code architecture)
  and `docs/erw-conceptual-framework.{tex,pdf,svg,png}` (scientific framework).
- **Docs** `flows.html` now embeds both figures + 9-map gallery (later expanded to 12).
- **Pipeline figure** Rewrote arrows with full orthogonal routing — one horizontal track per
  arrow, no co-linear overlap, all corners 90°. Widened erw-7 box so all six surfaces drop
  straight down; FAOSTAT wraps around the right edge.
- **B4 sub-mask** Built `data/basalt_source_mask.tif` from `data/LiMW_GIS 2015.gdb` via
  `erw/erw-build-basalt-mask.R` (the script had been writing an empty stub). Reprojection
  Eckert IV → WGS84 lat/lon was the unblocker.

---

## 2. Scope and units

- **Geographic extent**: 47 Sub-Saharan African countries per GADM v4, clipped to the union
  of GADM country polygons. Northern boundary at the southern edge of the Sahara
  (excludes Morocco, Algeria, Tunisia, Libya, Egypt). Madagascar included.
- **Working resolution**: ~0.083° ≈ 9 km at the equator. This is the SoilGrids-Africa
  30 arc-sec grid aggregated 10× by mean. All rasters downstream of `erw-1` are co-registered
  on this grid.
- **Crop coverage**: 23 SPAM crops — `ACOF BARL BEAN CASS CHIC COCO COTT COWP GROU LENT
  MAIZ PIGE PMIL POTA RCOF SMIL SORG SOYB SUGC SWPO TEAS TOBA WHEA` (SPAM 2017-SSA codes,
  as in `docs/tables/output-crop-ranking.csv`).
- **Temporal regimes**: year-1, NPV at 10% over 10 years, equilibrium (saturating CDR).
  CDR phasing 30 / 25 / 20 / 15 / 10 % over five years (Lewis 2021).
- **Currency**: USD throughout. Prices from FAOSTAT 2016–2020 producer-price averages,
  industrial-electricity tariffs from IEA / Ember / GET.invest (2022–2024).

---

## 3. Scientific framework

See `docs/erw-conceptual-framework.svg` for the figure. In words:

Three causal streams converge on a per-pixel gross margin

$$\pi(x, y \mid \text{regime}, \text{allocation}) \;=\; R_{\mathrm{CDR}}(x,y) + R_{\mathrm{agro}}(x,y) - C(x,y).$$

### 3.1 Biogeochemical stream → $R_{\mathrm{CDR}}$

`feedstock × grain size → reactive surface → climate × pH dissolution kinetics
→ net alkalinity export (minus pedogenic-C precipitation) → carbon revenue`

- Feedstock chemistry sets CaO + MgO mass fractions (default 10% + 7% by mass).
- Grain size sets specific surface area; the SSA exponent and Strefler-2018 grinding-energy
  exponent are the two grain-size dials.
- Dissolution rate is the temperature × moisture climate factor — an **Arrhenius**
  temperature term (Ea = 68.8 kJ/mol, White & Blum 1995; normalized to 1 at
  Tᵣₑf = 11 °C, clamped [0.3, 3.0]) times a moisture term MAP/Pᵣₑf (Pᵣₑf = 1000 mm) —
  times a **triangular pH term peaked at pH 6.0**. The pH term is the product of two
  opposing mechanisms: acid-catalysed dissolution kinetics rise with acidity below
  pH ~5.5, while the carbon-capture efficiency of the generated alkalinity collapses
  below pH 5 (Bertagni & Porporato 2022; Holden et al. 2024; Power et al. 2025);
  their product peaks between the pH-5 threshold and carbonic-acid pKa₁ = 6.35.
- The pedogenic-C deduction (UNEP 1992 aridity bands keyed on MAP) removes alkalinity that
  precipitates locally instead of exporting as ocean HCO₃⁻.
- Carbon revenue: $R_{\mathrm{CDR}} = \mathrm{CDR}_t \times (p_{\mathrm{CO}_2} - \mathrm{MRV})$.

### 3.2 Agronomic stream → $R_{\mathrm{agro}}$

`soil acidity constraint → lime-equivalent demand → basalt application rate
→ crop response → yield revenue`

- Soil acidity (pH, exchangeable acidity, Al saturation, ECEC) drives the lime-equivalent
  demand via `limer::limeRate` (Kamprath / Cochrane / Aramburu-Merlos LiTAS / maintenance).
- The lime demand is converted to t basalt ha⁻¹ using the feedstock chemistry, a
  Lewis-2021-calibrated reactive fraction, and the grain-size lever — **this rate is the
  cross-link feeding the biogeochemical stream** (see the dashed arrow in the framework
  figure).
- Crop response per pixel is the maximum of two surfaces:
  - **EcoCrop** Recocrop suitability clamped to [0.2, 1] for pH and acidity-saturation.
  - **Bayesian uplift** posterior medians from a brms model on the trial dataset,
    with covariates (pH, MAT, MAP, grain, crop type).
  When the Bayesian surface is present `erw-7` prefers it; otherwise falls back to EcoCrop.
- Yield revenue: $R_{\mathrm{agro}} = \Delta y(x) \times p_{\mathrm{crop}}$.

### 3.3 Economic-geography stream → $C$

`feedstock supply → logistics → grinding (cost + LCA) → operations → total cost`

- Feedstock supply: quarry-gate fines at $10 / t, anchored on GLiM v1 basic-volcanic,
  pyroclastic, and basic-plutonic source rocks.
- Logistics: cost-distance over the MAP 2019 motorised-friction surface, monetised at
  $0.04 / min / t (30-t truck @ $80 / h). Haul capped at 1000 km.
- Grinding: kWh / t × country industrial-electricity tariff × grid carbon intensity (the
  CI term is the LCA deduction from gross CDR, not a cost).
- Operations: $8 / t spreading + $30 / tCO₂ MRV (sampling + lab + verification + registry).

### 3.4 Decision variables

Six dials are exposed at the framework boundary and propagate inwards:

1. Feedstock chemistry — CaO + MgO mass fractions.
2. Grain size — 10 – 500 µm (default **50 µm**).
3. Allocation rule — LiTAS-targeted vs uniform 10 / 20 / 50 t ha⁻¹.
4. Carbon price — default $150 / tCO₂.
5. MRV cost — default **$20 / tCO₂**.
6. Discount rate — default 10 % (NPV regime only).

---

## 4. Pipeline architecture

See `docs/erw-pipeline-flow.svg` for the figure. In words:

- **Data layer** SoilGrids · SPAM v2 · WorldClim · GLiM + MAP friction · EcoCrop + ERW
  trials · FAOSTAT + IEA/Ember.
- **Working-grid layer** `erw-1`, `erw-2` produce `soilgrids_properties_cropland.tif` and
  `spam_*_processed.tif`; `erw-4` builds the per-crop parameter tables, `erw-5` the
  EcoCrop response surface.
- **Surface layer** Six geospatial surfaces:
  - `erw-3` → basalt rate
  - `erw-9` → CDR yield (per-t and per-ha)
  - `erw-basalt-access` → delivered basalt price
  - `erw-energy-country` → tariff + CI
  - `erw-yield-fit` → posterior fit (Bayesian)
  - `erw-yield-predict` → posterior surfaces (Bayesian)
- **Convergence** `erw-7` decomposed-cost profitability function; six straight drops from
  the surface layer plus FAOSTAT crop prices wrapping in from the right.
- **Output layer** `erw-8` sensitivity sweeps + `erw-supply` deployment frontier
  (LP-dual ranking on $ per tonne basalt).

---

## 5. Data sources

### 5.1 On disk

Located under `data/`. File sizes reflect SSA-clipped rasters at the working resolution.

| File | Size | Source &amp; notes |
|---|---|---|
| `gadm_ssa.gpkg` | ~30 MB | GADM v4 — 47 SSA countries |
| `soilgrids_properties_all.tif` | ~600 MB | SoilGrids-Africa (`geodata::soil_af`); 10 bands: SBD, ph, hp, k, ca, mg, na, bases, ecec, hp_sat |
| `soilgrids_properties_cropland.tif` | ~190 MB | as above, masked to QED cropland; cropland-only working stack |
| `spam_*_processed.tif` (harv_area, prod, yield) | ~70 MB each | SPAM v2 via `geodata::crop_spam`; 23 bands, one per crop |
| `basalt_*.tif` (kamprath, cochrane, merlos, merlos_maintenance) | up to ~270 MB | computed by `erw-3`; t ha⁻¹ at the four LiTAS regimes |
| `basalt_uniform_{10,20,50}.tif` | ~7 MB each | computed by `erw-3`; uniform-rate counterfactuals |
| `cdr_{climate_factor,pedogenic_fraction,per_t_basalt}.tif` | small | computed by `erw-9`; sub-components of CDR |
| `cdr_yield_*.tif` | small | computed by `erw-9`; per-ha cumulative CDR |
| `electricity_usd_kWh.tif`, `grid_CI_kg_per_kWh.tif` | small | computed by `erw-energy-country`; tariff + grid CI |
| `basalt_source_mask.tif` | ~115 kB | binary, vb + pb; built by `erw-build-basalt-mask` then `erw-basalt-access` |
| `basalt_source_class.tif` | ~110 kB | categorical (1 = basalt, 3 = gabbro); built by `erw-build-basalt-mask` |
| `basalt_{traveltime_min, transport_km, transport_cost_usd_t, delivered_price_usd_t}.tif` | ~400 kB each | B4 cost surfaces; computed by `erw-basalt-access` |
| `data/access/friction_surface_2019.tif` | 72.5 MB | MAP motorised friction surface (2019), via `malariaAtlas`, ~30 arc-sec |
| `data/LiMW_GIS 2015.gdb` | ~50 MB | PANGAEA doi:10.1594/PANGAEA.788537 — GLiM v1 global lithology |
| `data/ecocrop_f/{hp,ph}_crop_suitability_*_0.tif` | small | computed by `erw-5`; 23 crops × 2 responses |

### 5.2 External datasets (provenance)

| Dataset | Version | Access | Used by |
|---|---|---|---|
| GADM | v4.1 | `geodata::world()` | erw-1 |
| QED cropland | latest | `geodata::cropland(source='QED')` | erw-1 |
| SoilGrids-Africa | iSDA 30 arc-sec | `geodata::soil_af()` | erw-1 |
| SPAM | v2 (Africa) | `geodata::crop_spam()` | erw-2 |
| EcoCrop parameter set | curated `Recocrop::ecocropPars()` | local CSV | erw-4 |
| WorldClim | v2.1 (MAT, MAP) | `geodata::worldclim_global()` | erw-9, erw-yield-predict |
| GLiM lithology | v1.0 / 1.1 (GDB) | PANGAEA download | erw-basalt-access |
| MAP motorised friction surface | nominal 2019 | `malariaAtlas` (dataset_id `Explorer__2020_motorized_friction_surface`) | erw-basalt-access |
| FAOSTAT producer prices | 2016 – 2020 average | manual CSV download | erw-7, erw-8 |
| Country energy (industrial tariff + grid CI) | 2022 – 2024 | hard-coded CSV in `erw-energy-country.R` | erw-energy-country |
| ERW trial dataset | curated by Bisrat | `erw/erw-trial-data.csv` (~14 rows) | erw-yield-fit |

### 5.3 Not represented (gaps)

- **Industrial alkaline by-products**: steel-slag stockpiles (Saldanha and Vanderbijlpark in
  South Africa, Ajaokuta in Nigeria, Helwan in Egypt — outside SSA but referenced),
  cement-kiln dust at clinker plants, mine tailings at copper/nickel operations. These would
  add 10⁵–10⁶ tonnes / yr of point-source feedstock supply in countries with no basalt
  outcrops (notably much of West Africa).
- **Ultramafic outcrops**: olivine, dunite, peridotite, serpentinite. Intentionally excluded
  for cropland deployment because of Ni / Cr leaching and asbestos risk (see review §3).
- **National geological maps**: some SSA countries (Tanzania, South Africa) have higher-
  resolution geological mapping than GLiM v1. Not currently integrated.

---

## 6. Methodological blocks

Each block is one functional unit of the conceptual framework. The script(s) that implement
it are listed; the **Status** mirrors §0; the **Where to look** column points to the file the
reader edits when the block changes.

### B1. Working grid — `erw-1`, `erw-2` — **REAL**

GADM v4 SSA mask; depth-weighted SoilGrids properties (pH, BD, exch.\ acidity, K, Ca, Mg, Na
bases, ECEC, acidity-saturation); SPAM v2 harvested-area / production / yield for 23 crops
resampled to the 10× working grid. ECEC and acidity-saturation surfaces derived inline.

**Where to look:** `erw/erw-1-layers-soilgrids.R`, `erw/erw-2-layers-spam.R`
(parameters for `erw-1` / `erw-2` are not catalogued in `docs/erw-parameters.md`; see the script headers for the depth-weighting recipe).

### B2. Basalt rate — `erw-3` — **REAL**

Four lime-equivalent CaCO₃ rates (Kamprath, Cochrane, Aramburu-Merlos LiTAS year-1, LiTAS
maintenance) via `limer::limeRate`. Converted to t basalt ha⁻¹ using user-set CaO/MgO mass
fractions (default 10% / 7%), the Lewis-2021-calibrated reactive fraction, and the grain-size
lever. Uniform 10 / 20 / 50 t ha⁻¹ counterfactuals computed in parallel.

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `CaO_frac` | 0.10 | Mass fraction of CaO in feedstock. |
| `MgO_frac` | 0.07 | Mass fraction of MgO in feedstock. |
| `grain_size_um` | **50 µm** | Sweeps 10 – 500 µm in `erw-8`. Default lowered from 100 µm on 2026-05-26 — Strefler grinding-curve anchor, cost-minimising once carbon revenue is credited. |
| `reactive_fraction_ref` | 0.20 | Lewis 2021 calibration at reference grain × climate. |
| `GRAIN_BETA` | 0.5 | Surface-area exponent for the grain-size factor. |
| `GRIND_ALPHA` | 1.2 | Strefler 2018 grinding-energy exponent. |

**Where to look:** `erw/erw-3-basalt-requirements.R`, `docs/erw-parameters.md` §1.

### B3. CDR surface — `erw-9` — **REAL**

Per-tonne CDR potential from CaO/MgO stoichiometry, scaled by a temperature × moisture
climate factor (Arrhenius temperature term, Ea = 68.8 kJ/mol, anchored to Tᵣₑf = 11 °C;
moisture term MAP/Pᵣₑf, Pᵣₑf = 1000 mm) and a triangular pH term peaked at pH 6.0.
An aridity-binned pedogenic-carbonate fraction (UNEP 1992 bands on MAP) removes
alkalinity precipitating locally.

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `T_ref` | 11 °C | Reference MAT anchor (US Corn Belt). |
| `P_ref` | 1000 mm | Reference MAP anchor. |
| `f_MAT` | Arrhenius, Ea = 68.8 kJ/mol | exp(−(Ea/R)(1/T − 1/Tᵣₑf)), normalized to 1 at Tᵣₑf, clamped [0.3, 3.0] (White & Blum 1995). Former linear MAT/Tᵣₑf kept as a conservative sensitivity variant. |
| `f_pH` | triangular peak at pH 6.0 | Floor 0.5 below pH 4 / above pH 8; linear 0.5→1.0 over 4–6, 1.0→0.5 over 6–8. Product of acid-catalysed kinetics × alkalinity carbon-capture efficiency (collapses below pH 5 — Bertagni & Porporato 2022; Holden et al. 2024; Power et al. 2025); peak between the pH-5 threshold and pKa₁ = 6.35. |
| `pedogenic_frac` | CGIAR-CSI AI-binned 0 – 90 % (MAP-only fallback) | Primary path: UNEP 1992 aridity bands keyed on the CGIAR-CSI Global Aridity Index `data/cgiar_aridity_index.tif` (or `ai_v31_yr.tif`); auto-detects integer scaling and masks 65535 nodata. Fallback path: MAP-only proxy when the AI raster is absent. |

**Where to look:** `erw/erw-9-cdr-yield.R`, `docs/erw-parameters.md` §2.

### B4. Logistics — `erw-basalt-access` — **REAL** (since 2026-05-15)

Basalt sources from GLiM v1 (`vb` basic volcanic, `py` pyroclastic, `pb` basic plutonic);
cost-distance from each cropland pixel to nearest source over the MAP 2019 motorised
friction surface; monetised at $0.04 / min / t (30-t truck @ $80 / h); $10 / t quarry-gate.

**Current outputs**

- Source-mask cells in SSA: **1,399,005** (vb 1,320,820 + pb 78,185; py absent in SSA)
- Mean delivered price: **$40.8 / t**, range $10 – $50 / t (cap binds for ~half of pixels)
- Mean travel time: **815 min**, capped at 1000 min (≈ 1000 km @ 60 km/h free-flow proxy)

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `QUARRY_GATE_PRICE` | $10 / t | Basalt fines as quarry by-product. |
| `USD_PER_MIN_PER_T` | $0.04 / min / t | 30-t truck at $80 / h operating cost. |
| `EFFECTIVE_KM_PER_MIN` | 0.5 (≈ 30 km/h) | Effective speed for distance approximation. |
| `MAX_HAUL_KM` | 1000 km | Cap beyond which lifecycle emissions erase the credit. |

**Where to look:** `erw/erw-basalt-access.R`, `erw/erw-build-basalt-mask.R`,
`erw/erw-fetch-friction-surface.R`, `docs/erw-parameters.md` §3.

### B5. Energy — `erw-energy-country` — **REAL**

Per-country industrial-electricity tariff ($/kWh) and grid carbon intensity (kg CO₂/kWh)
rasterised onto the working grid. Drives both the grinding-cost term and the grinding-LCA
deduction inside `erw-7`. Falls back to flat $0.10 / kWh + 0.60 kg / kWh when missing.

**Where to look:** `erw/erw-energy-country.R`, `country_energy_table.csv`.

### B6. Crop response — EcoCrop arm (`erw-4`, `erw-5`) — **REAL**; Bayesian arm (`erw-yield-fit`, `erw-yield-predict`) — **NOT RUN**

EcoCrop arm runs: per-crop pH and acidity-saturation tolerance tables (23 crops × 2 responses)
feed a Recocrop relative-yield surface clamped to [0.2, 1].
Output: `{hp,ph}_crop_suitability_<crop>_0.tif` (46 rasters, one pair per crop) under `data/ecocrop_f/`.

Bayesian arm is unfit: needs `brms` + Stan + the ~14-row trial dataset. When fit, `erw-7`
prefers its posterior medians and falls back to EcoCrop where the Bayesian surface is NA.

**Where to look:** `erw/erw-4-crop-parameters.R`, `erw/erw-5-crop-yield-loss-function.R`,
`erw/erw-yield-fit.R`, `erw/erw-yield-predict.R`, `erw/erw-trial-data.csv`.

### B7. Profitability — `erw-7` — **REAL** (first end-to-end run 2026-05-19)

Cost side: quarry + grinding + transport + spreading. Credit side:
$\mathrm{CDR} \times p_{\mathrm{CO}_2} - \mathrm{MRV}$. Yield side:
$\Delta y \times p_{\mathrm{crop}}$. Three regimes (year-1, NPV @ 10%, equilibrium) with a
30 / 25 / 20 / 15 / 10 % CDR phasing over five years.

**Headline result (refreshed 2026-09-01).** At the current defaults
($150/tCO₂ credit, **$20/tCO₂** MRV, **50 µm** grain, Arrhenius
temperature factor, pH peak 6.0, net-export CDR accounting, year-1
agronomic return summed over the 5-yr basalt residency, CGIAR-CSI AI
for the pedogenic deduction, per-crop EcoCrop max-pH cliffs 5.5–8.0),
total gross margin under LiTAS-targeted allocation is **positive for
13 / 23 crops in year-1, 4 / 23 in NPV, and 14 / 23 in equilibrium**
(`docs/tables/output-crop-ranking.csv`). Top performers by total GM:
common bean (+\$4.9 B y1 / +\$0.6 B NPV / +\$1.0 B eq.), groundnut
(+\$4.0 B / +\$0.4 B / +\$0.8 B), potato (+\$2.5 B / +\$0.7 B /
+\$0.5 B), then sweet potato and cassava (positive on year-1 and
equilibrium). Acid-tolerant cereals (sorghum, millets) and
coffee/cocoa stay negative because the EcoCrop response is already
saturated on most of their SSA cropland — the agronomic side is
structurally small and CDR alone has to clear the full basalt cost.
The picture sharpens once pixels are supply-ranked and capped — see B8.

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `SPREADING_USD_T` | $8 / t | On-farm spreading cost. |
| `ELECTRICITY_USD_KWH_FB` | $0.10 / kWh | Fallback when country raster missing. |
| `GRID_CI_KG_PER_KWH_FB` | 0.60 kg / kWh | Fallback when country raster missing. |
| `TRUCK_KGCO2_PER_T_KM` | 0.12 | Diesel heavy truck. |
| `CARBON_PRICE_USD_T` | $150 / tCO₂ | Mid of 2024–25 ERW credit market. |
| `MRV_COST_USD_T_CO2` | **$20 / tCO₂** | Sampling + lab + verification + registry. Lowered from $30 on 2026-05-26; anchored (2026-09-01) to Mercer et al. 2024 (LSE GRI), EW MRV \$15–71/tCO₂. |
| `DISCOUNT_RATE_PCT` | 10 % | NPV regime. |
| `CDR_PHASING` | 30 / 25 / 20 / 15 / 10 % over 5 yr | Time-resolved CDR realisation. |

**Where to look:** `erw/erw-7-profitability-function.R`, `docs/erw-parameters.md` §5.

### B8. Supply ranking — `erw-supply` — **REAL** (refreshed 2026-09-01)

Pixels ranked descending by gross margin per tonne basalt — the LP dual on the basalt-supply
constraint. Produces supply curves and deployment masks at 1 / 5 / 10 / 25 / 50 / 100 / 250 /
500 Mt yr⁻¹ caps, plus an unconstrained reference.

**Headline result (refreshed 2026-09-01, Arrhenius + pH-6.0 net-export basis).**
Year-1 deployment is profitable out to ~250 Mt yr⁻¹ and NPV out to just past
100 Mt yr⁻¹. Marginal $/t basalt by regime:

- **year-1:** +$279 → +$104 → +$66 → **+$5** → −$60 over 1 / 50 / 100 / **250** / 500 Mt yr⁻¹.
  Peak total gross margin **$16.2 B at 250 Mt yr⁻¹** with 68.4 Mt CDR yr⁻¹.
- **NPV @ 10 %:** +$108 → +$34 → **+$4** → −$27 over the same ladder. Peak total gross
  margin **$3.9 B at 100 Mt yr⁻¹** with 28.6 Mt CDR yr⁻¹.
- **Equilibrium (maintenance rate):** +$196 → **+$18** → −$16 → −$61 over 1 / **50** / 100 /
  250 Mt yr⁻¹. Marginal pixel slips negative between 50 and 100 Mt yr⁻¹; peak total GM
  **$3.0 B at 50 Mt yr⁻¹** with 13.7 Mt CDR yr⁻¹.

Unconstrained SSA capacity tops out at 443 Mt basalt yr⁻¹ (year-1, NPV) or 145 Mt yr⁻¹
(equilibrium maintenance), with cumulative CDR of 121 Mt and 40 Mt respectively. The
unconstrained NPV total is **−$5.9 B** — net-negative because deep-tail pixels have basalt
costs exceeding both credit and agronomy. Ranking + cap still matters as much as the
input parameters.

**Where to look:** `erw/erw-supply.R`, `data/supply_curve_{year1,npv,equilibrium}.csv`,
`data/gm_per_t_basalt_{regime}.tif`, `data/deployment_under_{10,50,250}_Mt_{regime}.tif`.

### B9. Sensitivity — `erw-8` — **REAL** (run 2026-09-01)

Five sweeps: (i) crop × basalt × carbon-price grid; (ii) yield uplift **1.0 – 1.8×**
(capped 2026-09-01 at 1.8×, was 2.5×, per the 1.7× field-trial envelope); (iii) MRV
0 – 80 $/tCO₂; (iv) grain size 10 / 30 / 50 / 100 / 200 / 500 µm; (v) allocation rule
(LiTAS-targeted + uniform 10 / 20 / 50). All sweeps run across the three regimes and 23 crops.

`erw-8` `source()`s `erw-7`, so it runs at the current defaults automatically. The full
default-scope sweep was executed in the 2026-09-01 re-run (≈6–8 h on a single core,
≈14k `profit()` calls). The robustness-grid headline (targeted, equilibrium net-export,
180-point 4-knob grid): baseline intersection 1.32 Mha; tornado ranks the public-side
cost knob (p−m)/c at 1.73 Mha swing and the CDR rate at 1.72 (effectively tied), then
y/c at 0.96 and λ at 0.22; core tier (≥50 %) 0.65 Mha, candidate tier (≥33 %) 1.22 Mha
(`docs/tables/output-sensitivity-tornado.csv`, `output-core-priority-summary.csv`).

**Where to look:** `erw/erw-8-sensitivity-analysis.R`.

---

## 7. Outputs and indicator maps

Twelve indicator maps are rendered into `docs/maps/` by `erw/erw-plot-maps.R`. The HTML page
embeds them in a gallery alongside the conceptual-framework and pipeline-architecture figures.

| # | Map | What it shows | Block |
|---|---|---|---|
| 01 | `01-soil-ph.png` | SoilGrids depth-weighted topsoil pH, cropland-masked | B1 |
| 02 | `02-basalt-rate-merlos.png` | LiTAS year-1 basalt application rate (t / ha) | B2 |
| 03 | `03-cdr-per-t-basalt.png` | Per-tonne CDR efficiency (t CO₂ / t basalt) | B3 |
| 04 | `04-cdr-yield-merlos.png` | Per-ha cumulative CDR (t CO₂ / ha) | B3 |
| 05 | `05-cdr-climate-factor.png` | $f(\mathrm{MAT}, \mathrm{MAP})$ scaling | B3 |
| 06 | `06-pedogenic-fraction.png` | Aridity-band pedogenic-C deduction | B3 |
| 07 | `07-electricity-price.png` | Country industrial-electricity tariff (\$/kWh) | B5 |
| 08 | `08-grid-CI.png` | Country grid carbon intensity (kg CO₂ / kWh) | B5 |
| 09 | `09-basalt-sources.png` | GLiM vb + pb source mask | B4 |
| 10 | `10-basalt-traveltime.png` | Travel time to nearest source (min) | B4 |
| 11 | `11-basalt-delivered-price.png` | Delivered feedstock price (\$ / t) | B4 |
| 12 | `12-feedstock-class.png` | Source mask split by GLiM class | B4 |

Add a row when a new map is rendered; remove when one is dropped.

### 7.1 Profitability outcome maps (B7)

`erw/erw-10-profitability-maps-tables.R` renders outcome maps derived from
the 276 economics rasters: continent-wide crop-weighted GM, per-crop GM for
the five highest-acreage crops, profitable-pixel masks, and per-pixel
breakeven carbon-price surfaces. All assumption combinations (3 regimes ×
4 allocations) are covered. The full panel lives in `docs/erw-results.pdf`;
the most useful four panels for this document are below.

| Crop-weighted GM (\$/ha, NPV, targeted) | Profitable mask (NPV, targeted) |
|:-:|:-:|
| ![](maps/profitability/ssa_gm_npv_targeted.png){width=2.6in} | ![](maps/profitability/profitable_mask_npv_targeted.png){width=2.6in} |
| **Breakeven carbon price (NPV, targeted)** | **Crop-weighted GM (NPV, uniform 20 t/ha)** |
| ![](maps/profitability/breakeven_carbon_npv_targeted.png){width=2.6in} | ![](maps/profitability/ssa_gm_npv_uniform_20.png){width=2.6in} |

### 7.2 SSA-wide totals under different assumptions (refreshed 2026-09-01)

Source: `docs/tables/output-ssa-summary.csv` — one row per regime ×
allocation. Refreshed 2026-09-01 after the ESROC-anchored citation
review landed (Arrhenius temperature factor, pH peak 6.0, net-export
CDR accounting, yield sweep capped 1.8×), on top of the 2026-05-26
defaults (grain 50 µm, MRV \$20/tCO₂, year-1 agronomic summed over
5-yr horizon, CGIAR-CSI Global Aridity Index, per-crop EcoCrop max-pH).

```{=latex}
\begin{small}
```

| Regime | Allocation | Total GM (M\$) | Agro (M\$) | Basalt (M\$) | CDR rev. (M\$) | CDR (Mt) | Profitable (Mha) | CDR on profitable (Mt) |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| **year-1** | **targeted** | **+12,371** | 30,220 | 21,545 | 4,483 | 34.5 | 7.4 | 25.6 |
| NPV | targeted | −5,926 | 12,030 | 21,545 | 3,560 | 34.5 | 2.6 | 16.9 |
| **equilibrium** | **targeted** | **+1,772** | 6,044 | 7,364 | 3,248 | 25.0 | 6.5 | 12.4 |
| **year-1** | **uniform 10** | **+14,357** | 30,220 | 75,918 | 11,512 | 88.6 | 10.6 | 1.1 |
| NPV | uniform 10 | −10,548 | 5,495 | 75,918 | 9,143 | 88.6 | 3.2 | 0.4 |
| equilibrium | uniform 10 | −3,774 | 6,044 | 75,918 | 17,967 | 138.2 | 7.8 | 15.7 |
| **year-1** | **uniform 20** | **+1,422** | 30,220 | 151,836 | 27,978 | 215.2 | 8.1 | 7.6 |
| NPV | uniform 20 | −24,285 | 5,495 | 151,836 | 22,218 | 215.2 | 1.9 | 2.4 |
| equilibrium | uniform 20 | −11,850 | 6,044 | 151,836 | 40,188 | 309.1 | 6.3 | 29.2 |
| year-1 | uniform 50 | −25,337 | 30,220 | 379,591 | 92,169 | 709.0 | 6.7 | 50.5 |
| NPV | uniform 50 | −55,929 | 5,495 | 379,591 | 73,196 | 709.0 | 2.0 | 19.3 |
| equilibrium | uniform 50 | −36,049 | 6,044 | 379,591 | 107,153 | 824.2 | 4.9 | 63.2 |

```{=latex}
\end{small}
```

Read across: all rows are now on the **net-export** CDR basis (the
first-application acidity haircut removes ~70 % of gross first-round
CDR; the equilibrium haircut is much smaller), which is why the CDR
columns and profitable areas are far leaner than the pre-2026-09-01
gross-basis table. The **year-1 targeted** row leads among the targeted
runs at **+\$12.4 B** total SSA-wide GM — the horizon-summed agronomic
side scales with 5× annual agronomic returns. **Year-1 uniform 10** is
the highest absolute total (\$14.4 B) because basalt is applied across
all cropland regardless of acidity and the per-crop max-pH cliffs make
most of that cropland agronomically responsive. The **NPV-targeted**
row is negative (−\$5.9 B): the 10 % discount rate plus the net-export
haircut eat both revenue streams. **Equilibrium-targeted** stays
positive (+\$1.8 B) at a 25.0 Mt CDR footprint. Uniform-50 stays
negative across all regimes — 50 t/ha on every cropland pixel is excess
basalt where it isn't needed, and the deep-tail cost dominates. The
full per-country and per-crop breakdowns are in `docs/erw-results.pdf`.
The same CSVs feed `erw-supply.R`'s ranking.

---

## 8. Parameters and constants

See `docs/erw-parameters.md` for the full catalogue with citations, source URLs and DOIs.
The blocks in §6 above repeat only the constants that materially set the headline result;
the parameters doc is authoritative for everything else.

Quick reference of the six **decision variables** (the only knobs swept by `erw-8`):

| Decision variable | Default | Where set | Sweep range |
|---|---|---|---|
| `CaO_frac`, `MgO_frac` (feedstock) | 0.10 / 0.07 | `erw-3` | not currently swept |
| `grain_size_um` | **50 µm** | `erw-3` | 10 / 30 / 50 / 100 / 200 / 500 µm |
| `allocation` | LiTAS-targeted | `erw-7`, `erw-8` | + uniform 10 / 20 / 50 |
| `CARBON_PRICE_USD_T` | $150 / tCO₂ | `erw-7`, `erw-8` | swept jointly with crop + basalt price |
| `MRV_COST_USD_T_CO2` | **$20 / tCO₂** | `erw-7`, `erw-8` | 0 – 80 $ / tCO₂ |
| `DISCOUNT_RATE_PCT` | 10 % | `erw-7` | NPV regime only |

---

## 9. Validation and known issues

### What has been sanity-checked

- B1 pH map matches the qualitative expectation for SSA (acidic in humid tropics, alkaline
  in Sahel and parts of southern Africa).
- B3 CDR-yield map is strongest in the humid tropics (Guinea, Congo basin) and suppressed
  in the Sahel — the expected pattern given climate scaling and the aridity-driven
  pedogenic-C deduction.
- B4 delivered-price map shows the expected geography — cheap near basalt outcrops
  (Ethiopian highlands, East African Rift, Cameroon volcanic line, Madagascar, southern
  Africa), capped at $50 / t across West Africa and the Sahel.
- B4 source-mask polygon counts match the GLiM v1 catalogue (5,266 vb + 1,189 pb in SSA).

### Open issues

| Issue | Severity | Block | Mitigation |
|---|---|---|---|
| Bayesian yield arm not fit | high (limits scenario realism) | B6 | run `erw-yield-fit.R` once `brms` + Stan are installed; the trial dataset is the bottleneck, not the code |
| Pedogenic ∩ acidity deduction overlap | low (conservative) | B3 | 1.28 % of pixels are both arid and acid; the sequential ordering over-deducts F·S·p there — documented, not restructured |
| Industrial by-products not modelled | medium (regional realism) | B4 | requires a separate inventory of steel mills, cement plants, mine tailings |
| Ultramafic outcrops excluded from feedstock | low (intentional) | B4 | mark them explicitly in a future "rejected feedstock" overlay |
| MRV cost is constant $20 / tCO₂ regardless of scale or protocol | low | B7 | sweep already covers 0 – 80 $; consider scale-dependence in a future revision |
| Pedogenic-C deduction uses MAP only, not full AI | low | B3 | switch to AI = MAP / PET when a PET surface is available |
| 14-row trial dataset is prior-dominated | medium | B6 (Bayesian arm) | append trials as new evidence appears (Beerling group, InPlanet, Flux trials) |
| Single-currency model | low | all | USD throughout; not a problem for ex-ante analysis |

---

## 10. How to reproduce

### 10.1 Environment

```bash
# R 4.5+, with the geodata, terra, sf, here, brms, malariaAtlas packages
Rscript erw/erw-0-install-packages.R
```

LaTeX is needed only for the framework + pipeline figures (`pdflatex` + `pdftocairo`).

### 10.2 Run order

```bash
# 1. inputs and working grid
Rscript erw/erw-1-layers-soilgrids.R
Rscript erw/erw-2-layers-spam.R

# 2. basalt requirements
Rscript erw/erw-3-basalt-requirements.R

# 3. crop response
Rscript erw/erw-4-crop-parameters.R
Rscript erw/erw-5-crop-yield-loss-function.R

# 4. CDR + cost surfaces
Rscript erw/erw-9-cdr-yield.R
Rscript erw/erw-energy-country.R
Rscript erw/erw-fetch-friction-surface.R   # one-off — pulls MAP friction
Rscript erw/erw-basalt-access.R

# 5. (optional) Bayesian yield arm
Rscript erw/erw-yield-fit.R
Rscript erw/erw-yield-predict.R

# 6. profitability, supply, sensitivity
Rscript erw/erw-7-profitability-function.R
Rscript erw/erw-supply.R
Rscript erw/erw-8-sensitivity-analysis.R

# 7. render maps, results, and rebuild figures
Rscript erw/erw-plot-maps.R                      # 12 indicator maps
Rscript erw/erw-10-profitability-maps-tables.R   # profitability maps + 3 CSV tables
pdflatex docs/erw-pipeline-flow.tex \
  && pdftocairo -svg docs/erw-pipeline-flow.pdf docs/erw-pipeline-flow.svg
pdflatex docs/erw-conceptual-framework.tex \
  && pdftocairo -svg docs/erw-conceptual-framework.pdf docs/erw-conceptual-framework.svg

# 8. rebuild documentation PDFs
bash docs/build-erw-model.sh
bash docs/build-erw-results.sh
bash docs/build-erw-tutorial.sh
```

### 10.3 Expected runtimes (Apple Silicon, single core)

| Stage | Time |
|---|---|
| `erw-1`, `erw-2` (downloads + resampling) | ~30 – 60 min first time, cached afterwards |
| `erw-3`, `erw-9` | a few minutes each |
| `erw-fetch-friction-surface` | 5 – 10 min (one-off download) |
| `erw-basalt-access` (costDist) | ~10 min |
| `erw-7`, `erw-8` | minutes – hours depending on sweep depth |
| `erw-plot-maps` (12 maps) | ~15 min |
| `erw-10-profitability-maps-tables` (48 maps + 3 CSVs) | ~5 min |

---

## 11. Gaps and roadmap

### Near-term (within current month)

1. Fit the Bayesian yield arm (`erw-yield-fit.R`) once `brms` + Stan are installed locally.
2. ~~Run `erw-7` end-to-end~~ — done (2026-05-19 first run; refreshed 2026-09-01):
   276-raster profitability stack `{crop}_{regime}.tif` under `economics_erw/{allocation}/`.
3. ~~Run `erw-supply` and `erw-8`~~ — done (both re-run 2026-09-01 at the current defaults).
4. Add indicator maps for the supply curves and the year-1 / NPV / equilibrium profitability
   comparison.

### Medium-term

5. **Industrial by-product feedstock layer.** Inventory of steel mills (GEM Steel Plant
   Tracker), cement-clinker plants (Global Cement Directory), and active mine tailings
   (USGS / national geological surveys). Add a point-source feedstock layer and feedstock-
   chemistry table; rerun B4 with the union of mafic outcrops and by-product points.
6. **Cross-country MRV cost differentiation.** Some jurisdictions (Brazil, Kenya) have
   simpler smallholder-aggregator pathways; the flat $30 / tCO₂ assumption over-estimates
   cost for those.
7. **Aridity index using AI = MAP / PET** instead of MAP-only for the pedogenic-C deduction.
   Requires a PET surface (CGIAR-CSI or computed from WorldClim).

### Long-term

8. **Multi-feedstock decision rule.** Currently feedstock chemistry is fixed; the user
   chooses one. Generalise to a per-pixel cheapest-eligible-feedstock rule given a chemistry
   inventory.
9. **Time-resolved deployment scenarios.** Year-by-year deployment under supply caps,
   carbon-price paths, and yield-learning curves.
10. **Smallholder-aggregator economic model.** Costs and revenues at the aggregator level
    (transport, MRV pooling, finance) rather than the per-pixel "farmer" level.

---

## 12. References

The full bibliography is in `docs/erw-review.md`. The most load-bearing citations are:

- Beerling, D. J. et al. (2020). *Potential for large-scale CO₂ removal via enhanced rock
  weathering with croplands.* **Nature** 583, 242 – 248.
- Strefler, J. et al. (2018). *Potential and costs of carbon dioxide removal by enhanced
  weathering of rocks.* **ERL** 13, 034010.
- Lewis, A. L. et al. (2021). *Effects of mineralogy, chemistry and physical properties of
  basalts on carbon capture potential and plant-nutrient element release via enhanced
  weathering.* **Applied Geochemistry** 132, 105023. doi:10.1016/j.apgeochem.2021.105023.
  (Reference for the reactive-fraction calibration used in `erw-3`.)
- Hartmann, J. & Moosdorf, N. (2012). *The new global lithological map database GLiM.*
  PANGAEA doi:10.1594/PANGAEA.788537.
- Weiss, D. J. et al. (2020). *Global maps of travel time to healthcare facilities.*
  **Nature Medicine** 26, 1835–1838. doi:10.1038/s41591-020-1059-1.
  (Source of the Malaria Atlas Project 2019 motorised friction surface used in
  `erw-basalt-access`; the citation-review of 2026-09-01 corrected an earlier
  attribution to Weiss et al. 2018.)
- White, A. F. & Blum, A. E. (1995). *Effects of climate on chemical weathering in
  watersheds.* **Geochimica et Cosmochimica Acta** 59 (9), 1729–1747.
  (Source of the Ea = 68.8 kJ/mol silicate activation energy in the Arrhenius
  temperature factor of `erw-9`.)
- Bertagni, M. B. & Porporato, A. (2022). *The carbon-capture efficiency of natural water
  alkalinization.* **Science of the Total Environment**. (Capture-efficiency collapse
  below pH 5 — one anchor of the pH-6.0 peak in `erw-9`; with Holden et al. 2024,
  *Science of the Total Environment*, and Power et al. 2025, *Frontiers in Climate*.)
- Mercer, L. et al. (2024). *Measurement, reporting and verification costs for enhanced
  weathering.* LSE Grantham Research Institute. (EW MRV \$15–71/tCO₂ — anchor for the
  \$20/tCO₂ MRV default in `erw-7`.)
- Aramburu Merlos, F., Silva, J. V., Baudron, F. & Hijmans, R. J. (2023). *Estimating lime
  requirements for tropical soils: Model comparison and development.* **Geoderma** 432,
  116421. (Reference for the LiTAS lime-equivalence recipe used in `erw-3`.)
- Kanzaki, Y., Planavsky, N. J. & Reinhard, C. T. (2023). *New estimates of the storage
  permanence and ocean co-benefits of enhanced rock weathering.* **PNAS Nexus** 2 (4),
  pgad059.
- Beerling, D. J. et al. (2024). *Enhanced weathering in the US Corn Belt delivers carbon
  removal with agronomic benefits.* **PNAS** 121 (9), e2319436121.
- Haque, F. et al. (2025). *Agronomic Performance of Enhanced Rock Weathering in a Tropical
  Smallholder System: A Maize Trial in Kenya.* CDRXIV preprint 410 (Flux Carbon / UNCCD).
- Dupla, X., Bertagni, M. B. & Grand, S. (2025). *Three Years of Field Trials Indicate a
  Sustained Enhanced Rock Weathering Signal with Limited CO₂ Removal.*
  **Environmental Science & Technology** 59 (48), 25751–25764.

---

*This document is the canonical state of the model. When you change a script, a constant,
a data source, or an output, edit the relevant block under §6 and add a dated entry to §1.
Anything that is not in this document — even if it lives in the code — is not part of the
model's documented behaviour.*
