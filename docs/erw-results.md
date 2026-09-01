# Profitability under different assumptions

This is a focused results dashboard. It complements `erw-model.md` (full
methodology) and `erw-tutorial.md` (worked example). All figures and tables
below are generated from the 276 gross-margin rasters under
`data/economics_erw/` by `erw/erw-10-profitability-maps-tables.R`.

**Scope:** Sub-Saharan Africa, 23 SPAM crops, 0.083° working grid.
**Regimes:** year-1 (one application, agronomic + CDR revenue in year 1) ·
NPV @ 10 % (CDR revenue phased over 5 years, agronomic returns over the
reapplication interval) · equilibrium (steady-state maintenance dose).
**Allocations:** `targeted` (LiTAS dose only on acid pixels above each crop's
tolerance) · `uniform_10` / `uniform_20` / `uniform_50` (uniform t basalt / ha
across all cropland regardless of soil acidity).
**Model basis (refreshed 2026-09-01):** Arrhenius temperature factor
($E_a$ = 68.8 kJ/mol, headline; linear retained as sensitivity), triangular
soil-pH factor peaking at **pH 6.0** (was 5.0), yield-sensitivity sweep capped
at 1.8×. All maps and tables below are from the 2026-09-01 run.
**Default parameters (set 2026-05-26):** carbon price \$150 / tCO₂,
MRV **\$20 / tCO₂** (lowered from \$30), **grain size 50 µm** (lowered from
100 µm; the Strefler grinding-curve anchor), \$10 / t quarry gate,
country-level electricity tariffs and grid CI, spatial delivered-transport
costs, year-1 agronomic return **summed over the 5-year basalt residency**
(was a single-season figure), CGIAR-CSI Global Aridity Index for the
pedogenic deduction, per-crop EcoCrop max-pH cliffs (range 5.5–8.0).

---

## 1. Continent-wide gross margin

Each map below shows the crop-weighted average gross margin per hectare
(\$ / ha) at the 0.083° pixel — weighted by harvested area across the 23 crops
sharing that pixel. Green pixels are profitable; red are loss-making.

### 1.1 By return regime (LiTAS-targeted allocation)

| Year-1 | NPV @ 10 % | Equilibrium |
|:-:|:-:|:-:|
| ![](maps/profitability/ssa_gm_year1_targeted.png){width=2in} | ![](maps/profitability/ssa_gm_npv_targeted.png){width=2in} | ![](maps/profitability/ssa_gm_equilibrium_targeted.png){width=2in} |

### 1.2 By allocation rule (NPV regime)

| Targeted | Uniform 10 t/ha | Uniform 20 t/ha | Uniform 50 t/ha |
|:-:|:-:|:-:|:-:|
| ![](maps/profitability/ssa_gm_npv_targeted.png){width=1.6in} | ![](maps/profitability/ssa_gm_npv_uniform_10.png){width=1.6in} | ![](maps/profitability/ssa_gm_npv_uniform_20.png){width=1.6in} | ![](maps/profitability/ssa_gm_npv_uniform_50.png){width=1.6in} |

The targeted allocation prunes the action set to acidic pixels and pays the
LiTAS-calibrated dose; uniform rules pay a fixed rate across all cropland and
recover CDR even on near-neutral soils that the targeted rule skips.

---

## 2. Profitable footprint

Binary masks showing where the crop-weighted GM is strictly positive. These
are the candidate pixels for the supply-ranked deployment in `erw-supply`.

| | Targeted | Uniform 10 | Uniform 20 | Uniform 50 |
|---|:-:|:-:|:-:|:-:|
| Year-1 | ![](maps/profitability/profitable_mask_year1_targeted.png){width=1.4in} | ![](maps/profitability/profitable_mask_year1_uniform_10.png){width=1.4in} | ![](maps/profitability/profitable_mask_year1_uniform_20.png){width=1.4in} | ![](maps/profitability/profitable_mask_year1_uniform_50.png){width=1.4in} |
| NPV | ![](maps/profitability/profitable_mask_npv_targeted.png){width=1.4in} | ![](maps/profitability/profitable_mask_npv_uniform_10.png){width=1.4in} | ![](maps/profitability/profitable_mask_npv_uniform_20.png){width=1.4in} | ![](maps/profitability/profitable_mask_npv_uniform_50.png){width=1.4in} |
| Equilibrium | ![](maps/profitability/profitable_mask_equilibrium_targeted.png){width=1.4in} | ![](maps/profitability/profitable_mask_equilibrium_uniform_10.png){width=1.4in} | ![](maps/profitability/profitable_mask_equilibrium_uniform_20.png){width=1.4in} | ![](maps/profitability/profitable_mask_equilibrium_uniform_50.png){width=1.4in} |

---

## 3. Breakeven carbon price

For each pixel, the minimum carbon price (\$ / tCO₂) that drives crop-weighted
GM to zero, holding all other defaults constant (MRV \$20 / tCO₂, grain size
50 µm, etc.). Pixels with no CDR potential are masked; the legend caps at
\$500 / tCO₂ for legibility.

| Year-1 | NPV @ 10 % | Equilibrium |
|:-:|:-:|:-:|
| ![](maps/profitability/breakeven_carbon_year1_targeted.png){width=2in} | ![](maps/profitability/breakeven_carbon_npv_targeted.png){width=2in} | ![](maps/profitability/breakeven_carbon_equilibrium_targeted.png){width=2in} |

The equilibrium regime tends to need higher carbon prices because the
maintenance dose recurs forever, while year-1 / NPV amortise the up-front
agronomic uplift against a single application.

---

## 4. Per-crop gross margin (selected crops, targeted)

The five highest-acreage crops, year-1 and NPV regimes:

| Crop | Year-1 | NPV @ 10 % |
|---|:-:|:-:|
| Maize (MAIZ) | ![](maps/profitability/crop_gm_MAIZ_year1_targeted.png){width=2.4in} | ![](maps/profitability/crop_gm_MAIZ_npv_targeted.png){width=2.4in} |
| Sorghum (SORG) | ![](maps/profitability/crop_gm_SORG_year1_targeted.png){width=2.4in} | ![](maps/profitability/crop_gm_SORG_npv_targeted.png){width=2.4in} |
| Cassava (CASS) | ![](maps/profitability/crop_gm_CASS_year1_targeted.png){width=2.4in} | ![](maps/profitability/crop_gm_CASS_npv_targeted.png){width=2.4in} |
| Groundnut (GROU) | ![](maps/profitability/crop_gm_GROU_year1_targeted.png){width=2.4in} | ![](maps/profitability/crop_gm_GROU_npv_targeted.png){width=2.4in} |
| Wheat (WHEA) | ![](maps/profitability/crop_gm_WHEA_year1_targeted.png){width=2.4in} | ![](maps/profitability/crop_gm_WHEA_npv_targeted.png){width=2.4in} |

---

## 5. SSA-wide totals — one row per regime × allocation

Aggregates are summed across all 23 crops, all pixels (no positive-GM filter
unless the column says "profitable"). Source: `docs/tables/output-ssa-summary.csv`.

```{=latex}
\begin{small}
```

| Regime | Allocation | Total GM (M\$) | Agro return (M\$) | Basalt cost (M\$) | CDR revenue (M\$) | Total CDR (Mt) | Profitable area (Mha) | CDR on profitable (Mt) |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| year1 | targeted | 12,371 | 30,220 | 21,545 | 4,483 | 34.5 | 7.36 | 25.6 |
| year1 | uniform_10 | 14,357 | 30,220 | 75,918 | 11,512 | 88.6 | 10.61 | 1.1 |
| year1 | uniform_20 | 1,422 | 30,220 | 151,836 | 27,978 | 215.2 | 8.07 | 7.6 |
| year1 | uniform_50 | -25,337 | 30,220 | 379,591 | 92,169 | 709.0 | 6.65 | 50.5 |
| npv | targeted | -5,926 | 12,030 | 21,545 | 3,560 | 34.5 | 2.55 | 16.9 |
| npv | uniform_10 | -10,548 | 5,494 | 75,918 | 9,142 | 88.6 | 3.23 | 0.4 |
| npv | uniform_20 | -24,285 | 5,494 | 151,836 | 22,218 | 215.2 | 1.86 | 2.4 |
| npv | uniform_50 | -55,929 | 5,494 | 379,591 | 73,196 | 709.0 | 1.98 | 19.3 |
| equilibrium | targeted | 1,772 | 6,044 | 7,364 | 3,248 | 25.0 | 6.45 | 12.4 |
| equilibrium | uniform_10 | -3,774 | 6,044 | 75,918 | 17,967 | 138.2 | 7.75 | 15.7 |
| equilibrium | uniform_20 | -11,850 | 6,044 | 151,836 | 40,188 | 309.1 | 6.32 | 29.2 |
| equilibrium | uniform_50 | -36,049 | 6,044 | 379,591 | 107,153 | 824.2 | 4.92 | 63.2 |

```{=latex}
\end{small}
```

---

## 6. Top crops by aggregate gross margin (NPV regime)

The full crop × regime × allocation matrix is in
`docs/tables/output-crop-ranking.csv`. Below: the top eight crops by total GM
under the NPV-targeted scenario.

```{=latex}
\begin{small}
```

| Rank | Crop | Total GM (M\$) | Profitable area (Mha) | Total CDR (Mt) |
|--:|---|--:|--:|--:|
| 1 | POTA | 731 | 0.26 | 1.42 |
| 2 | BEAN | 594 | 0.78 | 10.41 |
| 3 | GROU | 435 | 0.68 | 7.57 |
| 4 | LENT | 18 | 0.01 | 0.04 |
| 5 | CHIC | -0 | 0.01 | 0.06 |
| 6 | TEAS | -1 | 0.00 | 0.00 |
| 7 | TOBA | -6 | 0.01 | 0.02 |
| 8 | BARL | -13 | 0.00 | 0.07 |

```{=latex}
\end{small}
```

---

## 7. Country breakdown — NPV, targeted (top 12 by GM)

Full per-country table for all regime × allocation combinations:
`docs/tables/output-country-summary.csv` (528 rows = 44 countries × 12
scenarios). Below: the top dozen by aggregate GM in the NPV-targeted scenario.

```{=latex}
\begin{small}
```

| Rank | ISO3 | GM (M\$) | Profitable area (Mha) | Total CDR (Mt) |
|--:|---|--:|--:|--:|
| 1 | CMR | 2,602 | 0.64 | 10.66 |
| 2 | GIN | 362 | 0.32 | 1.99 |
| 3 | RWA | 103 | 0.23 | 0.50 |
| 4 | ZAF | 19 | 0.06 | 0.00 |
| 5 | BWA | 0 | 0.00 | 0.00 |
| 6 | DJI | 0 | 0.00 | 0.00 |
| 7 | ERI | 0 | 0.00 | 0.00 |
| 8 | GMB | 0 | 0.00 | 0.00 |
| 9 | MRT | 0 | 0.00 | 0.00 |
| 10 | NAM | 0 | 0.00 | 0.00 |
| 11 | SDN | 0 | 0.00 | 0.00 |
| 12 | SOM | 0 | 0.00 | 0.00 |

```{=latex}
\end{small}
```

---

## 8. How to rebuild

```bash
# 1. Make sure erw-7 outputs exist
ls data/economics_erw/targeted/  # should have 69 = 23 crops × 3 regimes

# 2. Render maps + tables
Rscript erw/erw-10-profitability-maps-tables.R

# 3. Rebuild this PDF
bash docs/build-erw-results.sh
```

The R script is idempotent and ~3 min on an M-series laptop. The PDF build
requires `pandoc` + `xelatex` (same toolchain as `erw-model.pdf`).
