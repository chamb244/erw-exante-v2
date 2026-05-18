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
   basalt application [6],
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
   to the Lewis et al. [11] basalt-weathering calibration; tropical
   sites typically dissolve 1.5 to 2 times faster).
3. **The local soil pH** (the more acidic the soil, the faster the
   rock dissolves — this is the chemistry of acid-catalysed weathering,
   peaking near pH 5).

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
   **measuring/verifying the CDR for the carbon market** ($30 per tonne
   of CO₂ removed).

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
(the 2024–25 mid-market for verified ERW credits), MRV cost $30/tCO₂,
discount rate 10 % per year, CDR phasing 30/25/20/15/10 % over five
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
prices; across different yield-uplift levels; across different MRV
costs; across different grain sizes; and across different allocation
rules.

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

By **2026-05-16**, the model is in the following state:

- All five of the input-and-surface blocks (1, 2, 3, 4, 5) have been
  run end-to-end on real data and produce the maps above.
- The pH map matches the qualitative geography of African soils that
  you would expect from any soil-science textbook.
- The CDR yield map peaks in the humid tropics, exactly where the
  literature [2, 5] says it should.
- The delivered-basalt-price map ranges from $10 per tonne (right at
  the outcrop) to $50 per tonne (the cap), with about half of
  Sub-Saharan-African cropland binding at the cap. This is a strong
  signal that *which country a farm is in* matters far more for ERW
  economics than the literature's standard "uniform $30 per tonne"
  assumption used by Renforth [9] and similar global-scale work.
- Block 6's Bayesian-yield arm is **not yet fitted** --- the
  Bayesian-statistics software has to be installed and run on the
  curated trial dataset. EcoCrop is in place as the fallback.
- Block 7 (the profitability function), Block 8 (supply ranking),
  and Block 9 (sensitivity sweeps) **have not yet been run**. All
  their *inputs* are ready; what is left is to execute the run.

## 7.1 Key constants and their sources

Every parameter the model uses can be re-set. The defaults below are
chosen to match the central tendency of the published ERW literature.
Numbers in square brackets refer to the References section (§10).

| Parameter | Default value | Source / justification |
|---|---|---|
| Reference temperature $T_\text{ref}$ | 11 °C | US Corn-Belt anchor used by Lewis et al. [11] |
| Reference precipitation $P_\text{ref}$ | 1000 mm | as above [11] |
| Reactive fraction at reference | 0.20 | calibrated by Lewis et al. [11] |
| Grain-size exponent $\beta$ | 0.5 | surface-area scaling (Strefler et al. [3]) |
| Grinding-energy exponent $\alpha$ | 1.2 | Strefler et al. [3] |
| Pedogenic-carbonate fraction | MAP-binned 0–90 % | UNEP aridity bands [12] |
| Feedstock chemistry (CaO, MgO) | 10 % CaO, 7 % MgO | typical mafic basalt; user-settable |
| Default grain size | 100 µm | mid-range of published ERW trials |
| Quarry-gate basalt price | $10 / t | basalt fines as quarry by-product (industry data) |
| Truck haulage | $0.04 / min / t | 30-t truck @ $80 / hour (industry data) |
| Maximum haul distance | 1000 km | beyond cap, truck-diesel LCA erases the credit |
| Friction surface | MAP 2019 motorised | Weiss et al. [19] |
| On-farm spreading | $8 / t | industry data |
| Carbon price | $150 / tCO₂ | 2024–25 mid-market for verified ERW credits |
| MRV cost | $30 / tCO₂ | sampling + lab + verification + registry (industry data) |
| Discount rate (NPV) | 10 % / yr | conventional infrastructure rate |
| CDR realisation phasing | 30 / 25 / 20 / 15 / 10 % over 5 yr | trial data [5] |

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
3. **The full profitability run is not yet executed.** Blocks 7, 8, and
   9 (profitability, supply-constrained ranking, sensitivity sweeps)
   have not yet been run end-to-end. All their inputs are in place; what
   remains is to execute the run and publish the resulting profitability
   maps and supply curves.
4. **The aridity proxy is rough.** The pedogenic-carbonate deduction
   currently uses mean annual precipitation (MAP) alone, binned into
   UNEP-1992 categories [12]. The literature standard is the full
   aridity index $\text{AI} = \text{MAP} / \text{PET}$, which requires a
   potential-evapotranspiration surface from CGIAR-CSI or computed from
   WorldClim minimum-and-maximum temperatures. We expect this to be a
   small-effort, moderate-payoff upgrade.
5. **MRV cost is a single flat number.** $30/tCO₂ for all pixels and all
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

[14] Aramburu Merlos, F. (2022). *limer: Acidic soil management for
agriculture.* R package, GAIA Africa.
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

# 12. Glossary

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
model: $30 per tonne of CO₂.

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
