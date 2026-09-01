---
abstract: |
  This is a short tutorial that walks through what the GAIA *Ex-Ante ERW*
  project does and why. It is written for someone who has not seen this work
  before --- no background in soil chemistry, carbon markets, or geospatial
  modelling is assumed. Every technical term is defined on first use, and
  the glossary at the back gives a one-line refresher for each one.
  Read it once, look at the figures, and you should know enough to follow
  any conversation about the project.
---

# 1. What is this project, in one paragraph?

We are building a **map of where in Sub-Saharan Africa it would make
economic sense to use crushed rock to (a) reduce soil acidity for farmers,
*and* (b) pull carbon dioxide out of the atmosphere at the same time**.
The map answers, for every roughly-1 km² patch of cropland on the
continent, the question: *if a farmer spread basalt rock dust on this
field, would the carbon-removal payments plus the yield improvement
outweigh the cost of buying, transporting, and spreading the rock?* The
project produces this map under different policy assumptions (the carbon
price, the cost of measurement and verification, the choice of rock,
how finely the rock is ground), and ranks the locations that look the
most promising first.

# 2. Why this matters

The world has agreed it needs to *remove* carbon dioxide from the
atmosphere, not just stop emitting more, if it wants to hold warming
below 2 °C — this is the conclusion of the 2023 IPCC Sixth Assessment
Synthesis Report [1]. **Enhanced rock weathering** — the practice of
spreading finely-ground silicate rock (almost always basalt) on cropland
— is one of the few removal pathways that

1. is **physically scalable** — Beerling and colleagues [2] estimate
   that deploying basalt across global croplands could remove 0.5 to 2
   billion tonnes of CO₂ per year by 2050, with the highest per-hectare
   potential in the warm-humid tropics,
2. has a **co-benefit for farmers** (it works like agricultural lime,
   reducing soil acidity and raising yields) — a US Corn-Belt field
   trial reported a cumulative $10.5 \pm 3.8$ tonnes of CO₂ removed per
   hectare and a 12–16 % yield uplift over four years [5]; a 2024–25
   smallholder trial in Kisumu County, Kenya reported a 71 % first-year
   and 79 % second-year maize-yield increase from a single 20 t/ha
   nephelinite (volcanic rock powder) application [6],
3. uses **existing infrastructure** (rock from quarries that already
   exist; tractors that already spread lime; logistics chains that
   already exist), and
4. has **measurable, verifiable** outcomes that carbon-credit buyers
   are willing to pay for.

The headline numbers are not uniformly rosy: a recent three-year Swiss
vineyard trial measured only about 100 ± 30 kg CO₂ per hectare per year
[7], an order of magnitude below the higher published rates. This
underlines that *climate, soil pH, and drainage matter enormously*. The
high-end ERW response is concentrated in warm, mildly-acidic,
well-drained, vegetated systems — exactly the agroecological space most
of cropland Sub-Saharan Africa occupies.

Sub-Saharan Africa is a particularly interesting place to apply this
because (i) its soils are widely acidic and lime-poor, so the agronomic
benefit is unusually large; (ii) its climate is warm and humid, which is
exactly the climate that makes the rock dissolve quickly and remove the
most carbon; and (iii) its farmers are largely cut off from carbon
markets, so an enhanced-rock-weathering programme would deliver a new
income stream rather than crowding out an existing one.

But for a policy-maker or an investor, the right question is more
specific than "is this a good idea in general?" The right question is:
**at what carbon price, in which country, on which crop, would this
actually be profitable today?** That is the question the project model
answers, location by location.

# 3. What does the model actually compute?

For every 1 km² patch of cropland in 47 Sub-Saharan African countries,
the model computes a single number: the **per-hectare gross margin**
of a basalt-application programme on that patch. In plain English, the
number is

> *what the farmer earns from the carbon-credit payment, **plus**
> what they earn from the bigger harvest, **minus** what it costs to
> buy, grind, transport, and spread the rock.*

That number can be positive (profitable to do here), negative
(unprofitable), or close to zero (could go either way depending on
assumptions). When we put all the patches on a map, we see immediately
where the deployment-friendly zones are.

# 4. The conceptual picture

The conceptual framework, summarised in **Figure 1**, is the
single most-important diagram in the project. It shows that the
profitability of a patch of cropland comes from **three independent
chains of cause and effect**, and that those chains converge on the
single profitability number described above.

![**Figure 1.** The conceptual framework. Three streams (left to right:
*biogeochemistry* → carbon revenue; *agronomy* → yield revenue;
*economic geography* → total cost) converge on a single per-pixel gross-
margin equation. The six dashed boxes at the top are the user-settable
decision dials. The three coloured boxes at the bottom are the three
outputs the model produces. The dashed arrow from agronomy back to
biogeochemistry captures the fact that the same basalt application rate
that the farmer needs for soil-acidity reasons is the basalt that the
biogeochemical chain dissolves to remove CO₂.](erw-conceptual-framework.pdf){#fig:framework width=100%}

The three chains are:

## 4.1 The **biogeochemistry chain** (carbon side, blue in Figure 1)

This is the chain that tells us **how much CO₂ a tonne of basalt will
actually remove** when it sits on a particular farmer's field for a year.
The chemistry, summarised by Hartmann and colleagues [4], says that when
basalt dissolves in moist soil, the calcium and magnesium in the rock
combine with atmospheric CO₂ to form *bicarbonate*, which then washes
into rivers and eventually to the ocean, where it stays for tens of
thousands of years.

Three things determine how much of this actually happens on a given
field:

1. **What's in the rock** (its calcium and magnesium content, default
   10 % CaO and 7 % MgO by mass, and how finely it is ground — a finer
   grind exposes more surface to the soil water and dissolves faster
   [3, 11]).
2. **The climate** (the rock dissolves faster in warm, wet conditions —
   our reference point is a temperate American climate of 11 °C mean
   annual temperature and 1000 mm mean annual precipitation, anchored
   to the Lewis et al. [11] basalt-weathering calibration. The
   temperature response follows the standard **Arrhenius** law of
   chemical kinetics — the reaction rate roughly doubles with every
   7–9 °C of warming — so warm tropical sites dissolve the rock up to
   three times faster than the reference, the model's cap).
3. **The local soil pH** (two opposing effects are at work: acidity
   speeds up the *dissolution* of the rock, but if the soil is too
   acidic — below about pH 5 — the alkalinity the rock releases stops
   being *captured* as bicarbonate and the carbon benefit collapses.
   The combined effect peaks in mildly acidic soil, around pH 6).

We also subtract a **pedogenic-carbonate** deduction — a fancy name for
the well-known fact that in dry regions, some of the alkalinity the
rock releases doesn't make it to the ocean. It precipitates as solid
carbonate right there in the soil, which doesn't count as a permanent
carbon removal. We use the aridity bands keyed on mean annual
precipitation from the UNEP World Atlas of Desertification [12]; this
deduction can take away as much as 90 % of the gross removal in arid
pixels.

The output of this chain is the **CDR yield surface**: for every
1 km² patch, the tonnes of CO₂ that one hectare of treated cropland
would remove, accounting for climate, pH, and aridity penalties.

## 4.2 The **agronomy chain** (yield side, purple in Figure 1)

This chain tells us **how much extra crop the farmer will harvest** if
they apply basalt. The mechanism is almost the same as agricultural
lime: the dissolved cations from the rock raise the soil pH and free up
nutrients, particularly phosphorus and the basic cations themselves.

Three things determine the yield gain:

1. **How acidic the starting soil is** — the soil pH, exchangeable
   acidity, and aluminium saturation rasters come from SoilGrids-Africa
   [13]. On a soil already at pH 7, basalt does very little for the
   yield; on a soil at pH 5.0, it can do a great deal.
2. **The crop being grown** — maize is moderately acid-sensitive, so
   it responds strongly; cassava is acid-tolerant, so it responds less.
   We have 23 crops mapped across Africa using the SPAM database [17].
3. **How much rock you apply** — we use the `limer` R package [14] to
   compute the *lime-equivalent* requirement using the LiTAS recipe of
   Aramburu Merlos et al. [15], then convert lime-equivalent demand to a
   basalt application rate using the rock's chemistry. That same rate is
   what feeds into the biogeochemistry chain (this is the dashed
   cross-arrow in Figure 1).

The yield gain is then multiplied by the local crop price (taken from
the United Nations FAOSTAT producer-price database, 2016–2020 average)
to give the **yield revenue surface**: dollars per hectare per year of
agronomic benefit.

## 4.3 The **economic-geography chain** (cost side, orange in Figure 1)

This chain tells us **how much it actually costs** to put a tonne of
basalt on a farmer's field. The cost has four components:

1. **Buying the rock from the quarry** — typically $10 per tonne,
   because basalt fines (the pieces too small to use as construction
   aggregate) are a by-product that quarries are happy to sell cheap.
   We use the Global Lithological Map of Hartmann and Moosdorf [20] to
   find where basalt outcrops actually are.
2. **Transporting the rock from the quarry to the farm** — this is by
   far the most variable component. A farmer 50 km from a basalt quarry
   pays a few dollars; a farmer 500 km from one pays much more. We
   calculate this using the *cost-distance* over a 1-km global friction
   surface from the Malaria Atlas Project [19], which knows the
   locations of roads, rivers, and rough terrain. The default haulage
   cost is $0.04 per minute per tonne (a 30-tonne truck at $80 per
   hour); we cap the haul at 1000 km because beyond that the diesel
   lifecycle emissions of the truck erase the CDR credit.
3. **Grinding the rock fine enough to dissolve** — this is an
   electricity cost, so it varies by country (industrial electricity
   tariffs in Sub-Saharan Africa range roughly $0.05 to $0.20 per kWh).
4. **Spreading the rock on the field** ($8 per tonne) and
   **measuring/verifying the CDR for the carbon market** ($20 per tonne
   of CO₂ removed — inside the $15–71/tCO₂ range that Mercer et al.
   2024 (LSE Grantham Research Institute) report for enhanced-weathering
   MRV).

The output of this chain is the **delivered cost surface**: dollars per
tonne of basalt that arrives at a farmer's field.

## 4.4 Where the three chains meet

The three chains all produce numbers in the same units (US dollars per
hectare per year, on the same 1 km² grid). The model simply adds the
two revenue streams and subtracts the cost stream to get a single
profitability map. That is equation (1) in the working paper; for this
tutorial, the words above are the equation.

## 4.5 The six "dials" at the top of Figure 1

The boxed items at the top of Figure 1 are the **decision variables** ---
the things the user can change before running the model. They are:

1. **The chemistry of the rock** (a richer-in-calcium rock removes
   more carbon per tonne).
2. **How finely the rock is ground** (a finer grind dissolves faster
   but costs more electricity to produce).
3. **Where on the landscape we apply it** ("targeted" --- only on
   farms where the soil acidity is high enough to need it; or
   "uniform" --- everywhere, regardless of acidity).
4. **The carbon price** in dollars per tonne CO₂.
5. **The MRV cost** (measurement, reporting, verification --- what we
   pay to convince the carbon market that the removal actually
   happened).
6. **The discount rate** (how much we prefer dollars now over dollars
   in five years).

By running the model with different settings of these dials, we can
produce supply curves and sensitivity charts (the two outputs on the
right of Figure 1) that tell us, for example, *"at $80 per tonne of
CO₂ and a 200 µm grind, the model predicts 12 million hectares are
deployable"*.

# 5. The modelling tasks, in plain language

The model is built as a pipeline of **nine functional blocks**, each
doing one well-defined job. Figure 2 shows how they connect. Below I
walk through each one in plain English.

![**Figure 2.** The pipeline architecture. Blue boxes are raw data
sources; grey boxes are the working-grid step; orange boxes are
geospatial processing; green boxes are economic; purple boxes are the
Bayesian-statistics step; the wide green bar in the middle is the
profitability function; the red boxes at the bottom are the
deliverables. Every arrow is a data dependency: the box at the tail
of the arrow produces something that the box at the head of the arrow
consumes.](erw-pipeline-flow.pdf){#fig:pipeline width=100%}

## Block 1 — Build the working map

We take 47 country boundaries from GADM v4, the SoilGrids-Africa
database [13] (which gives us soil pH, density, and chemistry at every
kilometre on the continent), and the MapSPAM crop-production database
[17] (which tells us where which of 23 crops is actually being grown in
Africa). We put all of these on a common grid at roughly 9 km resolution.
Every subsequent step operates on this same grid.

## Block 2 — Figure out how much rock each pixel needs

For every patch of cropland, we use the standard agricultural
lime-requirement formulas (the same ones a soil-testing lab would use),
implemented in the `limer` R package [14], with the LiTAS recipe of
Aramburu Merlos et al. [15] as the default. We then convert that lime
requirement to a basalt requirement, using the rock's chemistry (default
10 % CaO + 7 % MgO by mass, with a Lewis-2021 [11] reactive-fraction
calibration of 0.20 at the reference grain × climate). This gives us a
**basalt application rate** in tonnes per hectare for every patch.

## Block 3 — Compute the CDR yield

For every patch, we take the per-tonne carbon-removal potential of the
chosen rock (computed from its calcium and magnesium content), multiply
it by the climate factor (warmer-and-wetter sites dissolve the rock
faster), multiply by the pH factor (acidic soils dissolve the rock
faster), and subtract the pedogenic-carbonate fraction (the fraction
of alkalinity that gets locked up locally and never makes it to the
ocean). The result is the **tonnes of CO₂ removed per hectare per
year** for that patch, under our default assumptions.

## Block 4 — Compute the delivered rock price

This is the trickiest geospatial step. For every patch of cropland, we
ask: *what is the nearest basalt outcrop, and how many minutes of
truck-time away is it?* We use the Global Lithological Map [20] for the
location of basalt outcrops and the Malaria Atlas Project 2019
motorised friction surface [19] for the per-pixel travel speed (it
accounts for roads, terrain, water bodies). The cost-distance is
accumulated using terra's algorithm; multiplying by the hourly cost of
a truck ($80 per hour for a 30-tonne diesel truck) gives us the
**delivered price** of a tonne of basalt at every cropland pixel.

## Block 5 — Country-resolved electricity

For every country in Sub-Saharan Africa, we have a tabulated industrial
electricity price (sourced from IEA, Ember, and GET.invest 2022–2024
data, so we know what it would cost to grind a tonne of rock there) and
a tabulated grid carbon intensity (so we know how much CO₂ the grinding
emits, which we have to subtract from the gross CDR to be honest about
the net climate benefit).

## Block 6 — Crop response

The trickiest *biological* step. We have two ways to predict how much
extra crop a farmer will get from a basalt application. The first is
**EcoCrop** — a long-established suitability model that gives a 0-1
score for every crop on every soil, available in R as the `Recocrop`
package by Hijmans and Manners [16]. The second is a **Bayesian
hierarchical statistical model**, implemented in `brms` [18] and fitted
to a small set of published ERW field trials (currently 14 rows). The
Bayesian model is more flexible because it lets us update our
predictions as new field trials are published. The profitability block
uses the Bayesian model when it has run; otherwise it falls back on
EcoCrop.

## Block 7 — The profitability function

This is the block that brings together everything above. It applies the
gross-margin equation to every patch of cropland, for every crop, for
every choice of *how much rock* (targeted vs uniform 10, 20, 50 tonnes
per hectare), and for every choice of *time horizon* (year-1, ten-year
net-present value at 10 % discount, or equilibrium). The output is a
large stack of map layers — 276 of them per run: 23 crops × 4 allocation
rules × 3 regimes. Default policy parameters: carbon price $150/tCO₂
(the 2024–25 mid-market for verified ERW credits), MRV cost $20/tCO₂,
grain size 50 µm, discount rate 10 % per year, CDR phasing 30/25/20/15/10 % over five
years.

## Block 8 — The supply ranking

In practice, basalt supply is constrained. We can't quarry an infinite
amount of basalt overnight, and we can't grind it instantly. So the
supply block ranks every patch of cropland from "best dollar of value
per tonne of basalt" to "worst dollar of value per tonne of basalt",
and produces a **supply curve**: how many tonnes of CO₂ would we remove
each year if our annual basalt supply were 1, 5, 10, 50, 250, or 500
million tonnes? This is the headline answer for an investor: *for $X
per year of basalt supply, you get Y million tonnes of CO₂ per year
removed at a marginal price of $Z per tonne*.

## Block 9 — Sensitivity sweeps

Finally, we run the whole pipeline five times under different
assumptions, to see which of our assumptions matter most for the
answer. The five sweeps are: across different crop, basalt, and carbon
prices; across different yield-uplift levels (1.0–1.8×, capped at the
envelope of published field trials); across different MRV costs; across
different grain sizes; and across different allocation rules.

# 6. What the maps look like

To make the model concrete, we have rendered twelve "indicator maps"
that show the inputs and intermediate outputs across Sub-Saharan
Africa. Below are three of the most diagnostic ones.

![**Figure 3.** Soil pH across Sub-Saharan African cropland. The
humid-tropical zones (West Africa, the Congo basin, East Africa) have
acidic soils (orange-to-red); the Sahel and parts of southern Africa
have alkaline soils (blue). The acidic zones are where the agronomic
benefit of basalt is large.](maps/01-soil-ph.png){width=80%}

![**Figure 4.** Cumulative CDR yield --- tonnes of CO₂ removed per
hectare under a one-year LiTAS-targeted basalt application. Strongest
in the humid tropics (the dark zones in the Congo basin and around
the African Great Lakes); suppressed in arid regions
because the pedogenic-carbonate deduction is large there.](maps/04-cdr-yield-merlos.png){width=80%}

![**Figure 5.** Delivered basalt price ($ per tonne) --- the
quarry-gate price plus the cost of trucking the rock to the field.
The dark zones (cheap) are near basalt outcrops in the Ethiopian
highlands, the East African Rift, the Cameroon volcanic line,
Madagascar, and southern Africa. The light zones (expensive --- the
$50 / tonne cap binds) are West Africa and the Sahel, where the
nearest basalt is hundreds of kilometres away.](maps/11-basalt-delivered-price.png){width=80%}

# 7. What we have actually produced so far

By **2026-09-01**, the model is in the following state:

- All five of the input-and-surface blocks (1, 2, 3, 4, 5) have been
  run end-to-end on real data and produce the maps above.
- The pH map matches the qualitative geography of African soils that
  you would expect from any soil-science textbook.
- The CDR yield map peaks in the humid tropics, exactly where the
  literature [2, 5] says it should. With the 2026-09-01 refresh (an
  Arrhenius temperature factor, the pH factor's peak moved to 6.0, on
  top of the 2026-05-26 round-1 fixes — 50 µm grain, CGIAR-CSI AI for
  the pedogenic deduction), mean CDR under LiTAS-targeted allocation
  lands at **4.4 t CO₂/ha** cumulative gross, or **3.3 t CO₂/ha** on
  the net-export (creditable) basis; the per-tonne CDR potential at the
  reference climate is **88 kg CO₂/t basalt** (was 62 kg/t at 100 µm).
- The delivered-basalt-price map ranges from $10 per tonne (right at
  the outcrop) to $50 per tonne (the cap), with about half of
  Sub-Saharan-African cropland binding at the cap. This is a strong
  signal that *which country a farm is in* matters far more for ERW
  economics than the literature's standard "uniform $30 per tonne"
  assumption used in global-scale ERW assessments.
- Block 6's Bayesian-yield arm is **not yet fitted** --- the
  Bayesian-statistics software has to be installed and run on the
  curated trial dataset. EcoCrop is in place as the fallback, now
  with per-crop max-pH cliffs instead of a flat 5.5.
- **Block 7 (profitability) and Block 8 (supply ranking) have been
  re-run end-to-end at the 2026-09-01 defaults.** Block 7 wrote 276
  gross-margin maps (4 allocation rules × 23 crops × 3 regimes); Block
  8 wrote three supply curves and nine deployment masks. The new
  headline picture is in §7.0 below — a majority of crops positive on
  year-1 and equilibrium under the targeted rule; NPV much leaner.
- **Block 9 (sensitivity sweeps) has now been run** at the current
  defaults (2026-09-01), with the yield-uplift sweep capped at 1.8×
  (the envelope of published field trials). The default-scope sweep
  takes roughly six to eight hours on a single core (about 14,000
  profitability evaluations).

## 7.0 Headline numbers (refreshed 2026-09-01)

A round-1 conservatism review (2026-05-26; see the change-log in
`docs/erw-parameters.md`) re-anchored five defaults: **grain size 100 µm
→ 50 µm**, **MRV $30 → $20/tCO₂**, **year-1 agronomic return now summed
over the 5-year basalt residency** (was a single-season figure),
**EcoCrop max-pH cliff** generalised from a flat 5.5 to per-crop
optima (5.5–8.0), and the **pedogenic deduction** now consumes the
CGIAR-CSI Global Aridity Index (AI = MAP / PET) when available. A
second, citation-anchored review (2026-09-01) then promoted the
**Arrhenius temperature factor** to the headline, moved the **pH
factor's peak from 5.0 to 6.0** (acid-catalysed dissolution ×
carbon-capture efficiency of the released alkalinity), and put all
credited CDR on the **net-export basis** (gross CDR minus the
alkalinity consumed neutralising standing soil acidity). The numbers
below are from the 2026-09-01 re-run.

**Per-crop, LiTAS-targeted, total SSA-wide gross margin ($ million).**
Totals across all deployed pixels (those passing the per-crop acidity
filter). Sorted by equilibrium-regime GM; the top eight only:

| Crop | Year-1 (5-yr cum.) | NPV | Equilibrium |
|---|--:|--:|--:|
| Common bean | **4,906** | 594 | **1,004** |
| Groundnut | **3,972** | 435 | **778** |
| Potato | 2,489 | 731 | 503 |
| Sweet potato | 1,437 | −276 | 231 |
| Cassava | 1,402 | −442 | 106 |
| Soybean | 152 | −70 | 21 |
| Wheat | 50 | −40 | 17 |
| Lentil | 40 | 18 | 8 |

**Crops with positive total GM across all 23 SPAM crops** (out of 23):

| Allocation | Year-1 | NPV | Equilibrium |
|---|--:|--:|--:|
| LiTAS-targeted | **13** | **4** | **14** |
| Uniform 10 t/ha | 12 | 2 | 5 |
| Uniform 20 t/ha | 6 | 2 | 3 |
| Uniform 50 t/ha | 4 | 0 | 3 |

Acid-tolerant cereals (sorghum, millet) and coffee/cocoa stay negative
because the EcoCrop response is already saturated on most of their
SSA cropland — the agronomic side is structurally small, so the CDR
revenue alone has to clear the full basalt cost.

**Supply-frontier deployment.** Ranking pixels by gross-margin per
tonne of basalt (Block 8) and capping at each annual supply level:

| Supply cap (Mt basalt/yr) | Year-1 GM (\$B) | NPV GM (\$B) | Equilib. GM (\$B) | Marginal \$/t basalt (Y1 / NPV / Eq) |
|---:|--:|--:|--:|--:|
| 10 | 2.14 | 0.92 | 1.34 | 173 / 76 / 89 |
| 50 | 7.31 | 3.08 | **3.01** | 104 / 34 / 18 |
| 100 | 11.43 | **3.89** | 3.00 | 66 / 4 / −16 |
| 250 | **16.24** | 2.09 | 1.77 | 5 / −27 / −61 |
| Unconstrained | 12.37 | −5.93 | 1.77 | (tail pixels negative) |

Headline supply-curve readings:

- **Year-1 regime**: total GM keeps climbing all the way to the 250
  Mt/yr cap — **$16.2 billion** with **68.4 Mt CO₂/yr** removed —
  though the marginal pixel is down to $5/t basalt there; at 100 Mt/yr
  the programme earns $11.4B on 28.1 Mt CO₂/yr with the marginal pixel
  still at $66/t.
- **NPV regime, 100 Mt/yr deployment**: **$3.9 billion** GM, 28.6 Mt
  CO₂/yr, marginal pixel $4/t — essentially the break-even scale. NPV
  deployment becomes net value-destructive between 100 and 250 Mt/yr.
- **Equilibrium regime breakeven**: the peak is now at the 50 Mt/yr
  cap — **$3.0 billion** with 13.7 Mt CO₂/yr — and the marginal pixel
  slips negative between 50 Mt/yr (still +$18/t) and 100 Mt/yr
  (−$16/t), so the steady-state programme tops out at about 50–75
  Mt/yr before adding more basalt destroys value at the margin.

**Unconstrained continental capacity** of the LiTAS-targeted
allocation is **443 Mt basalt/yr** for the year-1 / NPV regimes
and **145 Mt basalt/yr** for equilibrium. The corresponding
cumulative CDR is **121 Mt CO₂/yr** and **40 Mt CO₂/yr**
respectively. Deploying at the unconstrained level is net-positive
on year-1 ($12.4B) but value-destructive on NPV (−$5.9B),
confirming that **which pixels you deploy on** still matters more
than the gross continental capacity.

## 7.1 Key constants and their sources

Every parameter the model uses can be re-set. The defaults below are
chosen to match the central tendency of the published ERW literature.
Numbers in square brackets refer to the References section (§10).

| Parameter | Default value | Source / justification |
|---|---|---|
| Reference temperature $T_\text{ref}$ | 11 °C | US Corn-Belt anchor used by Lewis et al. [11] |
| Reference precipitation $P_\text{ref}$ | 1000 mm | as above [11] |
| Temperature response | Arrhenius, $E_a$ = 68.8 kJ/mol, clamped [0.3, 3.0] | White & Blum 1995 silicate activation energy; linear MAT/$T_\text{ref}$ kept as a conservative sensitivity variant |
| pH factor | triangular, peak at pH 6.0, floor 0.5 | acid-catalysed kinetics × alkalinity carbon-capture efficiency (Bertagni & Porporato 2022; Holden et al. 2024; Power et al. 2025) |
| Reactive fraction at reference | 0.20 | calibrated by Lewis et al. [11] |
| Grain-size exponent $\beta$ | 0.5 | surface-area scaling (Strefler et al. [3]) |
| Grinding-energy exponent $\alpha$ | 1.2 | Strefler et al. [3] |
| Pedogenic-carbonate fraction | CGIAR-CSI AI when present, else MAP-binned 0–90 % | UNEP aridity bands [12]; Zomer et al. 2022 |
| Feedstock chemistry (CaO, MgO) | 10 % CaO, 7 % MgO | typical mafic basalt; user-settable |
| Default grain size | 50 µm | Strefler grinding-curve anchor; cost-minimising once carbon revenue is credited |
| Quarry-gate basalt price | $10 / t | basalt fines as quarry by-product (industry data) |
| Truck haulage | $0.04 / min / t | 30-t truck @ $80 / hour (industry data) |
| Maximum haul distance | 1000 km | beyond cap, truck-diesel LCA erases the credit |
| Friction surface | MAP 2019 motorised | Weiss et al. [19] |
| On-farm spreading | $8 / t | industry data |
| Carbon price | $150 / tCO₂ | 2024–25 mid-market for verified ERW credits |
| MRV cost | $20 / tCO₂ | inside the $15–71/tCO₂ EW MRV range of Mercer et al. 2024 (LSE Grantham Research Institute) |
| Discount rate (NPV) | 10 % / yr | conventional infrastructure rate |
| CDR realisation phasing | 30 / 25 / 20 / 15 / 10 % over 5 yr | trial data [5] |
| Year-1 agronomic basis | summed undiscounted over project horizon (5 yr) | matches `cdr_tha`'s cumulative basis |
| EcoCrop max-pH cliff | per-crop EcoCrop optima (5.5–8.0) | EcoCrop database; previously a flat 5.5 |

# 8. Scope of the current work

To set expectations clearly, the model in its current state covers:

- **Geographic scope.** 47 Sub-Saharan African countries, masked to QED
  cropland; northern boundary at the southern edge of the Sahara (so
  Morocco, Algeria, Tunisia, Libya, and Egypt are excluded); Madagascar
  is included. Working resolution ≈9 km (0.083°).
- **Crops.** The 23 SPAM v2 crops [17] that cover ≥95 % of African
  harvested area.
- **Feedstock.** Mafic silicate rocks: basalt-equivalent (GLiM classes
  basic volcanic, pyroclastic, and basic plutonic / gabbro [20]). All
  other feedstock classes — ultramafics, wollastonite, steel slag,
  cement-kiln dust, mine tailings — are out of scope (see Limitations
  below).
- **Time horizons.** Year-1 only; ten-year net-present value at 10 %
  discount; equilibrium (saturating CDR). All three run in parallel.
- **Allocation rules.** Four — LiTAS-targeted (apply only where soil
  acidity is high enough to need it) plus uniform 10, 20, and 50 t/ha.
- **Decision variables.** Six dials (feedstock chemistry, grain size,
  allocation rule, carbon price, MRV cost, discount rate) — see §4.5.

# 9. Limitations of the current work

Six substantive limitations should be named upfront. They are listed in
rough order of how much they constrain the current results.

1. **The feedstock catalogue is incomplete.** The model currently
   considers only basalt-and-gabbro outcrops from GLiM v1 [20]. The
   literature recognises four additional candidate feedstock classes:
   ultramafic silicates (excluded for cropland use because of Ni/Cr
   leaching risk — see Vienne et al. [10] and Beerling et al. [2]),
   calcium-silicate by-products (wollastonite, steel slag, cement-kiln
   dust), construction by-products (recycled concrete fines, fly ash),
   and mine tailings. The omission of industrial alkaline by-products in
   particular materially shifts the picture for countries with no mafic
   outcrops — much of West Africa, where the model currently predicts
   delivered prices at the $50/tonne cap.
2. **The Bayesian yield-uplift arm is fitted on a small trial
   dataset** — currently 14 trial rows from the published ERW
   literature. The posterior is therefore prior-dominated. The Bayesian
   framework is correct (it grows in evidence weight as data is added),
   but quantitative yield predictions today carry wide uncertainty. The
   2024 US Corn-Belt trial [5], the 2024–25 Kisumu trial [6], and the
   2025 Swiss-vineyard trial [7] are all candidates for incorporation
   into the next iteration.
3. **The headline numbers move with the defaults.** Blocks 7, 8, and 9
   (profitability, supply-constrained ranking, sensitivity sweeps) have
   all been run end-to-end — most recently on 2026-09-01, on the
   Arrhenius + pH-6.0, net-export basis. But two default refreshes in
   2026 each moved the headline totals by billions of dollars, so treat
   any single set of headline numbers as conditional on the parameter
   set stamped on it (§7.0), not as a settled property of the system.
4. **The aridity proxy.** As of 2026-05-26 the pedogenic-carbonate
   deduction reads the CGIAR-CSI Global Aridity Index (AI = MAP / PET,
   Zomer et al. 2022) when `data/cgiar_aridity_index.tif` is present;
   otherwise it falls back to the MAP-only proxy. The CGIAR path is the
   literature standard; the MAP-only fallback over-deducts in cool
   highlands where low PET keeps the true AI in the humid band.
5. **MRV cost is a single flat number.** $20/tCO₂ for all pixels and all
   protocols is a strong simplification. In practice MRV cost is
   scale-dependent and protocol-dependent (Isometric vs Puro vs others),
   and is materially higher in smallholder-dominated systems where
   sampling has to be coordinated across many small farms. The
   sensitivity sweep over MRV $0–80/tCO₂ in Block 9 partly bounds this,
   but a proper treatment is a future revision.
6. **The model is per-pixel and farmer-perspective.** A complete
   economic model of deployment would also incorporate aggregator-level
   economics: pooling MRV across many small farms, finance for
   distributed deployment, and coordination with carbon-market
   intermediaries. These are likely material at the scale of
   smallholder-dominated cropping in Sub-Saharan Africa.

A seventh, more technical caveat: the SoilGrids-Africa pH raster [13]
is itself a machine-learning prediction with its own uncertainty,
which the current model treats as deterministic. Future work could
propagate that uncertainty into the gross-margin map using the
Bayesian framework already in place for the yield-uplift arm.

# 10. References

The default constants and the framing of the conceptual model rest on a
specific set of published references. All entries below have been
verified against the published record.

[1] IPCC (2023). *Climate Change 2023: Synthesis Report.* Sixth
Assessment Report of the IPCC, Geneva. <https://www.ipcc.ch/report/ar6/syr/>.

[2] Beerling, D. J. et al. (2020). Potential for large-scale CO₂ removal
via enhanced rock weathering with croplands. *Nature* 583, 242–248.
doi:10.1038/s41586-020-2448-9.

[3] Strefler, J., Amann, T., Bauer, N., Kriegler, E., Hartmann, J.
(2018). Potential and costs of carbon dioxide removal by enhanced
weathering of rocks. *Environmental Research Letters* 13, 034010.
doi:10.1088/1748-9326/aaa9c4.

[4] Hartmann, J. et al. (2013). Enhanced chemical weathering as a
geoengineering strategy. *Reviews of Geophysics* 51, 113–149.
doi:10.1002/rog.20004.

[5] Beerling, D. J. et al. (2024). Enhanced weathering in the US Corn
Belt delivers carbon removal with agronomic benefits. *PNAS* 121 (9),
e2319436121. doi:10.1073/pnas.2319436121.

[6] Haque, F. et al. (2025). *Agronomic Performance of Enhanced Rock
Weathering in a Tropical Smallholder System: A Maize Trial in Kenya.*
CDRXIV preprint 410 (Flux Carbon / UNCCD pilot).
<https://cdrxiv.org/preprint/410>.

[7] Dupla, X., Bertagni, M. B., Grand, S. (2025). Three Years of Field
Trials Indicate a Sustained Enhanced Rock Weathering Signal with Limited
CO₂ Removal. *Environmental Science & Technology* 59 (48), 25751–25764.
doi:10.1021/acs.est.5c09820.

[8] Kanzaki, Y. et al. (2024). *Soil cation storage as a key control on
the timescales of CDR through enhanced weathering.* ESS Open Archive
preprint, doi:10.22541/essoar.170960101.14306457/v1.

[9] Renforth, P. (2019). The negative emission potential of alkaline
materials. *Nature Communications* 10, 1401.
doi:10.1038/s41467-019-09475-5.

[10] Vienne, A. et al. (2022). Enhanced weathering using basalt rock
powder: carbon sequestration, co-benefits and risks in a mesocosm study
with *Solanum tuberosum*. *Frontiers in Climate* 4, 869456.
doi:10.3389/fclim.2022.869456.

[11] Lewis, A. L. et al. (2021). Effects of mineralogy, chemistry and
physical properties of basalts on carbon capture potential and
plant-nutrient element release via enhanced weathering. *Applied
Geochemistry* 132, 105023. doi:10.1016/j.apgeochem.2021.105023.

[12] Middleton, N. & Thomas, D. S. G. (eds.) (1992). *World Atlas of
Desertification.* United Nations Environment Programme, London.

[13] Hengl, T. et al. (2017). SoilGrids250m: Global gridded soil
information based on machine learning. *PLOS One* 12 (2), e0169748.
doi:10.1371/journal.pone.0169748.

[14] Aramburu Merlos, F. & Hijmans, R. J. (2024). *limer: Acidic soil
management for agriculture.* R package, GAIA Africa.
<https://github.com/gaiafrica/limer>.

[15] Aramburu Merlos, F., Silva, J. V., Baudron, F., Hijmans, R. J.
(2023). Estimating lime requirements for tropical soils: Model
comparison and development. *Geoderma* 432, 116421.
doi:10.1016/j.geoderma.2023.116421.

[16] Hijmans, R. J. & Manners, R. (2025). *Recocrop: Estimating
Environmental Suitability for Plants.* R package version 0.4-2, CRAN.
doi:10.32614/CRAN.package.Recocrop.

[17] You, L. et al. *MapSPAM — Spatial Production Allocation Model.*
IFPRI and HarvestChoice. Used here via `geodata::crop_spam`: SPAM 2010
V2.0 globally and SPAM 2017-SSA for Africa.
<https://www.mapspam.info>.

[18] Bürkner, P.-C. (2017). brms: An R package for Bayesian multilevel
models using Stan. *Journal of Statistical Software* 80 (1), 1–28.
doi:10.18637/jss.v080.i01.

[19] Weiss, D. J. et al. (2020). Global maps of travel time to
healthcare facilities. *Nature Medicine* 26, 1835–1838.
doi:10.1038/s41591-020-1059-1. (The motorised friction surface, nominal
year 2019, is derived from this work.)

[20] Hartmann, J. & Moosdorf, N. (2012). The new global lithological
map database GLiM. *Geochemistry, Geophysics, Geosystems* 13, Q12004.
doi:10.1029/2012GC004370. Dataset DOI: 10.1594/PANGAEA.788537.

# 11. What this tutorial does and does not cover

This tutorial covers the **conceptual and modelling tasks**: what the
model is, how it works, what it produces, and where its limits are.

It does **not** cover the day-to-day implementation details: the R
scripts, the data-handling, the rebuilding of the figures, the
TikZ/LaTeX setup. Those are described in the companion document
*Ex-Ante ERW Model --- Living Documentation* (`docs/erw-model.pdf`).
The more academic write-up is the *Working Paper*
(`docs/erw-working-paper.pdf`), which contains the formal equations and
the full reference list with author lists.

# 12. Appendix A — A worked example, end to end, on two pixels

> **Note on defaults.** The numbers below were computed against the
> pre-2026-05-26 parameter set (grain size 100 µm, MRV $30/tCO₂, MAP-only
> pedogenic deduction, single-season year-1 agronomic accounting, flat
> EcoCrop max-pH cliff at 5.5). The current defaults differ (see §7.1) —
> the worked example is preserved here as a *teaching artefact* rather
> than a live calibration of the current model. The temperature and pH
> factors, however, use the **current 2026-09-01 forms** (Arrhenius
> temperature response; triangular pH factor peaking at 6.0), so the
> factor arithmetic below matches the code as it stands; only the
> parameter inputs are slightly stale.

The sections above describe the *model* in words. This appendix takes
**two real-looking 1 km² pixels** and pushes them through every
calculation the pipeline performs, with all the arithmetic written out.
The aim is that a reader who has never seen the code should be able to
reproduce the gross-margin number on a pocket calculator.

We deliberately pick two contrasting pixels:

- **Pixel A — Kisumu County, western Kenya** (≈ 0.10° S, 34.75° E).
  Humid tropical climate, acidic soil, near volcanic outcrops in the
  Rift. This is a "poster-child" pixel — the kind that should be near
  the top of the supply-curve ranking. Tied to the real Haque et al.
  2025 smallholder trial [6].
- **Pixel B — central Burkina Faso, near Kaya** (≈ 13.10° N, 1.10° W).
  Hot, semi-arid Sahel; near-neutral sandy soil; hundreds of kilometres
  from the nearest basalt outcrop. This is a "bad" pixel — useful as a
  contrast that exposes which terms in the equation are doing the work.

The full set of input numbers, all derived from the project's input
rasters (SoilGrids-Africa, WorldClim, GLiM, MAP friction, FAOSTAT,
country electricity tables), is:

| Quantity | Symbol | Pixel A (Kisumu) | Pixel B (Kaya) | Source layer |
|---|---|---|---|---|
| Mean annual temperature | $\text{MAT}$ | 23 °C | 28 °C | WorldClim 10′ tavg |
| Mean annual precipitation | $\text{MAP}$ | 1 400 mm | 580 mm | WorldClim 10′ prec |
| Topsoil pH (0–30 cm) | $\text{pH}$ | 5.2 | 6.0 | SoilGrids-Africa |
| Acidity saturation | $\text{hp\_sat}$ | 25 % | 8 % | SoilGrids-Africa |
| LiTAS lime requirement | $L$ | 2.1 t CaCO₃/ha | (n/a — fails mask) | `limer::limeRate` |
| Truck-time distance to nearest basalt | $d$ | 150 km | 500 km | MAP friction × GLiM |
| Country industrial electricity | $p_\text{elec}$ | $0.13/kWh (Kenya) | $0.20/kWh (BF) | `erw-energy-country` |
| Country grid carbon intensity | $\text{CI}$ | 0.10 kg CO₂/kWh | 0.55 kg CO₂/kWh | `erw-energy-country` |
| Dominant crop on pixel | — | Maize (MAIZ) | Sorghum (SORG) | SPAM 2017-SSA |
| Baseline crop yield | $Y_0$ | 1.8 t/ha | 0.8 t/ha | SPAM 2017-SSA |
| Crop-price (country median) | $p_c$ | $250/t | $200/t | FAOSTAT 2016–2020 |

The two pixels also run under different **allocation rules** for the
reason explained in §4.5. Pixel A passes the LiTAS-targeted mask
(its 25 % acidity saturation exceeds maize's 10 % tolerance, so basalt
is genuinely useful for soil-acidity reasons); we therefore put it on
the **LiTAS-targeted** rule. Pixel B fails the LiTAS mask (its 8 %
acidity saturation is below sorghum's 30 % tolerance, so the targeted
allocation skips it); we therefore put it on the **uniform 20 t/ha**
rule, which mimics the "spread basalt everywhere" convention used by
Beerling et al. 2020 [2] and Baek et al. 2023.

## 12.1 Step 0 — Rock chemistry constants (same for every pixel)

These constants are computed *once* by `erw-3-basalt-requirements.R`
from the default basalt feedstock chemistry and grain size. They are
then reused for every pixel.

The default basalt has $\text{CaO} = 10 \%$ and $\text{MgO} = 7 \%$ by
mass, and the default grain size is $d = 100 \,\mu\text{m}$.

**Calcium-carbonate equivalent (CCE), per tonne of basalt.**
The chemistry says 1 g of CaO neutralises $100.09/56.08 \approx 1.783$ g
of CaCO₃-equivalent acidity, and 1 g of MgO neutralises
$100.09/40.30 \approx 2.481$ g of CaCO₃-equivalent acidity. So:

$$\text{CCE} = 0.10 \times 1.783 + 0.07 \times 2.481 = 0.1783 + 0.1737 = 0.3520$$

i.e. a tonne of basalt has the acid-neutralising power of about
**352 kg of pure agricultural lime**.

**Stoichiometric CDR ceiling.**
Each mole of divalent cation consumes 2 moles of CO₂ as it makes
bicarbonate. So 1 g CaO removes $(2 \times 44.01)/56.08 \approx 1.570$
g CO₂ and 1 g MgO removes $(2 \times 44.01)/40.30 \approx 2.185$ g CO₂:

$$\text{CDR}_\text{max} = (0.10 \times 1.570 + 0.07 \times 2.185) \times 1{,}000 = 157.0 + 152.9 \approx \mathbf{310 \,\text{kg CO}_2 / \text{t basalt}}$$

This is the **upper bound** — what we'd remove if every gram of
calcium and magnesium reacted completely and all the bicarbonate made
it to the ocean. The rest of the model is a sequence of haircuts on
this number.

**Grain-size factor.**
We anchor everything at $d_\text{ref} = 100 \,\mu\text{m}$, so:

$$f_\text{grain} = \left(\frac{100}{d}\right)^{0.5} = \left(\frac{100}{100}\right)^{0.5} = 1.00$$

At the default 100 µm grain size this factor is exactly one. A 25 µm
grind would give $f_\text{grain} = (100/25)^{0.5} = 2$ — twice the rate
but considerably more energy to produce (see grinding-energy step
below).

**Reference reactive fraction.**
From the Lewis et al. 2021 [11] calibration, the realised fraction of
the stoichiometric ceiling at a temperate-humid reference site is
$\phi_\text{ref} = 0.20$, or **20 %** of the maximum.

**Effective neutralising value at the reference climate.**

$$\text{NV}_\text{eff,ref} = \text{CCE} \times \phi_\text{ref} \times f_\text{grain} = 0.3520 \times 0.20 \times 1.00 = 0.0704$$

So at the reference climate one tonne of basalt does the work of
$0.0704$ t of pure CaCO₃ — about 70 kg-CaCO₃-equivalent. The
**basalt-to-lime ratio** is therefore:

$$r_\text{bl} = \frac{1}{0.0704} \approx \mathbf{14.20 \,\text{t basalt} / \text{t CaCO}_3\text{-eq}}$$

i.e. you need roughly fourteen tonnes of crushed basalt to do what one
tonne of agricultural lime does.

**Effective CDR per tonne basalt at the reference climate.**

$$\text{CDR}_\text{eff,ref} = \text{CDR}_\text{max} \times \phi_\text{ref} \times f_\text{grain} = 310 \times 0.20 \times 1.00 = \mathbf{62 \,\text{kg CO}_2 / \text{t basalt}}$$

This is the number that the per-pixel climate-factor and pH-factor
calculations in §12.3 below will scale up (for warm-wet-acidic pixels)
or down (for cool-dry or alkaline pixels).

**Grinding energy and reference grinding cost.**
The Strefler et al. 2018 [3] energy curve, anchored at 50 µm = 0.07
GJ/t and α = 1.2, gives:

$$E_\text{grind} = 0.07 \times \left(\frac{50}{100}\right)^{1.2} = 0.07 \times 0.4353 = 0.0305 \,\text{GJ/t}$$

Converting to kWh: $0.0305 \times 277.78 = 8.46 \,\text{kWh/t}$.

At the *reference* global electricity price of $0.10/kWh the grinding
cost is $0.85/t. In §12.5 below this is overridden by each country's
own electricity tariff.

## 12.2 Step 1 — Basalt application rate (Block 2)

**Pixel A — LiTAS-targeted maize.**
The `limer` package, fed the SoilGrids-Africa exchangeable acidity, K,
Ca, Mg, Na and bulk density at this pixel, computes a year-1 LiTAS
lime requirement of:

$$L_A = 2.10 \,\text{t CaCO}_3/\text{ha}$$

Converted to basalt at the rock-chemistry rate from §12.1:

$$R_A = L_A \times r_\text{bl} = 2.10 \times 14.20 = \mathbf{29.8 \,\text{t basalt/ha}}$$

This sits squarely in the typical LiTAS-targeted year-1 range of
~30 t/ha.

**Pixel B — uniform 20 t/ha sorghum.**
Because Pixel B fails the LiTAS-targeted mask, the model uses the
uniform-rate convention:

$$R_B = \mathbf{20.0 \,\text{t basalt/ha}}$$

(Note: under the *targeted* rule Pixel B would receive **0 t/ha**, i.e.
the model would say "don't bother." The uniform 20 t/ha column is the
literature-convention sensitivity test, not the model's recommendation.)

## 12.3 Step 2 — CDR yield per pixel (Block 3, file `erw-9-cdr-yield.R`)

This is where the reference-climate per-tonne CDR potential of 62 kg
CO₂/t basalt gets rescaled by **temperature, precipitation, soil pH,
and aridity** — the four factors that determine how much of the
stoichiometric ceiling we actually realise.

**Climate factor — temperature.** An Arrhenius response with silicate
activation energy $E_a = 68.8$ kJ/mol ($E_a/R = 8275.68$ K), normalized
to 1 at $T_\text{ref} = 11\,°\text{C} = 284.15$ K and clamped to
$[0.3, 3.0]$:

$$f_\text{MAT} = \text{clamp}\!\left(\exp\!\left[-8275.68\left(\tfrac{1}{\text{MAT}+273.15} - \tfrac{1}{284.15}\right)\right], \, 0.3, \, 3.0\right)$$

In plain words: the dissolution rate roughly doubles with every 7–9 °C
of warming, up to a 3× cap.

- Pixel A: $\exp[-8275.68\,(1/296.15 - 1/284.15)] = e^{1.180} = 3.25$
  → clamped → $f_\text{MAT,A} = 3.0$
- Pixel B: $\exp[-8275.68\,(1/301.15 - 1/284.15)] = e^{1.644} = 5.18$
  → clamped → $f_\text{MAT,B} = 3.0$

Both tropical pixels hit the 3.0 cap — a 23 °C or a 28 °C site is
already more than three Arrhenius-doublings warmer than the 11 °C
temperate reference.

**Climate factor — precipitation.** Anchored at $P_\text{ref} = 1000 \,\text{mm}$:

$$f_\text{MAP} = \text{clamp}\!\left(\tfrac{\text{MAP}}{1000}, \, 0.3, \, 3.0\right)$$

- Pixel A: $1400/1000 = 1.40$ → $f_\text{MAP,A} = 1.40$
- Pixel B: $580/1000 = 0.58$ → $f_\text{MAP,B} = 0.58$

**pH factor.** A triangular function peaking at pH 6.0. Two opposing
mechanisms are folded into one curve: acidity *speeds up* the rock's
dissolution, but below about pH 5 the released alkalinity stops being
*captured* as bicarbonate (it just neutralises the standing soil
acidity), so the carbon benefit collapses. Their product peaks in
mildly acidic soil:

$$f_\text{pH}(\text{pH}) = \begin{cases} 0.5 & \text{pH} < 4 \\ 0.5 + 0.25(\text{pH}-4) & 4 \le \text{pH} < 6 \\ 1.0 - 0.25(\text{pH}-6) & 6 \le \text{pH} < 8 \\ 0.5 & \text{pH} \ge 8 \end{cases}$$

- Pixel A: pH 5.2 → $0.5 + 0.25 \times 1.2 = 0.80$
- Pixel B: pH 6.0 → $1.0 - 0.25 \times 0.0 = 1.00$ (right at the peak)

**Combined climate factor.**

$$f_\text{clim} = f_\text{MAT} \times f_\text{MAP} \times f_\text{pH}$$

- Pixel A: $3.0 \times 1.40 \times 0.80 = \mathbf{3.36}$
- Pixel B: $3.0 \times 0.58 \times 1.00 = \mathbf{1.74}$

Pixel A's climate more than triples the reference reactivity; Pixel B
gets much less (the warm temperature is largely cancelled by the
modest rainfall, even though its pH 6.0 sits exactly at the pH-factor
peak).

**Pedogenic-carbonate deduction.** From the UNEP aridity bands keyed
on MAP:

- Pixel A: MAP = 1400 > 600 mm → humid band → $\text{ped} = 0.00$,
  exported fraction $= 1.00$
- Pixel B: MAP = 580 < 600 mm (dry sub-humid band) → $\text{ped} = 0.15$,
  exported fraction $= 0.85$

So at Pixel B we lose 15 % of the alkalinity right in the soil to
locally-precipitated carbonate.

**Effective reactive fraction at each pixel** (capped at 1.0, since
nothing can react more than 100 %):

$$\phi_\text{eff} = \min(1.0, \, \phi_\text{ref} \times f_\text{grain} \times f_\text{clim})$$

- Pixel A: $\min(1.0, \, 0.20 \times 1.0 \times 3.36) = \min(1.0, 0.672) = 0.672$
- Pixel B: $\min(1.0, \, 0.20 \times 1.0 \times 1.74) = 0.348$

**CDR per tonne basalt at each pixel.**

$$\text{CDR}_\text{px} = \text{CDR}_\text{max} \times \phi_\text{eff} \times (1 - \text{ped})$$

- Pixel A: $310 \times 0.672 \times 1.00 = \mathbf{208.3 \,\text{kg CO}_2/\text{t basalt}}$
- Pixel B: $310 \times 0.348 \times 0.85 = \mathbf{91.7 \,\text{kg CO}_2/\text{t basalt}}$

Pixel A is removing more than twice as much CO₂ per tonne of rock as
Pixel B — entirely because of climate.

**Gross CDR per hectare** (multiply by the application rate from §12.2):

- Pixel A: $29.8 \,\text{t/ha} \times 0.2083 \,\text{t CO}_2/\text{t} = \mathbf{6.21 \,\text{t CO}_2/\text{ha}}$ cumulative
- Pixel B: $20.0 \,\text{t/ha} \times 0.0917 \,\text{t CO}_2/\text{t} = \mathbf{1.83 \,\text{t CO}_2/\text{ha}}$ cumulative

## 12.4 Step 3 — Delivered basalt cost (Block 4, file `erw-basalt-access.R`)

Four cost components stack to give the dollars-per-tonne the farmer
ultimately pays. The four are: **quarry-gate** (fixed at $10/t),
**grinding** (kWh per tonne times the local electricity tariff),
**transport** (cost-distance from the nearest basalt outcrop, priced
at $0.04/min/t at an effective 30 km/h on the friction surface), and
**spreading** (fixed at $8/t).

**Grinding cost (pixel-specific via country electricity).**

$$C_\text{grind} = \text{kWh/t} \times p_\text{elec}$$

- Pixel A (Kenya, $0.13/kWh): $8.46 \times 0.13 = \$1.10/t$
- Pixel B (Burkina Faso, $0.20/kWh): $8.46 \times 0.20 = \$1.69/t$

**Transport cost (pixel-specific via friction surface).**
The friction surface converts each km of land travel to travel-minutes;
we use a long-run effective speed of $0.5 \,\text{km/min}$ (= 30 km/h)
to convert pixel-cumulative travel time back to dollars at the truck
rate of $0.04/min/t:

$$C_\text{trans} = \frac{d}{0.5} \times 0.04$$

- Pixel A: $\frac{150}{0.5} \times 0.04 = 300 \times 0.04 = \$12.00/t$
- Pixel B: $\frac{500}{0.5} \times 0.04 = 1000 \times 0.04 = \$40.00/t$

**Delivered cost per tonne basalt.**

$$C_\text{bas} = \$10 + C_\text{grind} + C_\text{trans} + \$8$$

- Pixel A: $10 + 1.10 + 12.00 + 8.00 = \mathbf{\$31.10/t}$
- Pixel B: $10 + 1.69 + 40.00 + 8.00 = \mathbf{\$59.69/t}$

**Total basalt cost per hectare** (rate × $/t):

- Pixel A: $29.8 \times 31.10 = \mathbf{\$926.78/ha}$
- Pixel B: $20.0 \times 59.69 = \mathbf{\$1{,}193.80/ha}$

## 12.5 Step 4 — Lifecycle CO₂ emissions of the operation (Block 5/7)

To be honest about the *net* climate benefit, we have to subtract the
CO₂ emitted by grinding, trucking, and spreading the basalt from the
gross CDR computed in §12.3. The three components are:

$$\text{LCA}_t = \underbrace{\text{kWh/t} \times \text{CI}}_\text{grinding} + \underbrace{d \times 0.12}_\text{transport} + \underbrace{0.5}_\text{spreading} \quad \text{(kg CO}_2/\text{t basalt)}$$

- Pixel A: $8.46 \times 0.10 + 150 \times 0.12 + 0.5 = 0.85 + 18.0 + 0.5 = \mathbf{19.35 \,\text{kg CO}_2/\text{t}}$
- Pixel B: $8.46 \times 0.55 + 500 \times 0.12 + 0.5 = 4.65 + 60.0 + 0.5 = \mathbf{65.15 \,\text{kg CO}_2/\text{t}}$

Notice that Pixel B's lifecycle bill is over **three times** Pixel A's,
because of (a) the dirtier grid mix in West Africa, and (b) the much
longer truck haul.

**LCA per hectare.**

- Pixel A: $29.8 \times 19.35/1000 = \mathbf{0.58 \,\text{t CO}_2/\text{ha}}$
- Pixel B: $20.0 \times 65.15/1000 = \mathbf{1.30 \,\text{t CO}_2/\text{ha}}$

## 12.6 Step 5 — Net CDR and CDR revenue

**Net CDR per hectare** is gross CDR (§12.3) minus the LCA (§12.5),
floored at zero (we don't pay the farmer to *emit*; we just refuse to
credit a net-negative pixel):

$$\text{CDR}_\text{net} = \max(0, \, \text{CDR}_\text{gross} - \text{LCA})$$

- Pixel A: $\max(0, \, 6.21 - 0.58) = \mathbf{5.63 \,\text{t CO}_2/\text{ha}}$
- Pixel B: $\max(0, \, 1.83 - 1.30) = \mathbf{0.53 \,\text{t CO}_2/\text{ha}}$

Pixel B's lifecycle emissions eat more than two thirds of its gross
CDR — the diesel of trucking the rock 500 km has wiped out most of the
climate benefit, leaving only half a tonne of creditable CO₂ per
hectare.

**CDR revenue.** Each net tonne of CO₂ sells at the carbon price minus
the MRV cost. At defaults ($150 − $30 = $120/tCO₂):

$$\text{Rev}_\text{CDR} = \text{CDR}_\text{net} \times (\text{price}_\text{C} - \text{MRV})$$

- Pixel A: $5.63 \times 120 = \mathbf{\$675.60/ha}$
- Pixel B: $0.53 \times 120 = \mathbf{\$63.60/ha}$

## 12.7 Step 6 — Agronomic return (Block 6)

The yield-uplift step asks: *with this much basalt on this soil, how
much more crop will this farmer harvest, and what is that worth?* In
the absence of a fitted Bayesian model (the current state of the
project, see §7), we use the EcoCrop-derived relative-yield curve from
`erw-5`. The numbers below are illustrative of the EcoCrop branch.

**Pixel A — maize at pH 5.2.**
Maize is moderately acid-sensitive. EcoCrop's response curve gives a
~12 % relative yield gain on this soil when the pH is nudged toward 6
by basalt-derived alkalinity. (For comparison: the published Corn-Belt
trial [5] reported 12–16 % cumulative uplift; the Kisumu smallholder
trial [6] reported a much larger 71 % first-year uplift at a 20 t/ha
nephelinite rate, but on a fresher and more reactive feedstock than
the basalt assumed here.)

$$\Delta Y_A = Y_0 \times \text{uplift} = 1.8 \times 0.12 = 0.216 \,\text{t/ha}$$

$$\text{Rev}_\text{agro,A} = \Delta Y_A \times p_c = 0.216 \times 250 = \mathbf{\$54.00/ha}$$

**Pixel B — sorghum at pH 6.0.**
Sorghum is acid-tolerant and the starting pH is already near neutral —
the EcoCrop response curve gives a much smaller uplift here, around
3 %.

$$\Delta Y_B = 0.8 \times 0.03 = 0.024 \,\text{t/ha}$$

$$\text{Rev}_\text{agro,B} = 0.024 \times 200 = \mathbf{\$4.80/ha}$$

## 12.8 Step 7 — Putting it all together — gross margin (Block 7)

The gross margin per hectare under the **year-1 regime** is the sum of
the two revenue streams minus the basalt cost:

$$\text{GM}_\text{y1} = \text{Rev}_\text{agro} + \text{Rev}_\text{CDR} - C_\text{bas}$$

| Term | Pixel A | Pixel B |
|---|---|---|
| Agronomic revenue | $54.00 | $4.80 |
| CDR revenue | $675.60 | $63.60 |
| Delivered basalt cost | −$926.78 | −$1,193.80 |
| **Gross margin year-1** | **−$197.18/ha** | **−$1,125.40/ha** |
| GM per tonne of basalt | **−$6.62/t** | **−$56.27/t** |

Three things to notice:

1. **Both pixels lose money in year 1.** At the default LiTAS rate of
   ~30 t/ha, the upfront basalt cost ($900–$1,300/ha) exceeds the
   carbon-credit revenue ($60–$680/ha) plus the agronomic uplift
   ($5–$54/ha). Even the "good" pixel is in the red on this
   single-season accounting (the current model's year-1 regime sums
   the agronomic return over the 5-year residency, which closes much
   of this gap — see the note at the top of this appendix).
2. **Pixel A is nearly an order of magnitude closer to break-even**
   than Pixel B (−$7/t vs −$56/t). If the supply-curve ranking deploys
   only the top-decile pixels, Pixel A is the kind of place that
   *might* make the cut; Pixel B isn't close.
3. **For Pixel B, the CDR side has largely collapsed.** Lifecycle
   emissions ate over two thirds of the gross CDR, so the farmer gets
   only $63.60 of carbon revenue plus $4.80 of yield uplift against
   the full $1,194 basalt cost. This is the model's way of saying
   *"do not deploy basalt in central Burkina Faso under these
   assumptions."* The Sahel pixel needs either
   (a) a local feedstock alternative — industrial alkaline by-products
   (out of scope at v1, see §9 limitation 1) or (b) a closer outcrop.

## 12.9 The same pixel under the NPV and equilibrium regimes

The year-1 picture above treats the application as a single up-front
cash flow. Two other regimes are computed in parallel.

**NPV regime.** The agronomic benefit accrues every year and the
basalt application is repeated periodically. The reapplication
interval is the year-1 LiTAS rate divided by the maintenance rate:

$$n_\text{reapply} = \text{round}\!\left(\frac{R_\text{y1}}{R_\text{maint}}\right) \approx \text{round}(29.8 / 5.0) = 6 \,\text{years}$$

`limer::NPV_lime` then computes the perpetuity-of-reapplication NPV
of the annual $54 agronomic benefit at a 10 % discount rate; a typical
result for the Pixel A parameters is around $260/ha.

The CDR revenue is phased over the 5-year reactive horizon
(`CDR_PHASING = c(0.30, 0.25, 0.20, 0.15, 0.10)`) and discounted year
by year, giving an NPV factor of:

$$\text{NPV factor} = \frac{\sum_t f_t / (1.10)^t}{\sum_t f_t} \approx \mathbf{0.79}$$

at 10 % discount. So Pixel A's CDR revenue under the NPV regime is
$675.60 \times 0.79 = \$533.70/ha$. The basalt cost remains an
up-front $926.78/ha (paid in year 0):

$$\text{GM}_\text{NPV,A} \approx 260 + 534 - 927 = \mathbf{-\$133/ha}$$

Still negative, but a smaller loss than the year-1 number because the
agronomic benefit now accrues for the full re-application interval
instead of one season.

**Equilibrium regime.** This skips the up-front liming entirely and
applies only the *maintenance* rate, which just keeps pace with
re-acidification. For Pixel A the maintenance rate from the LiTAS
calibration is around 5 t basalt/ha/yr. With everything else held
fixed:

| Term | Equilibrium Pixel A |
|---|---|
| Maintenance basalt rate | 5.0 t/ha/yr |
| Gross CDR | $5.0 \times 0.2083 = 1.04 \,\text{t CO}_2/\text{ha}$ |
| LCA | $5.0 \times 19.35/1000 = 0.10 \,\text{t CO}_2/\text{ha}$ |
| Net CDR | 0.94 t CO₂/ha |
| CDR revenue | $0.94 \times 120 = \$112.80/ha$ |
| Basalt cost | $5.0 \times 31.10 = \$155.50/ha$ |
| Agronomic revenue | $54.00/ha (unchanged) |
| **Gross margin (equilibrium)** | $54 + 113 - 156 = \mathbf{+\$11/ha}$ |

In equilibrium the pixel is essentially break-even — just barely
positive. This is exactly the regime in which the model's positive
steady-state picture sits: under the current (2026-09-01) defaults,
14 of 23 crops show positive total gross margin on equilibrium under
the LiTAS-targeted rule (§7.0), because the small maintenance-rate
basalt cost no longer swamps the recurring carbon and agronomic
revenue.

## 12.10 What the worked example tells us about the model

Three structural lessons fall out of the arithmetic above:

1. **The basalt cost dominates.** In Pixel A, $927/ha of basalt cost
   has to be earned back by $676 of CDR plus $54 of agronomy.
   Anything that moves the cost (a 50 % shorter haul, a 50 % cheaper
   electricity tariff, a lower spreading rate, a finer grind for a
   higher CDR-per-tonne yield) moves the answer materially. This is
   why **§4.5's six dials** are all on the cost side or on the
   reactivity side.
2. **Climate is the second-largest lever.** Pixel A's tropical
   climate factor of 3.4 turned the reference 62 kg CO₂/t into 208
   kg CO₂/t — more than a tripling. That is the entire reason
   Sub-Saharan Africa is interesting for ERW: the same tonne of basalt
   does over three times more carbon work here than in the temperate
   reference.
3. **Picking the right pixel matters more than the average price of
   basalt.** Even at *identical* model parameters, Pixel A is
   −$7/t while Pixel B is −$56/t — nearly an order-of-magnitude
   spread. The supply-curve ranking exploits exactly this spread:
   deploying the top-ranked pixels yields a profitable programme even
   though the continent-wide pixel-mean is negative (§7.0).

# 13. Glossary

**Allocation rule** — How we decide which fields get basalt. Either
*LiTAS-targeted* (only fields where the soil acidity is high enough to
benefit) or *uniform 10 / 20 / 50 tonnes per hectare* (everywhere,
regardless of acidity).

**Basalt** — A common, dark, fine-grained volcanic rock rich in
calcium and magnesium. The most-studied feedstock for enhanced rock
weathering on cropland.

**Bayesian hierarchical model** — A statistical model that combines
prior beliefs about parameters with observed data to produce a
posterior distribution over the parameters. "Hierarchical" means the
model has random effects --- for example, a per-crop intercept that
lets each crop have its own response without forcing them all to be
the same. We use it in Block 6 to predict yield response to basalt.

**CDR** — Carbon dioxide removal: the broad category of methods that
take CO₂ *out of the atmosphere* (as opposed to merely *avoiding new
emissions*).

**Cost-distance** — A spatial-analysis technique that, instead of
measuring straight-line distance, accumulates a *cost* (here:
minutes-of-travel) as you move from a source pixel. We use it to
compute how slow each kilometre of getting from a basalt quarry to a
farm is, given the local roads and terrain.

**Discount rate** — The annual percentage by which we reduce the
value of future dollars when comparing them to today's dollars. We
use 10 % per year as a baseline.

**EcoCrop** — A long-established crop-suitability model that scores
how suitable a given environmental condition (soil pH, temperature,
moisture) is for a given crop on a 0 to 1 scale.

**Enhanced rock weathering (ERW)** — The deliberate spreading of
finely-ground silicate rock (in this project, basalt) on cropland to
accelerate the natural chemical weathering reactions that consume
atmospheric CO₂.

**FAOSTAT** — The Food and Agriculture Organization's online
statistics database. We use it for crop-by-country producer prices.

**Gabbro** — The intrusive (slower-cooled) equivalent of basalt;
chemically nearly identical. We include it in the feedstock supply
because it has the same desirable properties.

**GLiM** — The Global Lithological Map: a worldwide map of surface
rock types, used here to find where basalt outcrops actually are.

**Grain size** — How finely the rock is ground. We work in
micrometres (µm). Below about 50 µm, dissolution is fast but grinding
costs jump sharply.

**Gross margin** — In economics, total revenue minus total variable
cost. In our model, the CDR revenue plus the yield revenue minus the
delivered + on-farm cost.

**Lime-equivalent demand** — The agronomic concept that there is a
specific quantity of agricultural lime that would, in theory, bring a
soil to its crop's optimum pH. Basalt and lime have similar
mechanisms, so we convert the lime requirement to a basalt
requirement using the rock's calcium and magnesium content.

**LiTAS** — Lime-Targeted Application Strategy: one of the more
recent and accurate recipes for calculating the lime-equivalent
demand on tropical acid soils. Defined by Aramburu Merlos and
colleagues in 2023.

**Malaria Atlas Project (MAP)** — A research consortium that, among
other things, publishes a global 1-km "friction surface" that scores
how slow it is to traverse each pixel on the Earth's surface. We use
this for the cost-distance calculation in Block 4.

**MRV** — Measurement, reporting, and verification: the protocols
that a carbon-credit buyer requires to be convinced that the carbon
removal they are paying for actually happened. Default cost in our
model: $20 per tonne of CO₂ (lowered from $30 in the 2026-05-26
refresh; inside the $15–71/tCO₂ range of Mercer et al. 2024, LSE
Grantham Research Institute).

**NPV** — Net present value. The discounted sum of a stream of
future cash flows. Used here when we want to compare an ERW
deployment over a ten-year horizon to one over a single year.

**Pedogenic carbonate** — Soil-formed carbonate. Where conditions are
arid, some of the alkalinity that the dissolving rock releases
doesn't make it to the ocean; it precipitates as solid carbonate
right in the soil. This locked-up alkalinity does not count as a
permanent carbon removal, so we subtract it.

**Pixel** — A 1 km² (more precisely, about 0.083 ° on a side, or
roughly 9 km × 9 km after our 10-fold spatial aggregation) cell of
the working grid. Every output of the model is a per-pixel number.

**Pyroclastic** — Volcanic rock made of fragments of pre-existing
volcanic material. In GLiM, marked `py`. Same chemistry as basalt.

**Quarry-gate price** — The price you pay for the rock at the quarry
gate, before transport. We use $10 per tonne for basalt fines.

**Recocrop** — An R-package implementation of EcoCrop, used here for
the EcoCrop-arm fall-back of Block 6.

**SoilGrids** — A global gridded map of soil properties (pH, bulk
density, exchangeable cations, ...) produced by ISRIC. We use the
1-km Africa subset.

**SPAM** — The Spatial Production Allocation Model: a global gridded
dataset of where which crops are grown, produced by the International
Food Policy Research Institute.

**Supply curve** — A graph that shows, for each level of annual
basalt supply (in million tonnes per year), the marginal price per
tonne CO₂ at which the next tonne is removed. The standard economic
output of a deployment-ranking exercise.

**Targeted vs uniform** — See *Allocation rule*.

**Working grid** — The common 9-km grid on which all the model's
inputs and outputs are co-registered. Built in Block 1.
