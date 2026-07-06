# ERW pipeline — parameters & assumptions

Comprehensive catalogue of every numerical constant, modelling choice, and load-bearing
assumption used by the `erw/erw-*.R` scripts. Each entry lists the script in which the
parameter is defined, the value at which it ships, the units, and the source citation
(with DOI / URL where one exists). Use this as the single point of reference when
auditing a model run or substituting a parameter for a particular site.

Updates to this file should be made whenever a default value in an `erw-*.R` script is
changed.

---

## Conventions

- **Code path** — file and approximate line where the constant lives.
- **Default** — value the script ships with.
- **Units** — physical or financial unit of the value.
- **Used by** — downstream scripts that consume the value (directly or via the
  `basalt_feedstock_chemistry.csv` handoff).
- **Source** — author, year, brief title; DOI or stable URL.
- **Notes** — modelling rationale and caveats.

Bracketed `[Sx]` refers to entries in the [Sources](#sources) section at the end.

---

## 1. `erw/erw-3-basalt-requirements.R` — feedstock chemistry & grain-size lever

### 1.1 Basalt mass-fraction chemistry (`basalt` list)

| Code path | Default | Units | Used by | Source |
|---|---|---|---|---|
| `basalt$CaO_frac` | 0.10 | mass fraction | erw-3 (CCE), erw-7, erw-9 | Lewis 2021 [S1]; Beerling 2020 SI [S2] |
| `basalt$MgO_frac` | 0.07 | mass fraction | erw-3 (CCE), erw-7, erw-9 | Beerling 2020 SI [S2] |
| `basalt$K2O_frac`  | 0.015 | mass fraction | (not yet consumed) | Beerling 2020 SI [S2] |
| `basalt$Na2O_frac` | 0.025 | mass fraction | (not yet consumed) | Beerling 2020 SI [S2] |
| `basalt$P2O5_frac` | 0.003 | mass fraction | (not yet consumed) | Beerling 2020 SI [S2] |
| `basalt$Ni_ppm`    | 100   | ppm | (not yet consumed, risk surrogate) | Beerling 2020 SI [S2]; Dupla 2023 [S3] |
| `basalt$Cr_ppm`    | 200   | ppm | (not yet consumed, risk surrogate) | Beerling 2020 SI [S2]; Dupla 2023 [S3] |

**Notes.** Values are representative of a tropical-belt basalt (e.g. Deccan Trap fines,
Brazilian Paraná, Cameroon Volcanic Line). Override per quarry once chemistry assays are
available from `erw-basalt-access` output. The trace-metal columns (Ni, Cr) are carried
for future risk-screening but are not consumed by the profitability function in this
version.

### 1.2 Grain-size lever

| Code path | Default | Units | Source |
|---|---|---|---|
| `basalt$grain_size_um` | 50 | µm | Decision variable. Sweeps 10–500 µm in `erw-8`. Default lowered from 100 µm on 2026-05-26 — coincides with the Strefler 2018 [S4] grinding-energy anchor and roughly √2× the reactivity of 100 µm at ~2× the kWh/t. Sensitivity sweep shows this is the cost-minimising default once carbon revenue is credited. |
| `GRAIN_REF_UM`         | 100 | µm | Anchor grain size at which the reference reactive fraction was calibrated. |
| `GRAIN_BETA`           | 0.5 | dimensionless | Surface-area exponent in $(d_{\text{ref}}/d)^\beta$. Square-root-of-surface-area midpoint, defensible without an extra free parameter. Lewis 2021 grain sensitivity [S1]; Strefler 2018 [S4]. |

**Notes.** Empirical surface-area-vs-rate studies on basalt fines show silt-dominated
(<45 µm) material weathering ~2× faster than sand-dominated (150–500 µm). This implies
$\beta \approx 0.35\text{–}0.5$. We use $\beta=0.5$ as a defensible midpoint that
collapses to the standard surface-area-square-root scaling.

### 1.3 Reactivity calibration

| Code path | Default | Units | Source |
|---|---|---|---|
| `basalt$reactive_fraction_ref` | 0.20 | fraction of stoichiometric CCE | Lewis et al. 2021 [S1] — midpoint of reported CDR of 1.3–8.5 t CO₂/ha over 15 yr at 50 t/ha (≈ 26–170 kg CO₂ / t basalt against a stoichiometric ceiling of ~310). |
| `basalt$project_horizon_yr`    | 5    | years | ERW industry-standard accreditation window. Beerling 2020 [S2] (10 yr); Isometric / Puro.earth registries [S14]; 5 yr matches the year-by-year CDR phasing used in `erw-7`. |

**Notes.** Lewis 2021 [S1] is the load-bearing calibration anchor. Their temperate
humid-forest mesocosm gives effective reactivity ≈ 0.20 of the stoichiometric maximum at
reference grain × climate. Tropical climates and finer grain push the realised fraction
upward through `erw-9`'s climate factor and the grain-size factor.

### 1.4 Grinding-energy curve

| Code path | Default | Units | Source |
|---|---|---|---|
| `GRIND_REF_UM`        | 50    | µm | Anchor grain size of Strefler 2018 grinding-energy curve. |
| `GRIND_REF_GJ`        | 0.07  | GJ / t basalt | Strefler et al. 2018 [S4] — reported E(50 µm) ≈ 0.07 GJ/t. |
| `GRIND_ALPHA`         | 1.2   | dimensionless | Strefler 2018 [S4] — power-law exponent fitting E(2 µm) ≈ 3 GJ/t. Calibrated from the two anchor points. |
| `ELECTRICITY_USD_KWH` | 0.10  | $/kWh | Global default; overridden per-country by `erw-energy-country` raster in `erw-7`. |

**Notes.** Grinding energy is the second-largest cost lever after transport. The power
law E(d) = E_ref × (d_ref / d)^α with α=1.2 reproduces Strefler 2018's two anchor
points and is monotone in grain size. Energy is converted to $ at the script-local
default electricity price; `erw-7` overrides this with the country-level raster from
`erw-energy-country` when the latter has been run.

### 1.5 Stoichiometric conversion constants (derived in-script)

These are not user-tunable but the source of each is given for traceability:

- **CaO → CaCO₃-equivalent:** 1 g CaO neutralises 100.09 / 56.08 ≈ 1.783 g CaCO₃.
- **MgO → CaCO₃-equivalent:** 1 g MgO neutralises 100.09 / 40.30 ≈ 2.481 g CaCO₃.
- **CaO → CO₂ stoichiometric ceiling:** 1 g CaO consumes (2 × 44.01) / 56.08 ≈ 1.570 g CO₂.
- **MgO → CO₂ stoichiometric ceiling:** 1 g MgO consumes (2 × 44.01) / 40.30 ≈ 2.185 g CO₂.

These follow from the divalent-cation balance Ca²⁺ / Mg²⁺ + 2 HCO₃⁻ and assume
unidirectional export of bicarbonate, i.e. no pedogenic re-precipitation (the
pedogenic deduction lives in `erw-9`).

### 1.6 Uniform-rate scenarios

| Rate | t basalt / ha | Source |
|---|---|---|
| `basalt_uniform_10` | 10 | Beerling et al. 2020 Nature [S2]; Baek et al. 2023 [S5] |
| `basalt_uniform_20` | 20 | Common pilot rate; Eufrasio et al. 2022 [S6] |
| `basalt_uniform_50` | 50 | Kantola et al. 2023 [S7]; Lewis 2021 mesocosm rate [S1] |

These three uniform-rate rasters complement the LiTAS-targeted rate, giving four
allocation rules in `erw-7`.

---

## 2. `erw/erw-9-cdr-yield.R` — climate, pH, and pedogenic scaling

### 2.1 Climate reference anchor

| Code path | Default | Units | Source |
|---|---|---|---|
| `T_ref` | 11   | °C  | US Corn Belt 1991–2020 climate normal; Lewis 2021 [S1] mesocosm temperature regime. |
| `P_ref` | 1000 | mm  | US Corn Belt 1991–2020 MAP normal. |

**Notes.** The reference reactive fraction in `erw-3` (0.20) is anchored to this
temperate-humid climate. Tropical sites with MAT ≈ 25 °C and MAP ≈ 1500 mm push the
multiplicative climate factor toward ~3, consistent with the Sabah and InPlanet field
weathering rates [S8, S9].

### 2.2 Climate-factor functional form

```
f_climate = clamp(MAT / T_ref, 0.3, 3.0)
          × clamp(MAP / P_ref, 0.3, 3.0)
          × f_pH
```

Clamp bounds prevent runaway scaling at extreme grid cells and reflect the
empirical range over which the linear-multiplier approximation holds. Source: Kanzaki et
al. 2023 PNAS Nexus reactive-transport surrogates [S10]; this is a v1 proxy and should be
replaced by the full Kanzaki form when calibration data permits.

### 2.3 pH factor (triangular, peak ≈ 5.0)

```
ph < 4.0  → 0.5
ph 4.0–5.0 → linear 0.5 → 1.0
ph 5.0–7.0 → linear 1.0 → 0.5
ph > 7.0  → 0.5
```

**Source.** Acid-catalysed silicate dissolution literature: White & Brantley 2003 [S11];
Brantley et al. 2008 [S12]. Peak at pH ~5 is a defensible midpoint; calcareous soils
(pH > 7) suppress reactivity by ~half because the H⁺ activity is several orders of
magnitude lower.

### 2.4 Pedogenic-carbonate deduction

**Primary path (added 2026-05-26):** if `data/cgiar_aridity_index.tif` is
present (CGIAR-CSI Global Aridity Index, Zomer et al. 2022 [S37], 1 km, AI =
MAP / PET, integer-scaled by 10 000), `erw-9` keys the deduction directly on
AI and the integer scaling is auto-detected. Aridity bands (UNEP 1992 [S13]):

| AI = MAP/PET | Aridity class | `pedogenic_frac` |
|---|---|---|
| < 0.05 | Hyperarid | 0.90 |
| 0.05–0.20 | Arid | 0.70 |
| 0.20–0.50 | Semi-arid | 0.40 |
| 0.50–0.65 | Dry sub-humid | 0.15 |
| > 0.65 | Humid | 0.00 |

**Fallback path (used when the AI raster is absent):** MAP-only proxy. Same
class boundaries below, keyed on mean annual precipitation rather than AI.
This proxy over-deducts in cool highlands (Ethiopian/Kenyan highlands, Rwanda,
Burundi, Lesotho) where low PET keeps the true AI in the humid band even at
modest MAP.

| MAP (mm)      | Aridity class (UNEP 1992 [S13]) | `pedogenic_frac` |
|---|---|---|
| < 120 | Hyperarid (AI < 0.05)            | 0.90 |
| 120–300 | Arid (AI 0.05–0.20)             | 0.70 |
| 300–500 | Semi-arid (AI 0.20–0.50)        | 0.40 |
| 500–600 | Dry sub-humid (AI 0.50–0.65)    | 0.15 |
| > 600 | Humid (AI > 0.65)                  | 0.00 |

**Sources.**

- Beerling et al. 2020 Nature — pedogenic-carbonate caveat in SI [S2]
- Renforth 2019 Nature Communications [S15]
- Kanzaki et al. 2023 PNAS Nexus [S10]
- Reershemius & Suhrhoff 2024 GCB — uncertainty in ERW CDR-rate calculations [S16]
- UNEP 1992 aridity classification [S13]
- Zomer, Xu & Trabucco 2022 — Global Aridity Index v3 (CGIAR-CSI) [S37]

**Notes.** In semi-arid soils a substantial fraction of the alkalinity released by
silicate dissolution precipitates locally as CaCO₃/MgCO₃ rather than exporting as
bicarbonate. CaCO₃ precipitation releases the CO₂ originally consumed, so this fraction
must be deducted from gross CDR. Using MAP alone as the AI proxy is a known crude
approximation — it breaks down in cool highlands where PET is low. Replace with the
CGIAR-CSI Global Aridity Index (P/PET, 1 km) for production runs.

### 2.5 CDR per tonne basalt at a pixel (derived)

```
CDR_per_t_basalt(px) =
    CDR_max_stoich           # ~310 kg CO2 / t basalt
  × reactive_fraction_ref    # 0.20 from erw-3
  × grain_size_factor        # (100 / grain_size_um)^0.5
  × clamp(f_climate, ... )   # MAT, MAP, pH factors
  × (1 - pedogenic_frac)     # aridity-driven precipitation
```

The full per-pixel reactive fraction is capped at 1.0 (nothing reacts more than 100%).

---

## 3. `erw/erw-basalt-access.R` — feedstock supply and transport

| Code path | Default | Units | Source |
|---|---|---|---|
| `QUARRY_GATE_PRICE`     | 10   | $/t basalt fines | Beerling et al. 2020 [S2]; Strefler 2018 [S4]; UNEP 2019 [S17]. Basalt fines are typically a quarry by-product (range $5–40/t). |
| `USD_PER_MIN_PER_T`     | 0.04 | $/min/t | 30-t truck at $80/hr operating cost (van Essen 2019 EU truck CBA [S18]; AfDB rural-road operating-cost study 2020 [S19]). |
| `MAX_HAUL_KM`           | 1000 | km | Cap beyond which lifecycle emissions erode the CDR credit (Beerling 2020 SI [S2]; Beerling 2018 Nat. Plants [S20]). |
| `KM_PER_HOUR_FREE`      | 60   | km/h | Free-flow speed used only for the haul-distance cap. |
| `EFFECTIVE_KM_PER_MIN`  | 0.5  | km/min (≈30 km/h) | Avg effective speed for friction-surface-routed haulage (Weiss et al. 2020 MAP friction methodology [S21]). |

**External data sources.**

- **Basalt source mask:** Hartmann & Moosdorf 2012 GLiM v1.0 [S22] — basic volcanic class (xx = vb) and pyroclastics (xx = vp). DOI: 10.1594/PANGAEA.788537.
- **Friction surface:** Weiss et al. 2020 [S21] — MAP friction surface 2019, minutes per metre of land travel. Distributed via the malariaAtlas R package.

---

## 4. `erw/erw-energy-country.R` — country-level electricity & grid CI

Forty-three SSA-country values for industrial electricity price ($/kWh) and grid carbon
intensity (kg CO₂ / kWh), hard-coded in the script. Edit the data frame and re-run to
update.

**Sources.**

- Grid carbon intensity: Ember Climate Data Explorer 2023 [S23]; IEA Africa Energy Outlook 2022 [S24].
- Electricity tariffs: GET.invest tariff database 2022–2024 [S25]; AfDB country tariff snapshots 2024 [S19].

**Notes on the range.**

- Grid CI: 0.03 kg/kWh (Ethiopia, DRC, Mozambique — hydro-dominated) to 0.95 kg/kWh
  (South Africa — coal-dominated). The ~30× spread is the load-bearing factor in
  grinding-emissions LCA — the same project produces credits in Ethiopia but almost
  none in South Africa.
- Electricity: $0.05–0.40/kWh; Ethiopia is the cheapest and several West African
  utility-tariff islands (Cape Verde, Sierra Leone, Liberia) the most expensive.

Values are approximate at the resolution of country-level published data — calibrate
against latest IEA / Ember snapshots for a production run.

---

## 5. `erw/erw-7-profitability-function.R` — economics & LCA

### 5.1 Cost components (per tonne basalt)

| Code path | Default | Units | Source |
|---|---|---|---|
| `QUARRY_GATE_USD_T`      | 10   | $/t basalt | Strefler 2018 [S4]; Beerling 2020 SI [S2]; mid-range global aggregate-fines market. |
| `SPREADING_USD_T`        | 8    | $/t basalt | Beerling 2018 Nat. Plants [S20]; Eufrasio 2022 [S6]; reflects mechanised broadcast spreader. |
| `ELECTRICITY_USD_KWH_FB` | 0.10 | $/kWh | Fallback when `erw-energy-country` raster absent. World Bank 2022 industrial-tariff median for low-income countries [S26]. |
| `GRID_CI_KG_PER_KWH_FB`  | 0.60 | kg CO₂ / kWh | Fallback when `erw-energy-country` raster absent. Global coal-mix proxy (IEA 2022 [S24]). |
| `TRANSPORT_FLAT_USD_T`   | 20   | $/t basalt | Fallback at 100 km equivalent; matches Strefler 2018 [S4] mid-range. |
| `TRANSPORT_FLAT_KM`      | 100  | km | Fallback haul distance for LCA when access raster absent. |

### 5.2 Lifecycle emissions (per tonne basalt)

| Code path | Default | Units | Source |
|---|---|---|---|
| `TRUCK_KGCO2_PER_T_KM`   | 0.12 | kg CO₂ / (t · km) | EEA EMEP/CORINAIR Tier 1 — diesel heavy goods vehicle (HGV) [S27]; UK BEIS 2023 conversion factors [S28]. |
| `SPREADING_KGCO2_PER_T`  | 0.5  | kg CO₂ / t basalt | ≈0.1 L diesel per tonne spread; from EU-tractor LCA inventory Nemecek & Schnetzer 2011 [S29]. |

Per-tonne LCA decomposes as:

```
LCA(px) = grinding_kWh × grid_CI(px)
        + transport_km(px) × TRUCK_KGCO2_PER_T_KM
        + SPREADING_KGCO2_PER_T
```

### 5.3 Carbon market

| Code path | Default | Units | Source |
|---|---|---|---|
| `CARBON_PRICE_USD_T`   | 150 | $/t CO₂ | Mid of 2024–25 ERW credit market — Frontier Climate offtake [S30]; CDR.fyi public-price index 2025 [S31]. Range $80–500/tCO₂. |
| `MRV_COST_USD_T_CO2`   | 20  | $/t CO₂ | Sampling + lab + verification + registry. Levy et al. 2024 [S32] benchmarks $25–40/tCO₂ for current pilots; Isometric / Puro forecast $10–15/tCO₂ at scale once aggregator-pooled protocols industrialise. Default lowered from $30 → $20 on 2026-05-26 as a midpoint between "first-of-kind" and "at-scale 2027+". |
| `DISCOUNT_RATE_PCT`    | 10  | %       | Project-level assumption; not citation-backed. 10% is the conventional rate used in multilateral ag-investment appraisal but no single authoritative source is claimed here. |

### 5.4 Time-resolved CDR phasing

| Code path | Default | Units | Source |
|---|---|---|---|
| `CDR_PHASING` | c(.30, .25, .20, .15, .10) | year fractions | First-order-kinetics-shaped, 5-yr horizon, ~80% by year 5. Kanzaki et al. 2023 [S10]; Beerling 2020 SI [S2]. |
| `CDR_NPV_FACTOR` | derived (≈0.79 at 10% discount, 5-yr) | dimensionless | $\sum f_t / (1+r)^t \big/ \sum f_t$ — NPV adjustment vs upfront treatment. |

**Notes.** Used only in the `npv` regime, this factor captures the time-value loss of
crediting CDR that arrives over a 5-year tail rather than as an upfront cash flow at
year 0. The remainder (~10%) of the reactive material is the never-fully-reacted tail
and is conservatively dropped.

### 5.5 Allocation rules

`erw-7` runs four allocation rules: `targeted` (LiTAS rate from `erw-3`), and
`uniform_{10, 20, 50}` t/ha. The targeted branch also masks to acid pixels above each
crop's `ac_sat` tolerance (from `erw-4-crop-parameters.R`); the uniform branches
treat all cropland identically (matches Beerling/Baek/Kantola modelling convention).

### 5.6 Return regimes

| Regime | What it computes |
|---|---|
| `year1`       | One up-front application, agronomic return accumulated **undiscounted over the project horizon** (`project_horizon_yr`, default 5 yr) to match the cumulative basis on which `cdr_tha` already sits. Suitable as the simple "did this pay back over basalt residency" screen. Fix landed 2026-05-26 — prior behaviour credited a single season's agronomy against five years of CDR. |
| `npv`         | Agronomic return via `limer::NPV_lime` at 10% discount; CDR revenue × `CDR_NPV_FACTOR`. Reapplication interval = round(year1_rate / maintenance_rate). |
| `equilibrium` | Steady-state maintenance rate only; no NPV adjustment (steady-state assumption). |

---

## 6. `erw/erw-8-sensitivity-analysis.R` — sensitivity sweeps

Five sweeps over the `erw-7` economics. Each spans all three regimes (year1 / npv /
equilibrium) and all 23 SPAM crops.

| Sweep | Range / values | Source |
|---|---|---|
| **Prices**     | crop_mult × basalt_mult × carbon_price grid: each of {0.5, 0.75, 1, 1.25, 1.5, 2}; carbon ∈ {0, 50, 100, 150, 250} $/tCO₂ | Frontier offtake price range [S30]; FAOSTAT historical price volatility [S33] |
| **Yields**     | yield-factor ∈ seq(1, 2.5, 0.25)             | Yield-gap closure scenarios — Mueller et al. 2012 Nature [S34] |
| **MRV**        | MRV cost ∈ {0, 15, 30, 50, 80} $/tCO₂        | Levy et al. 2024 [S32] |
| **Grain size** | {10, 30, 50, 100, 200, 500} µm                | Strefler 2018 [S4]; Lewis 2021 [S1] |
| **Allocation** | {targeted, uniform_10, uniform_20, uniform_50} | This pipeline (matches Beerling 2020 [S2] and the four `erw-3` branches) |

---

## 7. `erw/erw-supply.R` — supply-constrained deployment

| Code path | Default | Units | Source |
|---|---|---|---|
| `SUPPLY_CAPS_MT` | c(1, 5, 10, 25, 50, 100, 250, 500, Inf) | Mt basalt / yr | Range from tiny pilot to "an order of magnitude above any realistic SSA capacity". |

**Ranking criterion.** Pixels are sorted descending by gross-margin per tonne of basalt
— equivalent to the LP-dual on the basalt supply constraint when basalt is the scarce
input. This is the correct rule when feedstock supply, not cropland, is the binding
constraint. See Beerling et al. 2020 Nature [S2] for the precedent of supply-curve
framing in ERW. Deployment masks are written at caps of 10, 50, and 250 Mt/yr.

---

## 8. `erw/erw-yield-fit.R` — Bayesian agronomic-uplift fit

Response variable: `log(yield_with_basalt / yield_control)` with known per-trial
standard error (measurement-error syntax via `brms::se()`).

| Prior | Distribution | Source / rationale |
|---|---|---|
| Intercept   | Normal(0.10, 0.20)  | ~10% baseline uplift, weakly informative. Aramburu Merlos 2023 [S35]. |
| `log_rate`  | Normal(0.05, 0.05)  | A doubling of rate → ~3.5% extra uplift. Beerling 2018 Nat. Plants [S20]. |
| `pH_baseline` | Normal(0, 0.05)   | Near zero on log scale per unit pH; small effect expected. |
| `MAT_C`     | Normal(0, 0.005)    | Per-°C effect; small. |
| `MAP_mm`    | Normal(0, 0.0005)   | Per-mm effect; very small. |
| `log_grain` | Normal(−0.05, 0.05) | Negative — finer grain → more uplift. Strefler 2018 [S4]. |
| Group SDs   | Exponential(5)      | Weakly regularising. |

**Methodological references.** Aramburu Merlos et al. 2023 Geoderma [S35] — meta-regression structure; Beerling et al. 2018 Nat. Plants [S20] — log-ratio response; Bürkner 2017 [S36] — `brms` hierarchical modelling.

**Trial dataset (`erw/erw-trial-data.csv`).** ~14 rows at v1, from temperate
mesocosms (Lewis 2021 [S1]), US Corn Belt (Kantola 2023 [S7]), Brazil InPlanet [S9],
Newcastle oats (Beerling 2018 [S20]), Swiss vineyards (Dupla et al. 2025 — see
erw-tutorial.md [7]), Kisumu smallholder maize (Haque et al. 2025 — see
erw-tutorial.md [6]), and various other mesocosms. Append rows as new ERW trials
publish and re-run `erw-yield-fit` → `erw-yield-predict`. Small-n caveat: the
posterior is heavily prior-dominated; the framework is in place but should not be
over-interpreted at v1.

---

## 9. `erw/erw-yield-predict.R` — per-pixel uplift rasters

Reads the `brmsfit` object from `erw-yield-fit.R` and applies posterior-mean fixed
effects plus per-crop random intercepts to per-pixel covariate rasters (pH, MAT, MAP,
log_grain). Produces `erw_yield_uplift_{crop}_median.tif` per crop, which `erw-7`
consumes in preference to the EcoCrop-derived response if present.

Optional uncertainty arm (commented out) loops over `posterior_epred` draws to
produce 5th/95th-percentile rasters; off by default for compute reasons.

---

## 10. Known unknowns / assumptions still to relax

These are documented in `docs/erw-README.md` under "What this pipeline still does not do".
Listed here for the parameter audit:

1. **EcoCrop fallback for yield response.** When `erw-yield-predict` outputs are
   absent, `erw-7` falls back to `erw-5`'s EcoCrop relative-yield curves. EcoCrop
   captures tolerance ranges, not basalt-specific agronomic uplift.
2. **CGIAR-CSI Global Aridity Index.** Pedogenic-carbonate deduction uses MAP alone as
   AI proxy. The 1 km global AI (P/PET) dataset would be a strict improvement.
3. **Compaction emissions and N₂O.** Heavy basalt traffic on cropland causes some
   soil compaction; tilling-in basalt fines may briefly elevate N₂O. Neither is
   modelled at v1.
4. **Country-level credit eligibility / Article 6.** Some SSA countries restrict export
   of carbon credits or have unresolved corresponding-adjustment rules. Not in scope.
5. **Tenure & aggregator finance.** Who pays the upfront ~$600/ha basalt cost, who
   owns the credit, and what aggregator structure makes MRV tractable for smallholders
   is unmodelled.

---

## Sources

The full citation list referenced by the tables above.

<a id="sources"></a>

- **[S1]** Lewis, A. L., Sarkar, B., Wade, P., Kemp, S. J., Hodson, M. E., Taylor, L. L., Yeong, K. L., Davies, K., Nelson, P. N., Bird, M. I., Kantola, I. B., Masters, M. D., DeLucia, E. H., Leake, J. R., Banwart, S. A., & Beerling, D. J. (2021). Effects of mineralogy, chemistry and physical properties of basalts on carbon capture potential and plant-nutrient element release via enhanced weathering. *Applied Geochemistry*, 132, 105023. https://doi.org/10.1016/j.apgeochem.2021.105023
- **[S2]** Beerling, D. J., Kantzas, E. P., Lomas, M. R., Wade, P., Eufrasio, R. M., Renforth, P., Sarkar, B., Andrews, M. G., James, R. H., Pearce, C. R., Mercure, J.-F., Pollitt, H., Holden, P. B., Edwards, N. R., Khanna, M., Koh, L., Quegan, S., Pidgeon, N. F., Janssens, I. A., … Banwart, S. A. (2020). Potential for large-scale CO₂ removal via enhanced rock weathering with croplands. *Nature*, 583, 242–248. https://doi.org/10.1038/s41586-020-2448-9
- **[S3]** Dupla, X., Möller, B., Baveye, P. C., & Grand, S. (2023). Potential accumulation of toxic trace elements in soils during enhanced rock weathering. *European Journal of Soil Science*, 74(2). https://doi.org/10.1111/ejss.13343
- **[S4]** Strefler, J., Amann, T., Bauer, N., Kriegler, E., & Hartmann, J. (2018). Potential and costs of carbon dioxide removal by enhanced weathering of rocks. *Environmental Research Letters*, 13(3), 034010. https://doi.org/10.1088/1748-9326/aaa9c4
- **[S5]** Baek, S. H., Kanzaki, Y., Lora, J. M., Planavsky, N., Reinhard, C. T., & Zhang, S. (2023). Impact of climate on the global capacity for enhanced rock weathering on croplands. *Earth's Future*, 11. https://doi.org/10.1029/2023EF003698
- **[S6]** Eufrasio, R. M., Kantzas, E. P., Edwards, N. R., Holden, P. B., Pollitt, H., Mercure, J.-F., Koh, S. C. L., & Beerling, D. J. (2022). Environmental and health impacts of atmospheric CO₂ removal by enhanced rock weathering depend on nations' energy mix. *Communications Earth & Environment*, 3, 106. https://doi.org/10.1038/s43247-022-00436-3
- **[S7]** Kantola, I. B., Blanc-Betes, E., Masters, M. D., Chang, E., Marklein, A., Moore, C. E., von Haden, A., Bernacchi, C. J., Wolf, A., Epihov, D. Z., Beerling, D. J., & DeLucia, E. H. (2023). Improved net carbon budgets in the U.S. Midwest through direct measured impacts of enhanced weathering. *Global Change Biology*, 29(24), 7012–7028. https://doi.org/10.1111/gcb.16903
- **[S8]** Larkin, C. S., Andrews, M. G., Pearce, C. R., Yeong, K. L., Beerling, D. J., Bellamy, J., Benedick, S., Freckleton, R. P., Goring-Harford, H., Sadekar, S., & James, R. H. (2022). Quantification of CO₂ removal in a large-scale enhanced weathering field trial on an oil palm plantation in Sabah, Malaysia. *Frontiers in Climate*, 4, 959229. https://doi.org/10.3389/fclim.2022.959229
- **[S9]** InPlanet (2024). Basalt-ERW field trial results, Brazil. Open data release. https://www.inplanet.earth/science (accessed 2025).
- **[S10]** Kanzaki, Y., Planavsky, N. J., & Reinhard, C. T. (2023). New estimates of the storage permanence and ocean co-benefits of enhanced rock weathering. *PNAS Nexus*, 2(4), pgad059. https://doi.org/10.1093/pnasnexus/pgad059
- **[S11]** White, A. F., & Brantley, S. L. (2003). The effect of time on the weathering of silicate minerals: why do weathering rates differ in the laboratory and field? *Chemical Geology*, 202(3–4), 479–506. https://doi.org/10.1016/j.chemgeo.2003.03.001
- **[S12]** Brantley, S. L., Kubicki, J. D., & White, A. F. (Eds.) (2008). *Kinetics of Water-Rock Interaction*. Springer. https://doi.org/10.1007/978-0-387-73563-4
- **[S13]** UNEP (1992). *World Atlas of Desertification*. United Nations Environment Programme, London: Edward Arnold. (Aridity-index categorisation used worldwide.)
- **[S14]** Isometric (2024). *Enhanced Weathering in Agriculture v1.1*. https://registry.isometric.com/protocol/enhanced-weathering-agriculture/1.1 (accessed 2025)
- **[S15]** Renforth, P. (2019). The negative emission potential of alkaline materials. *Nature Communications*, 10, 1401. https://doi.org/10.1038/s41467-019-09475-5
- **[S16]** Reershemius, T., & Suhrhoff, T. J. (2024). On error, uncertainty, and assumptions in calculating carbon dioxide removal rates by enhanced rock weathering in Kantola et al., 2023. *Global Change Biology*, 30(1), e17025. https://doi.org/10.1111/gcb.17025
- **[S17]** UNEP (2019). *Sand and Sustainability — Finding new solutions for environmental governance of global sand resources*. https://www.unep.org/resources/report/sand-and-sustainability-finding-new-solutions-environmental-governance-global
- **[S18]** van Essen, H., et al. (2019). *Handbook on the external costs of transport — Version 2019*. European Commission. https://op.europa.eu/en/publication-detail/-/publication/9781f65f-8448-11ea-bf12-01aa75ed71a1
- **[S19]** African Development Bank (2020–2024). *African Economic Outlook* annuals — country tariff and operating-cost snapshots. https://www.afdb.org/en/knowledge/publications/african-economic-outlook
- **[S20]** Beerling, D. J., Leake, J. R., Long, S. P., Scholes, J. D., Ton, J., Nelson, P. N., Bird, M., Kantzas, E., Taylor, L. L., Sarkar, B., Kelland, M., DeLucia, E., Kantola, I., Müller, C., Rau, G., & Hansen, J. (2018). Farming with crops and rocks to address global climate, food and soil security. *Nature Plants*, 4, 138–147. https://doi.org/10.1038/s41477-018-0108-y
- **[S21]** Weiss, D. J., Nelson, A., Vargas-Ruiz, C. A., Gligorić, K., Bavadekar, S., Gabrilovich, E., Bertozzi-Villa, A., Rozier, J., Gibson, H. S., Shekel, T., Kamath, C., Lieber, A., Schulman, K., Shao, Y., Qarkaxhija, V., Nandi, A. K., Keddie, S. H., Rumisha, S., Amratia, P., … Gething, P. W. (2020). Global maps of travel time to healthcare facilities. *Nature Medicine*, 26, 1835–1838. https://doi.org/10.1038/s41591-020-1059-1
- **[S22]** Hartmann, J., & Moosdorf, N. (2012). The new global lithological map database GLiM: A representation of rock properties at the Earth surface. *Geochemistry, Geophysics, Geosystems*, 13(12), Q12004. https://doi.org/10.1029/2012GC004370 (Data: https://doi.pangaea.de/10.1594/PANGAEA.788537)
- **[S23]** Ember (2024). *Yearly Electricity Data — 2023 release*. https://ember-energy.org/data/data-explorer/
- **[S24]** International Energy Agency (2022). *Africa Energy Outlook 2022*. https://www.iea.org/reports/africa-energy-outlook-2022
- **[S25]** GET.invest (2022–2024). *Country fact sheets — electricity tariffs and grid characteristics*. EU initiative for renewable energy investment in Africa, the Caribbean and the Pacific. https://www.get-invest.eu/
- **[S26]** World Bank (2019). *Doing Business — Getting Electricity* (final data collection May 2019; series discontinued 2021). Tariff series for low-income countries. https://archive.doingbusiness.org/en/data/exploretopics/getting-electricity
- **[S27]** European Environment Agency (2023). *EMEP/EEA air pollutant emission inventory guidebook — Road transport*. https://www.eea.europa.eu/publications/emep-eea-guidebook-2023
- **[S28]** UK Department for Energy Security and Net Zero (BEIS) (2023). *Greenhouse gas reporting: conversion factors 2023*. https://www.gov.uk/government/publications/greenhouse-gas-reporting-conversion-factors-2023
- **[S29]** Nemecek, T., & Schnetzer, J. (2011). *Methods of assessment of direct field emissions for LCIs of agricultural production systems*. Agroscope Reckenholz-Tänikon Research Station ART.
- **[S30]** Frontier Climate (2024). *Offtake and prepurchase agreements — ERW transactions*. https://frontierclimate.com/writing (accessed 2025)
- **[S31]** CDR.fyi (2025). *Carbon Dioxide Removal Public Database — price index*. https://www.cdr.fyi/
- **[S32]** Levy, C. R., Almaraz, M., Beerling, D. J., Raymond, P., Reinhard, C. T., Suhrhoff, T. J., & Taylor, L. (2024). Enhanced rock weathering for carbon removal — monitoring and mitigating potential environmental impacts on agricultural land. *Environmental Science & Technology*, 58(39), 17215–17226. https://doi.org/10.1021/acs.est.4c02368
- **[S33]** FAO (2023). *FAOSTAT Producer Prices — annual, 2016–2020 series for SSA countries × 23 SPAM crops*. https://www.fao.org/faostat/en/#data/PP (accessed 2023-04-24; local export `data/FAOSTAT_data_en_4-24-2023.csv`).
- **[S34]** Mueller, N. D., Gerber, J. S., Johnston, M., Ray, D. K., Ramankutty, N., & Foley, J. A. (2012). Closing yield gaps through nutrient and water management. *Nature*, 490, 254–257. https://doi.org/10.1038/nature11420
- **[S35]** Aramburu Merlos, F., Silva, J. V., Baudron, F., & Hijmans, R. J. (2023). Estimating lime requirements for tropical soils: Model comparison and development. *Geoderma*, 432, 116421. https://doi.org/10.1016/j.geoderma.2023.116421
- **[S36]** Bürkner, P.-C. (2017). brms: An R package for Bayesian multilevel models using Stan. *Journal of Statistical Software*, 80(1), 1–28. https://doi.org/10.18637/jss.v080.i01
- **[S37]** Zomer, R. J., Xu, J., & Trabucco, A. (2022). Version 3 of the Global Aridity Index and Potential Evapotranspiration Database. *Scientific Data*, 9, 409. https://doi.org/10.1038/s41597-022-01493-1 (data: https://doi.org/10.6084/m9.figshare.7504448)

---

## Change log

- **2026-05-13** — Initial version. Captures every constant in `erw-*.R` as shipped at this date.
- **2026-05-26** — Re-anchored five defaults after a structural review of model conservatism:
  - `basalt$grain_size_um` 100 → 50 µm (Strefler anchor; cost-minimising at carbon revenue ≥ 0).
  - `MRV_COST_USD_T_CO2` 30 → 20 $/tCO₂ (midpoint of pilot vs. at-scale).
  - `year1` regime now scales agronomic return by `project_horizon_yr` to match `cdr_tha`'s cumulative basis (was silently crediting 1 yr of agronomy against 5 yr of CDR).
  - `erw-4`'s `max_ph` upper-bound generalised from a flat 5.5 to per-crop EcoCrop optima (cereals 7.0–7.5; legumes 6.8–8.0; tea 5.5; cocoa 6.0).
  - Pedogenic-carbonate deduction now consumes the CGIAR-CSI Global Aridity Index raster when present at `data/cgiar_aridity_index.tif`; falls back to the MAP-only proxy otherwise.
