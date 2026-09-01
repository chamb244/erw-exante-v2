# Private vs public returns to basalt-ERW in Sub-Saharan Africa: envelope analysis

> **[2026-09-01] Numbers in this memo are superseded.** The pipeline was re-run
> on the Arrhenius + pH-6.0 basis (erw-9 temperature factor now Arrhenius,
> Ea = 68.8 kJ/mol; pH-factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×)
> after the ESROC-anchored citation review (`litrature/citation-review.md`).
> Current headline (equilibrium net-export, $150/$20, targeted): private 4.31 /
> public 1.95 / intersection 1.32 / combined 7.61 Mha; combined-only 2.67;
> uniform-20 public 3.95 Mha / 20.4 Mt; MAC medians $276 (uniform-20) / $330
> (targeted); core 0.65 / candidate 1.22 Mha. The memo's *reasoning* stands;
> quote numbers only from the 2026-09-01 tables in `docs/tables/`.

*Provisional results memo — substrate for the paper. Baseline: year-1 regime,
LiTAS-targeted and uniform-20 t/ha allocations, $150/tCO₂, MRV $20/tCO₂,
area-weighted across the 23 SPAM crops sharing each pixel. Figures in
`paper/figures/`, tables in `paper/tables/`. Canonical pipeline code:
`erw/erw-11-private-public-envelopes.R`.*

## 1. Framing

At every cropland pixel the model already decomposes the gross margin of basalt
application into a private stream (agronomic yield gains from acidity
neutralization) and a public stream (CDR revenue at the carbon price net of MRV),
each measured against the *full* delivered basalt cost:

- **Private-sufficient** — agronomic return alone covers the basalt investment
  (`gm_agro_only > 0`). The grower would rationally invest with or without carbon
  finance.
- **Public-sufficient** — CDR revenue alone covers the investment
  (`gm_cdr_only > 0`). A carbon buyer would fund it with or without yield gains.
- **Intersection** — both hold independently. Investment is *doubly justified* —
  and, importantly, this is exactly where carbon credits are **least additional**,
  because the agronomic case already stands on its own.

This yields a five-way per-pixel typology: both (intersection), private-only,
public-only, combined-only (neither stream alone suffices but together they do),
and neither. See `env_typology_{targeted,uniform_20}.png`.

## 2. The three envelopes

Area-weighted footprint, farms, gross value of crop production on the affected
land, and cumulative net CDR. (`output-envelope-summary.csv`.)

| Allocation | Envelope | Area (Mha) | Farms (M) | Value of prod. ($M) | Net CDR (Mt) |
|---|---|--:|--:|--:|--:|
| Targeted | Private-sufficient | 8.22 | 6.5 | 8,590 | 47.9 |
| Targeted | Public-sufficient | 2.23 | 1.6 | 1,680 | 25.0 |
| Targeted | **Intersection** | **1.85** | **1.3** | **1,486** | **22.2** |
| Targeted | Combined > 0 | 11.95 | 9.1 | 10,761 | 65.3 |
| Uniform 20 | Private-sufficient | 7.98 | 6.4 | 8,966 | 30.1 |
| Uniform 20 | Public-sufficient | 3.51 | 2.6 | 2,746 | 17.8 |
| Uniform 20 | **Intersection** | **1.97** | **1.3** | **1,669** | **10.7** |
| Uniform 20 | Combined > 0 | 13.12 | 10.2 | 13,955 | 51.5 |

Decomposing the targeted case by the typology (Mha of harvested area):

- **Private-only: 6.37 Mha** — yield gains alone justify investment; CDR credits
  here are *non-additional*.
- **Public-only: 0.38 Mha** — CDR alone justifies it; the agronomic case does not.
- **Intersection: 1.85 Mha** — doubly justified.
- **Combined-only: 3.35 Mha** — neither stream alone suffices, but stacked they do.
  This is the band where blended (carbon + agronomic) finance is genuinely pivotal.

The headline tension for the paper: the private case is much larger than the
public case (8.2 vs 2.2 Mha), so most of the agronomically-attractive land would
*not* depend on carbon credits, while the land where carbon finance is decisive
(the 3.35 Mha combined-only band) is precisely where the private case falls short.
Allocation choice mostly trades CDR depth for footprint — uniform-20 widens the
combined footprint (13.1 vs 12.0 Mha) but roughly halves intersection CDR (10.7 vs
22.2 Mt) because it spreads a fixed dose onto near-neutral soils with weak
agronomic response.

## 3. Where to target, and how robust it is

Holding the targeted allocation, we recomputed the envelopes analytically across a
240-point grid spanning the parameters the result is plausibly sensitive to:
delivered cost ×{0.5–2.0}, carbon price {$50–250}, yield benefit ×{0.5–2.0}, and
CDR rate ×{0.5–1.5}. Each pixel's **robustness score** is the fraction of that grid
under which it remains in the intersection (`robustness_intersection.png`).

No pixel stays in the intersection across more than **57%** of this deliberately
wide grid — the doubly-justified case is inherently parameter-sensitive. Defining
the priority area on the robustness gradient:

| Tier | Definition | Area (Mha) | Farms (M) | Value ($M) | CDR (Mt) |
|---|---|--:|--:|--:|--:|
| Core | intersection under ≥50% of grid | 0.74 | 0.45 | 663 | 13.1 |
| Candidate | intersection under ≥33% of grid | 1.73 | 1.16 | 1,409 | 21.5 |

A plausible-central-band cross-check (cost 0.75–1.25×, $100–250/tCO₂, yield
1.0–1.5×, CDR 0.75–1.25×; core = ≥75% of band) independently gives **0.81 Mha** —
the two methods converge on ~0.7–0.8 Mha of genuinely robust core land.

The core concentrates in a few areas with the right combination of acidic soils,
warm-wet climate (high CDR factor), proximity to basalt sources, and decent crop
prices (`core_priority.png`, `output-core-priority-by-country.csv`):

| Country | Core area (Mha) | Farms (M) | Value of prod. ($M) |
|---|--:|--:|--:|
| Cameroon | 0.42 | 0.26 | 422 |
| Guinea | 0.25 | 0.13 | 164 |
| Ethiopia | 0.05 | 0.05 | 48 |
| Tanzania | 0.02 | 0.01 | 20 |
| Nigeria / Madagascar / Sierra Leone | <0.01 each | | |

## 4. Which assumptions move the answer

One-at-a-time sensitivity of total intersection area (`output-sensitivity-tornado.csv`,
`sensitivity_tornado.png`; baseline intersection 1.85 Mha):

| Parameter | Range tested | Intersection swing (Mha) |
|---|---|--:|
| **Delivered basalt cost** | ×0.5 – ×2.0 | **5.62** (0.0 – 5.6) |
| Carbon price | $50 – $250 | 2.80 |
| CDR rate | ×0.5 – ×1.5 | 2.38 |
| Yield benefit | ×0.5 – ×2.0 | 0.89 |

**Delivered basalt cost is by far the dominant lever** — larger than carbon price,
CDR rate, and yield combined at the margin. Targeting is therefore first and
foremost a logistics problem: proximity to basalt sources and transport cost
decide more than the carbon market or the agronomic response. Encouragingly, the
**yield benefit is the *least* sensitive parameter** — which matters because it is
also the most uncertain input (the Bayesian uplift fit is prior-dominated on ~14
trials). The core targeting area is robust to that uncertainty.

## 5. What binds the public (VCM) envelope — marginal abatement cost

Because investment interest concentrates on the carbon-credit case, the public
envelope deserves a separate diagnosis. Public-sufficiency
(`CDR_net × (price − MRV) > basalt_cost`) reduces to a marginal-abatement-cost
test in which the per-hectare dose cancels:

> **MAC ($/tCO₂) = delivered cost per tonne basalt ÷ CDR per tonne basalt.**

The public envelope is exactly the land where `MAC < price − MRV`. Across treated
cropland the area-weighted MAC distribution is **p25 $247, median $305, p75
$476/tCO₂** (`mac_targeted.png`) — set against a net credit price of only $130
($150 − $20 MRV). Only the cheapest ~10–15% of land clears, which is why the
public envelope is just 2.2 Mha.

The binding factor is therefore the **realized CDR rate per tonne of basalt**
(~0.1–0.25 tCO₂/t here — ~2–6 tCO₂/ha against $650–1,640/ha of basalt cost), not
the credit price or logistics. The price ladder is steeply convex
(`public_area_vs_price.png`):

| VCM price | Public-sufficient area | Cumulative CDR |
|--:|--:|--:|
| $150 (current) | 2.23 Mha | 25 Mt |
| $250 | 3.57 | 31 |
| $300 | 7.52 | 51 |
| $500 | 13.15 | 73 |
| $1000 | 16.6 (of 17.6 treated) | 81 |

A lever comparison on the public envelope settles which knob matters
(`cdr_rate_sensitivity_panel.png`, `output-cdr-rate-sensitivity.csv`):

| Lever | Change in public area |
|---|--:|
| +33% carbon price ($150→$200) | +26% |
| −33% delivered cost (≈ aggressive solar haulage) | +33% |
| +33% CDR rate | +23% |
| **2× CDR rate** | **+181%** (2.23 → 6.27 Mha) |

Doubling the realized CDR rate nearly triples the public envelope — beyond any
plausible price or cost move. The CDR rate is governed by the reactive fraction
(~0.20, Lewis-calibrated), grain size, the climate factor, and pedogenic-carbonate
loss — precisely the `erw-3`/`erw-9` parameters still carried as v1 empirical
proxies. (A feasible at-scale solar-electric haulage scenario — ~25% off the
transport term, ~14% off delivered cost — widens the *private* envelope by
~1 Mha but the public envelope by only ~0.15 Mha, confirming the public case is
revenue-, not cost-, limited; see `solar_transport_summary.csv`.)

**Investor implication.** ERW's public/VCM case hinges on CDR-quantification and
durability risk, not price risk. The single largest economic lever is also the
least scientifically resolved quantity — how much of the stoichiometric potential
actually weathers, how fast, and how much re-precipitates as pedogenic carbonate.
This reframes MRV: it is not merely a $20/t cost line but the mechanism that
converts an uncertain CDR rate into a sellable, high-integrity tonne, so tighter
measurement raises the *effective* CDR rate that can be monetized — exactly where
the leverage sits.

## 6. Caveats

- **Year-1 regime is the most optimistic**: it sums the agronomic return over the
  5-year basalt residency against an undiscounted CDR total. NPV and equilibrium
  regimes would shrink all envelopes; worth reporting as a robustness panel.
- **Area-weighted** pixels evaluate the average crop outcome; a best-crop or
  dominant-crop rule would enlarge the private envelope.
- **Farm counts** use approximate per-country average holding sizes — order-of-
  magnitude only; a gridded field-size layer would sharpen them.
- The committed `docs/tables/output-ssa-summary.csv` (e.g. 137.87 Mha profitable)
  is **stale** relative to the current `economics_erw` rasters; `erw-10`'s own
  definition recomputed on today's data gives 9.89 Mha, consistent with this memo.
  `erw-10` should be re-run.
- CDR climate factor and pedogenic-carbonate deduction remain v1 empirical proxies;
  the CDR-rate ×0.5–1.5 sweep is the stand-in for that structural uncertainty.
