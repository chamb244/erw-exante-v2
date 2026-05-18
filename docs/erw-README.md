# ERW pipeline — runbook

Geospatial ex-ante profitability model for Enhanced Rock Weathering with
basalt in Sub-Saharan Africa. Combines a SoilGrids/SPAM working grid,
feedstock-chemistry-aware basalt application rates, climate-and-aridity-scaled
CDR yield, decomposed costs with per-pixel lifecycle emissions, MRV
deduction, time-resolved CDR, and a supply-constrained deployment ranking.

## Files

| File                                | Purpose                                                                                            |
|-------------------------------------|----------------------------------------------------------------------------------------------------|
| `erw-0-install-packages.R`          | Bootstrap R dependencies.                                                                          |
| `erw-1-layers-soilgrids.R`          | SSA mask + SoilGrids depth-weighted soil-property stack, masked to cropland.                       |
| `erw-2-layers-spam.R`               | SPAM area / production / yield rasters for 23 crops on the working grid.                           |
| `erw-3-basalt-requirements.R`       | CaCO3-equivalent lime rates via `limer::limeRate`, then converted to t basalt/ha with grain-size lever, Lewis-2021 reactivity calibration, uniform-rate options.|
| `erw-4-crop-parameters.R`           | Per-crop EcoCrop pH and acidity-saturation tolerance tables.                                       |
| `erw-5-crop-yield-loss-function.R`  | Per-crop relative-yield rasters from `Recocrop::ecocrop`.                                          |
| `erw-9-cdr-yield.R`                 | Climate-, pH-, and aridity-scaled CDR yield per pixel; pedogenic carbonate deducted.               |
| `erw-basalt-access.R`               | Cost-distance from basalt outcrops → delivered price + transport-km rasters.                       |
| `erw-energy-country.R`              | Per-country electricity price + grid CI rasters for SSA. Drives spatially-varying grinding economics.|
| `erw-yield-fit.R`                   | Bayesian hierarchical fit of log yield-ratio on the trial dataset.                                 |
| `erw-yield-predict.R`               | Per-crop yield-uplift rasters from the brmsfit posterior.                                          |
| `erw-7-profitability-function.R`    | Decomposed cost, derived LCA, MRV deduction, time-resolved CDR, four allocation rules.             |
| `erw-8-sensitivity-analysis.R`      | Five sweeps: prices × MRV × yields × grain size × allocation rule.                                 |
| `erw-supply.R`                      | Supply-constrained deployment ranking — produces supply-curve CSVs and deployment-mask rasters.    |

## Run order

```
erw-0 → erw-1 → erw-2 → erw-3 → erw-4 → erw-5
                          │
                          ▼
                       erw-9   (CDR yield, climate + pedogenic carbonate)
                          │
            ┌─────────────┼──────────────────────┐
            ▼             ▼                      ▼
      erw-basalt-access  erw-energy-country  (erw-yield-fit → erw-yield-predict, optional)
            │             │                      │
            └─────────────┼──────────────────────┘
                          ▼
                       erw-7   (profitability — decomposed costs + time-resolved CDR)
                          │
            ┌─────────────┼──────────────┐
            ▼             ▼              ▼
       erw-8           erw-supply        (headline figures — TODO)
       (sensitivity)   (supply curves)
```

`erw-basalt-access`, `erw-energy-country`, and `erw-yield-predict` are
optional sibling inputs. `erw-7` auto-detects each — falls back to flat
constants or EcoCrop yield-loss when their output rasters are missing.

## Key constants — where they live and what they default to

| Constant                       | File                  | Default          | Source / role                                              |
|--------------------------------|-----------------------|------------------|------------------------------------------------------------|
| `basalt$CaO_frac`              | `erw-3`               | 0.10             | Typical tropical basalt; per-quarry override.              |
| `basalt$MgO_frac`              | `erw-3`               | 0.07             | "                                                          |
| `basalt$grain_size_um`         | `erw-3`               | 100              | **Decision variable.** Sweeps available in `erw-8`.        |
| `reactive_fraction_ref`        | `erw-3`               | 0.20             | **Lewis 2021 calibration** at reference grain × climate.   |
| `GRAIN_BETA`                   | `erw-3`               | 0.5              | Surface-area exponent for grain-size factor.               |
| `GRIND_ALPHA`                  | `erw-3`               | 1.2              | Strefler 2018 grinding-energy exponent.                    |
| `T_ref`, `P_ref`               | `erw-9`               | 11 °C, 1000 mm   | US Corn Belt climate anchor.                               |
| pedogenic_frac thresholds      | `erw-9`               | UNEP aridity     | UNEP 1992 categories; uses MAP as v1 proxy for P/PET.      |
| `QUARRY_GATE_USD_T`            | `erw-7`               | $10/t            | Basalt fines as quarry by-product.                         |
| `SPREADING_USD_T`              | `erw-7`               | $8/t             | On-farm spreading.                                         |
| `ELECTRICITY_USD_KWH_FB`       | `erw-7`               | $0.10/kWh        | Fallback when country raster missing.                      |
| `GRID_CI_KG_PER_KWH_FB`        | `erw-7`               | 0.60 kg/kWh      | Fallback when country raster missing.                      |
| `TRUCK_KGCO2_PER_T_KM`         | `erw-7`               | 0.12             | Diesel heavy truck.                                        |
| `CARBON_PRICE_USD_T`           | `erw-7`               | $150/tCO2        | Mid of 2024-25 ERW credit market.                          |
| `MRV_COST_USD_T_CO2`           | `erw-7`               | $30/tCO2         | Sampling + lab + verification + registry.                  |
| `DISCOUNT_RATE_PCT`            | `erw-7`               | 10%              | For NPV regime.                                            |
| `CDR_PHASING`                  | `erw-7`               | c(.30,.25,.20,.15,.10) | 5-year phased CDR realisation.                       |
| `QUARRY_GATE_PRICE`            | `erw-basalt-access`   | $10/t            | Default ex-quarry price.                                   |
| `USD_PER_MIN_PER_T`            | `erw-basalt-access`   | $0.04/min/t      | 30-t truck at $80/hr operating cost.                       |
| `EFFECTIVE_KM_PER_MIN`         | `erw-basalt-access`   | 0.5              | Avg 30 km/h, accounts for slow-segment routing.            |
| `MAX_HAUL_KM`                  | `erw-basalt-access`   | 1000             | Beyond this, lifecycle emissions erode the credit.         |
| `SUPPLY_CAPS_MT`               | `erw-supply`          | 1 … ∞ Mt/yr      | Supply scenarios for the deployment ranking.               |

## Output schema

### From `erw-7` — `economics_erw/{allocation_rule}/{crop}_{regime}.tif`

`{allocation_rule}` ∈ `{targeted, uniform_10, uniform_20, uniform_50}`,
`{regime}` ∈ `{year1, npv, equilibrium}`. Total: 4 × 3 × 23 = 276 rasters.

Each raster contains:

| Layer                       | Units      | What                                               |
|-----------------------------|------------|----------------------------------------------------|
| `{crop}_ha`                 | ha         | SPAM harvested area                                |
| `{crop}_ya`                 | t/ha       | Actual yield (SPAM)                                |
| `{crop}_loss`               | 0–1        | Relative yield from EcoCrop                        |
| `{crop}_yresp_tha`          | t/ha       | Yield response to acidity correction               |
| `{crop}_agro_return_usha`   | $/ha       | Agronomic return                                   |
| `{crop}_basalt_tha`         | t/ha       | Basalt application rate                            |
| `{crop}_basalt_cost_usha`   | $/ha       | Decomposed basalt cost                             |
| `{crop}_cdr_gross_tha`      | t CO2/ha   | Gross CDR (cumulative over project horizon)        |
| `{crop}_cdr_net_tha`        | t CO2/ha   | Net of LCA emissions                               |
| `{crop}_cdr_revenue_usha`   | $/ha       | CDR revenue (NPV-discounted in `npv` regime)       |
| `{crop}_gm_combined_usha`   | $/ha       | Agronomic + CDR − basalt cost                      |
| `{crop}_gm_agro_only_usha`  | $/ha       | Agronomic-only GM                                  |
| `{crop}_gm_cdr_only_usha`   | $/ha       | CDR-only GM                                        |
| `{crop}_roi_combined`       | ratio      | (Agro return + CDR rev) / basalt cost              |

### From `erw-8` — CSVs in `output-data/`

- `output-erw-sensitivity-prices.csv` — crop × basalt × carbon-price grid
- `output-erw-sensitivity-yields.csv` — yield factor 1.0–2.5
- `output-erw-sensitivity-mrv.csv` — MRV cost 0–80 $/tCO2
- `output-erw-sensitivity-grain.csv` — grain size 10/30/50/100/200/500 µm
- `output-erw-sensitivity-allocation.csv` — targeted vs uniform_{10,20,50}

### From `erw-supply` — supply-curve CSVs + deployment masks

- `supply_curve_{regime}.csv` — supply cap → marginal GM, deployed ha, delivered CDR
- `deployment_under_{cap}_Mt_{regime}.tif` — 1/NA mask at selected caps
- `gm_per_t_basalt_{regime}.tif` — the ranking variable, useful for diagnostics

### From `erw-9` — physical-rate rasters

- `cdr_yield_merlos.tif`, `cdr_yield_merlos_maintenance.tif` (targeted)
- `cdr_yield_uniform_{10,20,50}.tif` (uniform)
- `cdr_climate_factor.tif`, `cdr_pedogenic_fraction.tif`, `cdr_per_t_basalt.tif`

### From `erw-energy-country` — country-level energy rasters

- `electricity_usd_kWh.tif` — industrial tariff
- `grid_CI_kg_per_kWh.tif` — grid carbon intensity
- `country_energy_table.csv` — editable source table

### From `erw-basalt-access` — feedstock-access rasters

- `basalt_source_mask.tif` — basalt source mask from GLiM
- `basalt_traveltime_min.tif` — cost-distance from sources
- `basalt_transport_km.tif` — approximate haul distance
- `basalt_transport_cost_usd_t.tif` — transport $/t
- `basalt_delivered_price_usd_t.tif` — full delivered price (quarry + transport)

## What this pipeline still does *not* do

- **Bayesian yield response** is wired up (`erw-yield-fit` → `erw-yield-predict`)
  but the dataset is small (~14 trials). `erw-7` falls back to EcoCrop tolerance
  curves from `erw-5` when the uplift rasters are absent.
- **CGIAR-CSI Global Aridity Index.** The pedogenic-carbonate deduction in
  `erw-9` uses MAP alone as a proxy for AI = P/PET. The right upgrade is the
  1 km global aridity dataset.
- **Compaction emissions and N2O.** Heavy basalt traffic on cropland causes
  some compaction; tilling-in basalt fines may also elevate N2O briefly.
  Neither is modelled.
- **Country-level credit eligibility / Article 6.** Some SSA countries restrict
  export of carbon credits or have unresolved corresponding-adjustment rules.
- **Tenure and aggregator finance structure.** Who pays the upfront $600/ha
  basalt cost, who owns the credit, and what aggregator structure makes MRV
  tractable for smallholders is unmodelled.

## Headline analyses to produce

1. **SSA-wide profitable-area map** under each allocation rule and regime,
   separated by agronomic-only / CDR-only / combined drivers.
2. **Per-country totals** of profitable ha, total GM, and total CDR (Mt CO2).
3. **Break-even surfaces.** Minimum carbon price needed for combined GM > 0,
   as a function of soil acidity and crop, at fixed basalt cost.
4. **Supply curves.** Marginal $/tCO2 and marginal pixel GM as basalt supply
   ramps from pilot (1 Mt/yr) to large scale (100+ Mt/yr).
5. **Grain-size optimum.** Per-pixel grain size that minimises $/tCO2 net of
   grinding emissions. Likely lands at 30–80 µm in most of SSA.

## Known portability issues

All scripts hard-code `D:/# Jvasco/...` Windows paths. Edit `input_path` and
`output_path` at the top of each file when running on a different host. None
of the scripts are runnable on this Mac without the upstream SoilGrids /
SPAM / FAOSTAT / WorldClim / GLiM / MAP-friction data being downloaded.
