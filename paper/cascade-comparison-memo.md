# Cascade Climate's Weathering Potential Explorer vs. our ERW model

*Comparison memo. Sources: Cascade blog explainer (cascadeclimate.org/blog/weathering-potential-explorer) and the Weathering Potential Explorer User Guide PDF, reviewed 2026-07.*

**One-line framing.** Cascade's Explorer and our model are different animals. Cascade produces a **relative weathering-rate screening index** (a dimensionless, normalized 0-1 percentile map answering "where does rock dissolve fastest, all else equal?"). Ours is an **absolute ex ante economic + CDR + agronomic decision model** (answering "where is ERW profitable, how much durable CO2, at what marginal abatement cost, and for whom - public or private?"). Cascade is, in effect, the single *weathering-rate* input layer; we build the entire downstream stack - feedstock, dose, durability, cost, agronomy - that Cascade explicitly declines to model.

## Side-by-side

| Dimension | Cascade Weathering Potential Explorer | Our ERW ex ante model |
|---|---|---|
| Purpose | Global *screening* of relative weathering potential | Ex ante *decision model*: profitability, CDR, MAC, public/private envelopes |
| Output | Dimensionless normalized index (0-1), percentile ranks / "weathering multiplier" vs global median; explicitly **not** a CO2 flux | Absolute $/ha gross margin, tCO2/ha, Mha viable, $/tCO2 MAC |
| Core weathering law | `r ∝ s · [H+] · A·e^(−Ea/RT)` (Bertagni & Porporato 2022 normalized-flux framework) | `gross CDR = CDR_max · reactive_fraction · grain_factor · (f_MAT · f_MAP · f_pH)` |
| Temperature | **Arrhenius**, exponential, fixed **Ea = 68.8 kJ/mol** (basaltic glass; White & Blum 1995); ~5x from 10->30 C | **Linear** `clamp(MAT/11 C, 0.3-3)` - no activation energy |
| Water | **Soil moisture** (GSSM 0-5 cm) with explicit *far-from-equilibrium* assumption | **Precipitation** proxy `clamp(MAP/1000 mm, 0.3-3)` |
| pH in the rate | `[H+] = 10^(−pH)` - **monotonic** (more acid = faster, unbounded); durability handled *separately* via a conceptual "sweet spot ~5.5-7" and an optional pH mask | **Triangular** `f_pH` peaking at **pH 5.0**, floor 0.5 - bakes a rate *optimum* into the factor |
| Feedstock / grain / dose | **Normalized out** (per unit reactive surface area); held constant | **Explicit**: CaO/MgO -> CDR_max 310 kg/t, reactive_fraction 0.20 (Lewis 2021), 50 um grain factor, dose allocations |
| Durability / downstream fate | **Not modeled** (listed as a limitation); flags the acid-storage trade-off and MRV's local-flux bias conceptually | **Quantified**: net-export `max(gross − F·S, 0)`, F = 0.88 |
| Economics | **Excluded** (points to their separate MRV Cost Estimator) | Full delivered cost (quarry+grind+transport+spread), MRV, carbon price, MAC |
| Agronomy | **Excluded** | EcoCrop acidity-saturation yield response -> private returns |
| Geography / resolution | **Global**, ~1 km, all cropland (ESA WorldCover / GFSAD masks) | 44 SSA countries, ~0.083 deg (~9 km), acid-eligible (targeted) or all cropland (uniform) |
| Soil pH source | SoilGrids pH(H2O), selectable depth | SoilGrids (same family) - common ground |

## The methodological differences that matter

**1. Temperature: Arrhenius vs linear.** This is the cleanest place Cascade is more rigorous. They use a proper Arrhenius factor with a literature activation energy; we use a clamped linear `MAT/11`. Over 10-30 C, Arrhenius gives ~5-7x while our linear factor gives ~2.7x, so we likely **understate the tropical temperature advantage** relative to the standard kinetic treatment. This is a concrete, low-cost robustness swap - implemented as the `arrhenius` variant in `erw-9` (see the sensitivity section).

**2. Water: soil moisture vs precipitation.** Soil moisture (their choice) is a better proxy for actual water-rock contact than annual precipitation (ours), and it carries the explicit *far-from-equilibrium* framing that underpins the dissolution-rate literature. Our `f_MAP` is cruder. Adopting GSSM soil moisture would be the next Cascade-aligned refinement, but it requires ingesting a new global dataset (not currently in the pipeline).

**3. pH: their cleaner separation vs our baked-in optimum.** Cascade keeps the *rate* monotonic in `[H+]` (standard proton-promoted law) and handles the "too acidic hurts durable storage" concern as a **separate** layer (masking + conceptual sweet spot). We fold a non-monotonic peak (pH 5.0) directly into the rate factor, which is more ad hoc. Notably, the thing Cascade handles heuristically (durability declines on very acidic soil) is exactly what our net-export mass balance does *quantitatively* - so on durability we are ahead of them, but our `f_pH` triangular shape is the weaker part of our formulation and could be replaced by (monotonic rate) x (net-export durability), which is conceptually cleaner and closer to Cascade's separation.

**4. Static-pH feedback.** Cascade flags that they use static pH, so their potentials are "upper bounds, most accurate early / at low dose." We partially fix this: our over-liming refinement evaluates *post-application* pH, capturing the feedback Cascade leaves unhandled. Point in our favor.

## Where we agree, and where each goes further

We **agree on the environmental targeting**: warm + moist + mildly acidic is the sweet spot. Cascade's "pH 5.5-7" and our equilibrium net-export peak (~pH 5-5.5) are close, and both flag over-acidic soils as durability-risky.

Cascade goes further on: weathering kinetics (Arrhenius + Ea + far-from-equilibrium), global coverage, 1 km resolution, and a cleaner rate law.

We go further on essentially everything downstream of "does the rock dissolve": feedstock chemistry and dose, net-export durability, delivered cost / MRV / MAC, agronomic co-benefit, and the public/private envelope economics - all of which Cascade explicitly lists as out of scope.

**Net:** complementary, not competing. Cascade is a defensible, literature-grounded *weathering-rate screen*; ours is the economic/CDR decision layer that sits on top. The most useful thing to borrow is their kinetics treatment - hence the Arrhenius-temperature sensitivity variant, and a candidate paragraph positioning our environmental drivers against the community screening standard.

## Implemented: Arrhenius temperature as a sensitivity variant

We adopted Cascade's Arrhenius temperature response as a sensitivity variant of our
gross-CDR climate factor. Both are normalized to `f = 1` at `T_ref = 11 C` and
clamped to `[0.3, 3.0]`:

- linear (our default): `f_lin = clamp(MAT / 11, 0.3, 3.0)`
- Arrhenius (Cascade): `f_arr = clamp( exp(-Ea/R (1/T - 1/T_ref)), 0.3, 3.0 )`, `Ea = 68.8 kJ/mol`

SSA cropland is warm (area-weighted MAT: p10 19 C, median 26 C, p90 28 C), so the
steeper Arrhenius curve **raises area-weighted gross CDR by ~27% (capped) / ~74%
(uncapped)** relative to the linear default. Because MAC is inversely proportional
to CDR, that lowers MAC and expands the public envelope. In the illustrative
uniform-20, all-cropland, equilibrium net-export case, public-viable area rises
**~+54% (4.6 -> 7.1 Mha)** under the capped Arrhenius variant. The uncapped form
(full Cascade steepness) roughly doubles tropical gross CDR and would expand it
further.

**How it is wired in.** Two ways, no data download needed (WorldClim `tavg` already
in the pipeline):

1. *Analytic sweep (fast, preferred):* run `paper/analysis/erw_arrhenius_variant.py`
   to generate `data/cdr_climate_arrhenius_multiplier.tif` (= `f_arr/f_lin` per pixel),
   then pass it as the GROSS-CDR multiplier `rmult` in the erw-11/erw-12 sweep:
   `envelopes(P, rmult = resample(rast('data/cdr_climate_arrhenius_multiplier.tif'), ref))`.
   No pipeline re-run.
2. *Full re-run:* set `CLIMATE_TEMP_MODE <- "arrhenius"` in `erw-9` and re-run
   erw-9 -> erw-7 -> erw-11/12.

Caveat: we clamp `f_arr` to the same `[0.3, 3.0]` bounds as the linear default so
the two are directly comparable in scale; the uncapped Arrhenius is reported as an
upper bound. The soil-moisture half of Cascade's formulation (GSSM) is a further
refinement that would require ingesting a new global dataset and is left as
future work.
