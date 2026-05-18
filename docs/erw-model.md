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

**Last updated:** 2026-05-15
**Geographic scope:** Sub-Saharan Africa, 47 countries, GADM v4 boundaries
**Working grid:** SoilGrids-Africa 30 arc-sec aggregated 10× → ~0.083° (≈9 km) — 746 × 828 cells
**Currency:** USD; **CO₂ in tonnes; year-1 / NPV @ 10% / equilibrium regimes**

### Pipeline-block status

| Block | Stage(s) | Status | Notes |
|---|---|---|---|
| B1. Working grid | `erw-1`, `erw-2` | **REAL** | SoilGrids properties + SPAM v2 (23 crops) co-registered on the 10× grid |
| B2. Basalt rate | `erw-3` | **REAL** | LiTAS / Kamprath / Cochrane / maintenance + uniform 10/20/50 t·ha⁻¹ |
| B3. CDR surface | `erw-9` | **REAL** | Climate × pH × pedogenic-C deduction; CDR-per-tonne + CDR-per-ha rasters |
| B4. Logistics | `erw-basalt-access` | **REAL** (since 2026-05-15) | Friction surface fetched, mask expanded to vb+pb, end-to-end delivered price computed |
| B5. Energy | `erw-energy-country` | **REAL** | Country tariff + grid CI rasters |
| B6. Crop response — EcoCrop | `erw-4`, `erw-5` | **REAL** | Per-crop pH and acidity-saturation suitability rasters for 23 crops |
| B6. Crop response — Bayesian | `erw-yield-fit`, `erw-yield-predict` | **NOT RUN** | Trial-anchored brms model not fit; erw-7 falls back to EcoCrop |
| B7. Profitability | `erw-7` | **NOT RUN** | All inputs are ready; gross-margin rasters not yet generated |
| B8. Supply ranking | `erw-supply` | **NOT RUN** | Depends on B7 |
| B9. Sensitivity | `erw-8` | **NOT RUN** | Depends on B7 |

### Headline numbers (current run)

| Metric | Value | Source raster |
|---|---|---|
| Mafic source pixels (vb+pb in SSA) | **1,399,005** (1.9% of SSA cropland-context cells) | `basalt_source_mask.tif` |
| Mean delivered basalt price | **$40.8 / t** (range $10 – $50, cap binds for ~half of pixels) | `basalt_delivered_price_usd_t.tif` |
| Mean travel time to source | **815 min** (capped at 1000 min ≈ 1000 km @ 60 km/h) | `basalt_traveltime_min.tif` |
| CDR per tonne basalt | computed pixel-wise | `cdr_per_t_basalt.tif` |
| CDR yield (LiTAS year-1) | computed pixel-wise; strongest in humid tropics | `cdr_yield_merlos.tif` |

---

## 1. Changelog

Reverse chronological. One bullet per material change. Reference the block(s) affected so it
is obvious which section under §6 also moved.

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
- **Crop coverage**: 23 SPAM v2 crops — `MAIZ SORG BEAN CHIC LENT GROU SOYB COWP RICE WHEA
  CASS POTA SWPO YAMS BARL MILL VEGE TROF TEMF OPUL OOIL OFIB OCER` (the SPAM v2 codes).
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
- Dissolution rate is the temperature × moisture climate factor (Arrhenius anchored to
  Tᵣₑf = 11 °C, Pᵣₑf = 1000 mm) times a triangular pH-acid-catalysis term peaked near pH 5.
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
2. Grain size — 10 – 500 µm.
3. Allocation rule — LiTAS-targeted vs uniform 10 / 20 / 50 t ha⁻¹.
4. Carbon price — default $150 / tCO₂.
5. MRV cost — default $30 / tCO₂.
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

**Where to look:** `erw/erw-1-layers-soilgrids.R`, `erw/erw-2-layers-spam.R`,
`docs/erw-parameters.md` §1 (depth-weighting recipe).

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
| `grain_size_um` | 100 µm | Sweeps 10 – 500 µm in `erw-8`. |
| `reactive_fraction_ref` | 0.20 | Lewis 2021 calibration at reference grain × climate. |
| `GRAIN_BETA` | 0.5 | Surface-area exponent for the grain-size factor. |
| `GRIND_ALPHA` | 1.2 | Strefler 2018 grinding-energy exponent. |

**Where to look:** `erw/erw-3-basalt-requirements.R`, `docs/erw-parameters.md` §2.

### B3. CDR surface — `erw-9` — **REAL**

Per-tonne CDR potential from CaO/MgO stoichiometry, scaled by a temperature × moisture
climate factor (anchored to Tᵣₑf = 11 °C, Pᵣₑf = 1000 mm) and a triangular pH term peaked
near pH 5. An aridity-binned pedogenic-carbonate fraction (UNEP 1992 bands on MAP) removes
alkalinity precipitating locally.

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `T_ref` | 11 °C | Reference MAT anchor (US Corn Belt). |
| `P_ref` | 1000 mm | Reference MAP anchor. |
| `f_pH` | triangular peak at pH ≈ 5.0 | Acid-catalysed dissolution scaling. |
| `pedogenic_frac` | MAP-binned 0 – 90 % | UNEP 1992 aridity bands using MAP as v1 proxy for AI = P / PET. |

**Where to look:** `erw/erw-9-cdr-yield.R`, `docs/erw-parameters.md` §3.

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
`erw/erw-fetch-friction-surface.R`, `docs/erw-parameters.md` §4.

### B5. Energy — `erw-energy-country` — **REAL**

Per-country industrial-electricity tariff ($/kWh) and grid carbon intensity (kg CO₂/kWh)
rasterised onto the working grid. Drives both the grinding-cost term and the grinding-LCA
deduction inside `erw-7`. Falls back to flat $0.10 / kWh + 0.60 kg / kWh when missing.

**Where to look:** `erw/erw-energy-country.R`, `country_energy_table.csv`.

### B6. Crop response — EcoCrop arm (`erw-4`, `erw-5`) — **REAL**; Bayesian arm (`erw-yield-fit`, `erw-yield-predict`) — **NOT RUN**

EcoCrop arm runs: per-crop pH and acidity-saturation tolerance tables (23 crops × 2 responses)
feed a Recocrop relative-yield surface clamped to [0.2, 1]. Output:
`ecocrop_f/{hp,ph}_crop_suitability_<crop>_0.tif`.

Bayesian arm is unfit: needs `brms` + Stan + the ~14-row trial dataset. When fit, `erw-7`
prefers its posterior medians and falls back to EcoCrop where the Bayesian surface is NA.

**Where to look:** `erw/erw-4-crop-parameters.R`, `erw/erw-5-crop-yield-loss-function.R`,
`erw/erw-yield-fit.R`, `erw/erw-yield-predict.R`, `erw/erw-trial-data.csv`.

### B7. Profitability — `erw-7` — **NOT RUN**

Cost side: quarry + grinding + transport + spreading. Credit side:
$\mathrm{CDR} \times p_{\mathrm{CO}_2} - \mathrm{MRV}$. Yield side:
$\Delta y \times p_{\mathrm{crop}}$. Three regimes (year-1, NPV @ 10%, equilibrium) with a
30 / 25 / 20 / 15 / 10 % CDR phasing over five years.

**Key constants**

| Name | Default | Notes |
|---|---|---|
| `SPREADING_USD_T` | $8 / t | On-farm spreading cost. |
| `ELECTRICITY_USD_KWH_FB` | $0.10 / kWh | Fallback when country raster missing. |
| `GRID_CI_KG_PER_KWH_FB` | 0.60 kg / kWh | Fallback when country raster missing. |
| `TRUCK_KGCO2_PER_T_KM` | 0.12 | Diesel heavy truck. |
| `CARBON_PRICE_USD_T` | $150 / tCO₂ | Mid of 2024–25 ERW credit market. |
| `MRV_COST_USD_T_CO2` | $30 / tCO₂ | Sampling + lab + verification + registry. |
| `DISCOUNT_RATE_PCT` | 10 % | NPV regime. |
| `CDR_PHASING` | 30 / 25 / 20 / 15 / 10 % over 5 yr | Time-resolved CDR realisation. |

**Where to look:** `erw/erw-7-profitability-function.R`, `docs/erw-parameters.md` §5.

### B8. Supply ranking — `erw-supply` — **NOT RUN**

Pixels ranked descending by gross margin per tonne basalt — the LP dual on the basalt-supply
constraint. Produces supply curves and deployment masks at 1 / 5 / 10 / 25 / 50 / 100 / 250 /
500 Mt yr⁻¹ caps, plus an unconstrained reference.

**Where to look:** `erw/erw-supply.R`.

### B9. Sensitivity — `erw-8` — **NOT RUN**

Five sweeps: (i) crop × basalt × carbon-price grid; (ii) yield uplift 1.0 – 2.5×; (iii) MRV
0 – 80 $/tCO₂; (iv) grain size 10 / 30 / 50 / 100 / 200 / 500 µm; (v) allocation rule
(LiTAS-targeted + uniform 10 / 20 / 50). All sweeps run across the three regimes and 23 crops.

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
| 07 | `07-electricity-price.png` | Country industrial-electricity tariff ($/kWh) | B5 |
| 08 | `08-grid-CI.png` | Country grid carbon intensity (kg CO₂ / kWh) | B5 |
| 09 | `09-basalt-sources.png` | GLiM vb + pb source mask | B4 |
| 10 | `10-basalt-traveltime.png` | Travel time to nearest source (min) | B4 |
| 11 | `11-basalt-delivered-price.png` | Delivered feedstock price ($ / t) | B4 |
| 12 | `12-feedstock-class.png` | Source mask split by GLiM class | B4 |

Add a row when a new map is rendered; remove when one is dropped.

---

## 8. Parameters and constants

See `docs/erw-parameters.md` for the full catalogue with citations, source URLs and DOIs.
The blocks in §6 above repeat only the constants that materially set the headline result;
the parameters doc is authoritative for everything else.

Quick reference of the six **decision variables** (the only knobs swept by `erw-8`):

| Decision variable | Default | Where set | Sweep range |
|---|---|---|---|
| `CaO_frac`, `MgO_frac` (feedstock) | 0.10 / 0.07 | `erw-3` | not currently swept |
| `grain_size_um` | 100 µm | `erw-3` | 10 / 30 / 50 / 100 / 200 / 500 µm |
| `allocation` | LiTAS-targeted | `erw-7`, `erw-8` | + uniform 10 / 20 / 50 |
| `CARBON_PRICE_USD_T` | $150 / tCO₂ | `erw-7`, `erw-8` | swept jointly with crop + basalt price |
| `MRV_COST_USD_T_CO2` | $30 / tCO₂ | `erw-7`, `erw-8` | 0 – 80 $ / tCO₂ |
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
| `erw-7` profitability not run | high (no headline output yet) | B7 | all inputs are in place; one run suffices |
| `erw-supply`, `erw-8` not run | medium | B8, B9 | both depend on B7 |
| Industrial by-products not modelled | medium (regional realism) | B4 | requires a separate inventory of steel mills, cement plants, mine tailings |
| Ultramafic outcrops excluded from feedstock | low (intentional) | B4 | mark them explicitly in a future "rejected feedstock" overlay |
| MRV cost is constant $30 / tCO₂ regardless of scale or protocol | low | B7 | sweep already covers 0 – 80 $; consider scale-dependence in a future revision |
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

# 7. render maps and rebuild figures
Rscript erw/erw-plot-maps.R
pdflatex docs/erw-pipeline-flow.tex      && pdftocairo -svg docs/erw-pipeline-flow.pdf      docs/erw-pipeline-flow.svg
pdflatex docs/erw-conceptual-framework.tex && pdftocairo -svg docs/erw-conceptual-framework.pdf docs/erw-conceptual-framework.svg
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

---

## 11. Gaps and roadmap

### Near-term (within current month)

1. Fit the Bayesian yield arm (`erw-yield-fit.R`) once `brms` + Stan are installed locally.
2. Run `erw-7` end-to-end to produce the 276-raster profitability stack
   (`economics_erw/{allocation}/{crop}_{regime}.tif`).
3. Run `erw-supply` and `erw-8` and render their headline figures.
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
- Lewis, A. L. et al. (2021). *Effects of mineralogy, chemistry and climatic regime on rates
  of basalt weathering.* (Reference for the reactive-fraction calibration used in `erw-3`.)
- Hartmann, J. & Moosdorf, N. (2012). *The new global lithological map database GLiM.*
  PANGAEA doi:10.1594/PANGAEA.788537.
- Weiss, D. J. et al. (2018, 2020). *Global maps of travel time to healthcare facilities.*
  Malaria Atlas Project — friction surface 2019.
- Aramburu-Merlos, F. et al. (2024). *LiTAS: lime-targeted application strategy for tropical
  acid soils.* (Reference for the LiTAS lime-equivalence recipe used in `erw-3`.)
- Kanzaki, Y. et al. (2024). *Soil-pH-driven controls on enhanced-weathering CDR rates.*
  **Nature**.
- Beerling group, US Corn Belt field trials (2024 PNAS).
- Flux × UNCCD Kisumu County trial (2024).
- Amann, T. et al. (2025). *Swiss vineyard ERW trial: low CDR rates in cool-alkaline systems.*
  **Environmental Science & Technology**.

---

*This document is the canonical state of the model. When you change a script, a constant,
a data source, or an output, edit the relevant block under §6 and add a dated entry to §1.
Anything that is not in this document — even if it lives in the code — is not part of the
model's documented behaviour.*
