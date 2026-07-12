# Prep for hard questions - ERW ex ante model

*Grounded in the committed code (`erw/erw-*.R`, `paper/analysis/`) and the manuscript. Each item gives the short answer, the specifics, and - where it matters - the honest weak spot and how I'd respond. Numbers are the equilibrium, targeted, net-export headline unless noted.*

---

## A. Data and cost assumptions

### 1. Source of basalt feedstock locations; alternatives; other assumptions

**Source.** Feedstock *source geology* comes from the **GLiM - Global Lithological Map** (Hartmann & Moosdorf 2012; PANGAEA doi:10.1594/PANGAEA.788537). We rasterize three mafic classes as basalt-equivalent feedstock: `vb` basic volcanic (basalt s.s.), `py` pyroclastics (basaltic tuff), and `pb` basic plutonic (gabbro). Ultramafic classes are **deliberately excluded** for cropland use because of Ni/Cr leaching risk. `erw-basalt-access.R` / `erw-build-basalt-mask.R`.

These GLiM polygons are the *origin points*; delivered cost is then a cost-distance from every cropland pixel to the nearest source (see Q2).

**Alternatives we could/should offer.**
- **National / regional geological surveys** at finer resolution than GLiM (GLiM is coarse and lumps lithologies); would sharpen source locations, especially in the East African Rift.
- **Active-quarry point inventories** (the code already supports an optional quarry-point mask). Real ERW would source from operating quarries with crushing capacity, not from every basalt outcrop - this is arguably the more economically honest source set.
- **Mine-tailings / by-product silicate streams** (steel slag, mine waste) as alternative feedstocks - different chemistry, different geography.

**Other assumptions worth stating up front.** A single "representative basalt" chemistry (CaO 10%, MgO 7%, plus K/Na/P; Ni 100 ppm, Cr 200 ppm) is applied everywhere - we do **not** vary feedstock chemistry by source. Grain size is fixed at 50 µm. Both are decision levers we hold constant in the headline and could sweep.

**Weak spot / response.** "GLiM outcrops ≠ deliverable supply." True - we map *geological availability*, not *quarry capacity or permitting*. The transport layer partly compensates (remote sources are expensive), but a production version should intersect with an active-quarry inventory. Frame the current map as an upper bound on feedstock access.

### 2. Fixed vs variable components of transportation cost

**Transport is modeled as purely *variable* (distance/time-proportional):**

`transport_cost ($/t) = travel_time(min) × $0.04/min/t`

- `$0.04/min/t` = a 30-tonne truck at ~$80/hr operating cost (`USD_PER_MIN_PER_T`).
- `travel_time` = accumulated cost-distance from the nearest basalt source over the **Malaria Atlas Project friction surface** (Weiss et al. 2020, nominal 2019), which folds in roads, terrain, rivers, urban slow-downs. `terra::costDist`.
- Haul distance for the LCA is `travel_time × 0.5 km/min` (≈30 km/h effective). Pixels beyond a **1,000 km cap** are treated as unreachable.

**The genuinely fixed (per-tonne, location-independent) costs live elsewhere in the stack:** quarry-gate feedstock ($10/t), grinding (set by grain size and local power price), and spreading ($8/t). See the Q3 table.

**Weak spot / response.** There is **no separate fixed loading/handling charge, no backhaul/return-trip accounting, no rail option, and no trucking economies of scale** - it's a linear per-tonne-per-minute haulage cost. That likely *overstates* marginal cost for long, high-volume, road- or rail-served hauls and *understates* the fixed cost of short hauls. Honest framing: a transparent first-order haulage proxy; the sensitivity analysis should sweep `$/min/t` because delivered cost is the dominant swing variable.

### 3. Explicit "other costs" (grinding + feedstock + spreading + ?) - table

Delivered basalt cost is decomposed per tonne (`erw-7`, `erw-3`, `erw-basalt-access`):

| Component | Value (reference) | Type | Basis / source |
|---|---|---|---|
| Ex-quarry feedstock (quarry gate) | **$10 / t** | fixed per t | basalt-fines aggregate by-product price (`QUARRY_GATE_USD_T`) |
| Grinding to 50 µm | **≈$1.94 / t** at $0.10/kWh; per-pixel = **19.4 kWh/t × local electricity price** | fixed per t (varies by country power price) | Strefler et al. 2018 grinding-energy curve; 0.07 GJ/t = 19.4 kWh/t at 50 µm |
| Transport (haulage) | **travel_time × $0.04/min/t** (spatial) | variable (distance) | 30-t truck @ ~$80/hr over MAP friction surface (Q2) |
| Spreading (on-farm application) | **$8 / t** | fixed per t | `SPREADING_USD_T` |
| **= Delivered cost / t basalt** | quarry + grind + transport + spread | | consumed by `erw-7` as `basalt_cost_per_t` |
| MRV (separate) | **$20 / tCO₂** | per tCO₂, netted from carbon price | see Q4 |

Two things are handled as CO₂, not dollars, and are subtracted from gross removal (lifecycle emissions, kg CO₂/t basalt): grinding (`kWh/t × grid carbon intensity`, country raster; fallback 0.60 kgCO₂/kWh), transport (`km × 0.12 kgCO₂/t-km`, diesel truck), and spreading (0.5 kgCO₂/t).

**A cost table like this belongs in the paper** (or SI) - it's the clearest way to preempt Q2-Q4 and it's currently only in prose/comments.

**Weak spot.** Grinding-plant capex, quarry royalties, storage, and financing are *not* itemized - they are implicitly inside the $10 quarry gate and the energy-based grinding proxy. The $10/t is optimistic (assumes fines are a cheap by-product); worth a sensitivity row.

### 4. The MRV assumption, explicitly

**MRV = $20 per tCO₂**, subtracted directly from the carbon price so revenue = `net_CDR × (carbon_price − MRV) = net_CDR × ($150 − $20)`. `MRV_COST_USD_T_CO2` in `erw-7`.

The stack it represents: field sampling, lab analysis, verification, and registry fees. Code comment records the reasoning: **$30/tCO₂** is the first-of-kind pilot benchmark (Levy et al. 2024); **$20** is the at-scale aggregator/pooling target (Isometric/Puro-type protocols, 2027+). We use the optimistic-but-defensible $20 in the headline.

**Weak spot / response.** Real early-market ERW MRV (dense soil/water sampling, uncertain reactive-transport models) can run **far above $20** - some estimates put first-mover MRV at $50-100+/tCO₂. Since MRV enters one-for-one with price, it's a first-order lever. Response: hold it explicit, sweep $20/$30/$50, and note the headline uses the mature-market value.

---

## B. Carbon accounting (slides 8-9)

### 5. Definition of "durable" CDR

Two deductions, applied in sequence, define what we credit:

1. **Gross CDR** - CO₂ consumed by basalt weathering, scaled by a climate (temperature/precipitation) factor and a small pedogenic-carbonate loss in arid zones (`erw-9`).
2. **Net-export CDR = max(gross − F·S, 0)** - subtract the alkalinity consumed neutralizing soil acidity, which re-releases its CO₂ (Q7). **This is the "durable" quantity: alkalinity that leaves the field as bicarbonate (HCO₃⁻) with drainage and is stored in rivers/ocean for >10,000 years** (Renforth 2019; Kanzaki et al. 2023). It is durable in the geochemical-permanence sense.
3. **Net (creditable) CDR = net-export − lifecycle supply-chain emissions** (grinding/transport/spreading CO₂). Revenue is on this figure.

So "durable" = removal that survives *both* the acidity re-release *and* the supply-chain emissions - carbon that is actually gone for millennia.

**Weak spot.** ">10,000 years" is the ocean-alkalinity permanence argument; it assumes the bicarbonate reaches and stays in drainage/ocean. Riverine/estuarine CO₂ evasion (some HCO₃⁻ degasses en route) is not modeled and would trim durability further.

### 6. Slide 8 - units of "Durable CDR (Mt)" and "% treated"

- **Durable CDR (Mt)** = millions of tonnes of **CO₂** durably removed per year (net-export basis, equilibrium regime), summed over the area that is public-viable at that carbon price. Metric tonnes CO₂, not tonnes C.
- **% treated** = share of the **17.6 Mha of "treated cropland"** - the acid-eligible cropland that receives the targeted (lime-equivalent) dose (defined in Q12). It is **not** all cropland. The manuscript also reports the all-cropland share (of 146 Mha, ~one-eighth of the treated share) for reference. So "$150 → 9.4% treated" means 1.65 Mha of the 17.6 Mha treated base, ≈1.1% of all SSA cropland.

### 7. Slide 9 - reference for `durable = max(gross − F·S, 0)`, and F = 0.88

**The equation is mass balance, not a fitted parameter.** It's our own derivation (documented in `paper/netexport-cdr-memo.md`), resting on the standard geochemistry that neutralizing acidity re-releases CO₂ exactly as agricultural lime does (Hartmann et al. 2013; the lime analogy is textbook). The acidity sink `S` is the soil's lime requirement in t CaCO₃/ha, computed by `erw-3` via the LiTAS/Kamprath method (Aramburu-Merlos et al. 2023).

**F = 0.88 tCO₂ per t CaCO₃-equivalent** falls straight out of the feedstock's own constants:

```
F = CDR_eff / effective_NV
  = 87.6 kg CO2 per t basalt  ÷  99.6 kg CaCO3-eq per t basalt
  = 0.88 tCO2 / tCaCO3-eq
```

Plainly: one tonne of our basalt removes 87.6 kg CO₂ *and* supplies 99.6 kg of acid-neutralizing capacity. So each unit of neutralizing capacity "carries" 0.88 units of CO₂ - and when that capacity is spent fighting soil acidity instead of exporting, that 0.88 is re-released. `S` is per-regime: **standing exchangeable acidity** (`caco3_kamprath`) for year-1/NPV, **annual maintenance acidity** (`caco3_merlos_maintenance`) for equilibrium.

**Important reproducibility note (be ready for this).** `erw-9` writes *both* gross (`cdr_yield_*.tif`) and net-export (`cdr_yield_*_netexport.tif`) rasters. The headline net-export envelopes were produced by the analysis engine that applies `max(gross − F·S,0)` directly; **`erw-7` as currently committed reads the gross rasters.** Before submission we should repoint `erw-7`/`erw-11` at the `_netexport` layers so the R pipeline reproduces the headline end-to-end. If asked "does the committed pipeline produce the net-export numbers in one run?" - the honest answer is "the deduction is implemented in `erw-9` and the analysis engine; wiring `erw-7` to consume it is a cleanup item on the reproducibility checklist."

**Weak spot we already flag (memo §6).** This is a **first-order sequential bound** - it assumes the acidity sink is fully paid down *before* any alkalinity exports. Reality is simultaneous: some carbon exports even on acid soils, and re-acidification keeps regenerating the sink. Truth lies between "gross" (old) and "net" (this). We present both as bounds and lead the carbon case on equilibrium, where they converge.

---

## C. Agronomic response (slide 10) and kinetics (slides 10-11)

### 8. The EcoCrop model; which crops; pH vs exchangeable acidity

**EcoCrop** is FAO's crop environmental-requirements database; we run it through the R package **`Recocrop`**. It maps an environmental variable to a **relative yield (0-1)** using a piecewise-linear/trapezoidal response defined by breakpoints (absolute min, optimum-lower, optimum-upper, absolute max). `erw-4`, `erw-5`.

**Crops (23, all SPAM):** maize, sorghum, common bean, chickpea, lentil, wheat, barley, arabica & robusta coffee, pearl & finger millet, potato, sweet potato, cassava, cowpea, pigeon pea, soybean, groundnut, sugarcane, cotton, cocoa, tea, tobacco.

**Which variable - the key point:** the **headline model runs on *acidity saturation* (exchangeable acidity as % of ECEC - effectively aluminum saturation), not pH.** This is the mechanistically correct driver of acid-soil yield loss (Al³⁺ toxicity), and it's what the targeting and yield-loss layers use (`resp_hp`, `soil$hp_sat` vs per-crop `ac_sat` tolerance). We *also* compute a **pH-based** response as an alternative/robustness layer. Yield loss is clamped to [0.2, 1] (we never let ERW "create" more than a 5× yield or a full crop failure).

**Weak spot / response (a sharp coauthor may catch this).** The **over-liming penalty prototype (Refinement 1) was built on the EcoCrop *pH* ceiling** (post-application pH pushed past the crop optimum), whereas the core envelope model runs on *acidity saturation*. That's a mild internal inconsistency of variable. Defensible response: over-liming (raising pH past optimum, inducing micronutrient lock-up) is genuinely a pH phenomenon, so using the pH ceiling for the *penalty* is appropriate even though the *baseline* yield gain is driven by relieving Al saturation - but we should state this explicitly and, ideally, express both on a common axis.

### 9. Slide 10 - buffered shift and the sensitivity band (Refinement 1)

**Buffered shift.** How far pH moves for a given dose of reacted alkalinity `A`:

`final_pH ≈ pH0 + A / β`, where `β = kβ · ECEC` and `A = gross_CDR / F`.

- `A` = reacted alkalinity (t CaCO₃-eq/ha), backed out of gross CDR by the same factor F.
- `β` = the soil's **buffering capacity** - how much alkalinity it takes to move pH one unit. Higher ECEC (cation exchange capacity) → more buffered → smaller pH move per tonne. `kβ` is the (uncertain) proportionality between ECEC and buffering.
- Once the acidity demand is met (`A > S`), extra alkalinity pushes pH *above* neutral toward the crop's ceiling; the EcoCrop pH response then applies a yield haircut past the optimum. That's the over-liming penalty.

**Sensitivity band.** Because both `kβ` (buffering) and the realized-alkalinity multiplier on `A` are uncertain, we carry a **low-high band** over them: low penalty = `(mA=0.5, kβ=2.0)`, central = `(1.0, 1.0)`, high = `(1.5, 0.5)`. "**Uniform-50 is where it bites hardest**" because a blanket 50 t/ha dose massively over-applies relative to the lime requirement on most pixels, so pH is driven far past the optimum: the private return there falls from **$997M (no penalty) to $814M central and ~$8M in the high scenario** - i.e., aggressive uniform over-liming can erase the private return, while the targeted dose is barely touched (4.31 → 4.02 Mha, −7%). This is the intended message: moderate, targeted doses are robust; blanket-high doses are fragile.

**Weak spot.** `kβ` is not calibrated to SSA soils - it's a plausible range, not a measured relationship. Say so.

### 10. Source of the kinetic-saturation assumption (Refinement 2)

**Honest answer: this is a functional-form stress test, not a calibrated relationship.** The multiplier `sat(D) = (Kd + 50)/(Kd + D)` encodes the well-documented qualitative finding that **per-tonne weathering efficiency declines as application rate rises** (a given soil column, moisture, and CO₂ supply can only weather so much rock per year). It is anchored to **Lewis et al. (2021)**, whose ~50 t/ha experiment we use as the reference dose where `sat = 1`, and to the general saturation behavior seen in mesocosm/column studies (e.g., Strefler et al. 2018 on grain-size/rate trade-offs). **The half-saturation constant `Kd` itself is uncalibrated**, which is exactly why we report a *band* (`Kd = ∞/60/30/15`) rather than a point estimate.

**Why this matters for the story (and the likely follow-up).** We show that saturation makes CDR concave in dose (creating an interior optimum) but does **not** drive the public envelope to zero - below the 50 t/ha reference, normalized per-tonne reactivity is actually *higher*, so at targeted doses durable CDR rises. The binding constraint on the carbon case is **MAC > price** (median MAC $446/tCO₂ vs $150 price), *not* kinetics. If pushed - "so you can't cite a number for Kd?" - concede it's uncalibrated and frame it as sensitivity, then pivot to the MAC point, which does not depend on it.

### 11. Slide 12 - "Equilibrium: steady-state durable removal" in plain language

Yes, that bullet reads like jargon. Here's the plain version to use:

> The model runs three timeframes. **Year-1** is the first application on soil that still carries its full historical acidity load. **Equilibrium** is the long-run **maintenance** phase: picture a field whose acidity has already been neutralized (by past liming or earlier ERW), so each year you only add enough basalt to offset *that year's* fresh acidification - from fertilizer, crop removal, and rainfall. In that maintenance state, very little of the weathering is "spent" fighting a backlog of acidity, so most of the alkalinity exports as bicarbonate and counts as durable carbon removal.

We headline equilibrium because year-1 CDR is dominated by paying down a one-time acidity debt (mostly re-released, per Q7), whereas the maintenance/steady state is what an ongoing ERW *program* actually looks like. Retention illustrates it: **year-1/NPV retains only ~19-23% of gross CDR as durable; equilibrium retains ~73-87%** (net-export memo §4). Swap the slide wording to: *"the ongoing maintenance phase, once soils are already at target - when most weathering goes to carbon rather than to clearing an acidity backlog."*

---

## D. The typology map (slide 14)

### 12. The universe of candidate (non-white) pixels

**Non-white pixels = the ~17.6 Mha of "treated cropland": acid-eligible cropland that receives the targeted dose.** Precisely, a pixel is in the universe if, for **at least one of the 23 SPAM crops grown there**, both:

1. **SPAM harvested area > 0** (the crop is actually grown on that pixel), **and**
2. **soil acidity saturation exceeds that crop's tolerance** (`soil$hp_sat > crop ac_sat`) - i.e., the soil is acid enough that liming/ERW is agronomically indicated, so a LiTAS lime-equivalent dose is prescribed.

`erw-7` builds the per-crop mask (`area_mask × acid_mask`); `erw-11` then keeps every pixel where the area-weighted combined margin is defined (`wsum > 0`) and classifies it into private / public / intersection / combined-only / neither. Values are area-weighted across the crops sharing the pixel.

**White pixels** are therefore: non-cropland; cropland that is not acid enough to trigger the targeted dose for *any* crop it grows; or pixels with no defined economics (missing price/soil/CDR). White ≠ "ERW fails" - most white is simply "not acid-eligible" or "not cropland."

**Contrast with the uniform-rate maps:** under uniform 10/20/50 the universe is *all* cropland regardless of acidity (matching the Beerling/Baek convention), so those maps have a larger non-white footprint. Slide 14 is the **targeted, equilibrium** map, so its universe is the acid-eligible 17.6 Mha.

**Weak spot / response.** The acid-eligibility threshold is crop-specific and depends on the SoilGrids acidity-saturation layer and the EcoCrop `ac_sat` tolerances - both uncertain. A reviewer could argue the 17.6 Mha denominator is itself a modeling choice. Fair; it's why we always report shares of *both* treated (17.6 Mha) and all cropland (146 Mha).

---

## Two cross-cutting points to have ready

- **Everything is per-pixel and area-weighted across co-located crops** - there is no single "representative farm"; farm *counts* are a coarse post-hoc conversion using national average holding sizes (order-of-magnitude only).
- **The three levers that actually move the public envelope** are carbon price, delivered cost, and durable-CDR-per-tonne (MAC = cost ÷ durable CDR). Net-export accounting and MAC > price - not kinetic saturation - are what keep the carbon-only case small at today's $150. This is the line to return to whenever a carbon question gets into the weeds.
