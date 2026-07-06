# Enhanced Rock Weathering (ERW) — Evidence Review for an SSA Ex-Ante Analysis

This document reviews the current state of evidence on Enhanced Rock Weathering (ERW), with an emphasis on the geospatial profitability model for Sub-Saharan Africa (SSA) implemented in this repository (`erw-1` through `erw-8`, plus the optional `erw-basalt-access`, `erw-energy-country`, `erw-yield-fit`/`predict`, and `erw-supply` modules).

---

## 1. What ERW is

Enhanced Rock Weathering is the deliberate spreading of finely crushed silicate rocks — most commonly **basalt** — onto agricultural soils to (a) accelerate the natural geochemical weathering reaction that draws CO₂ out of the atmosphere and (b) deliver agronomic co-benefits very similar to those of agricultural liming.

It is one of a small set of "open-system" carbon dioxide removal (CDR) pathways that can plausibly scale to gigatonnes per year, alongside afforestation, BECCS, biochar, and ocean alkalinity enhancement. Unlike DAC or BECCS it has no engineered point of capture; the reaction happens in the soil column over months to years and the dissolved inorganic carbon (DIC) it produces is transported through soil water → rivers → ocean, where it is stored for >10,000 years as bicarbonate (HCO₃⁻) and ultimately as marine carbonate sediments.

Conceptually ERW is liming with a different rock: instead of CaCO₃ (which releases CO₂ when it neutralises soil acidity, so it is carbon-neutral at best), ERW uses silicate minerals whose dissolution consumes CO₂.

---

## 2. The chemistry — why a silicate rock removes CO₂

The reaction for a representative basaltic mineral (anorthite, CaAl₂Si₂O₈):

```
CaAl₂Si₂O₈ + 2 CO₂ + 3 H₂O → Ca²⁺ + 2 HCO₃⁻ + Al₂Si₂O₅(OH)₄
   (silicate)                    (released to soil solution)    (kaolinite, stays in soil)
```

Three things happen at once:

1. **CO₂ consumption** — carbonic acid (formed from atmospheric and soil-respired CO₂) attacks the mineral surface. Two moles of CO₂ are converted to two moles of bicarbonate per mole of divalent cation released.
2. **Cation release** — Ca²⁺, Mg²⁺, K⁺, Na⁺ go into soil solution. These raise pH and ECEC and provide plant-available nutrients.
3. **Bicarbonate export** — most of the HCO₃⁻ eventually leaches with drainage water to rivers and the ocean, where it is stable. A smaller fraction precipitates as pedogenic carbonate.

Contrast with lime:
- Lime (CaCO₃): `CaCO₃ + CO₂ + H₂O → Ca²⁺ + 2 HCO₃⁻` — net **zero** CO₂ uptake from the atmosphere (the carbon in HCO₃⁻ came from the limestone itself).
- ERW (silicate): the carbon in HCO₃⁻ comes from **atmospheric CO₂**, so it is a true sink.

This is why ERW is treated as a CDR technology and lime is not, even though their agronomic effects look very similar.

---

## 3. Feedstock options

| Rock type        | Example minerals                | Reactivity | Cation supply        | Risk concerns           |
|------------------|---------------------------------|------------|----------------------|-------------------------|
| Mafic (basalt)   | plagioclase, pyroxene, olivine  | High       | Ca, Mg, K, P, Si     | Low (preferred)         |
| Ultramafic       | olivine, serpentine             | Very high  | Mg                   | High Ni, Cr — concern   |
| Felsic (granite) | feldspar, quartz                | Low        | K, Na                | Low reactivity          |
| By-product slags | wollastonite, steel slag        | Very high  | Ca                   | Variable contaminants   |

**Basalt is the leading candidate.** It is the most abundant volcanic rock on Earth, already mined as aggregate for roads and construction, and ~20% of quarry output is "fines" (<10 mm) that are too small for aggregate and tend to stockpile — a ready feedstock. Mafic rocks have Ni and Cr levels roughly an order of magnitude below ultramafics, putting them well below most agricultural-soil contamination thresholds at typical application rates.

Olivine was originally favoured for its fast dissolution kinetics but has been largely set aside for agricultural ERW because of its Ni/Cr load.

---

## 4. Application practice

The three operational levers are **rock type**, **grain size**, and **application rate**.

- **Grain size.** Dissolution rate scales roughly with specific surface area, so smaller is faster — but milling costs and dust hazards rise sharply below ~10 µm. Empirically, silt-dominated powders (<45 µm) weather at roughly double the rate of sand-dominated (150–500 µm) material. Reported CDR rates span 2.8–6.8 t CO₂/ha/yr across this range; ~3–4 t/ha/yr for fine-medium sand and ~6–7 t/ha/yr for fine-medium silt.
- **Application rate.** Field trials and commercial deployments cluster at **10–50 t/ha**, applied either once or annually. Pot studies have tested 0–100 t/ha. A 50 t/ha basalt application has a theoretical maximum CDR of ~20 t CO₂/ha if all the divalent cations weather and reach the ocean as HCO₃⁻ — but realised rates are much lower over realistic time scales.
- **Timing.** Spread once at the start of the season (similar to a lime pass) using existing manure/lime spreaders. No special machinery is needed.

---

## 5. CDR potential — what the evidence shows

### Global / continental modelling
- Beerling et al. (Nature, 2020) estimate that deploying ERW on global croplands could remove **0.5–2 Gt CO₂/yr by 2050** at scale, with the highest per-hectare potential in the warm-humid tropics. Tropical croplands (~680 Mha) sit at the top of the priority list.
- Baek et al. (2023) and Beerling et al. (Nature, 2025) confirm that climate is a first-order control: high temperature and moisture roughly double weathering rates compared to temperate sites. US-state-level modelling gives 0.16–0.30 Gt CO₂/yr by 2050 rising to 0.25–0.49 Gt CO₂/yr by 2070.

### Field-trial evidence (the picture is mixed)

| Site / system                                | Result                                                                                 | Conditions                  |
|----------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------|
| US Corn Belt (PNAS, 2024, Beerling group)    | Cumulative **3.8 → 10.5 t CO₂/ha** over 4 annual applications; yield +12–16%           | Warm-humid, mildly acidic   |
| Kisumu County, Kenya (Haque et al. 2025, CDRXIV)    | Maize yield **+71% Y1, +79% Y2** from a single 20 t/ha **nephelinite** (volcanic rock powder) application; +$326/ha    | Tropical smallholder, pH 6.4 |
| InPlanet (Brazil, 2025)                       | First independently MRV-verified ERW credits issued (Isometric protocol)              | Tropical, multiple crops    |
| Swiss vineyards (ES&T, 2025 — Dupla et al.)   | Only **~100 kg CO₂/ha/yr** — 10–30× below the higher published rates                  | Cool, alkaline, vineyard    |

The Swiss result is important: it does **not** invalidate ERW but underlines that **climate, soil pH, and drainage** dominate realised rates. Tropical, mildly-acidic, well-drained, vegetated systems consistently sit at the high end of the response distribution — which is exactly the agroecological space most of SSA occupies.

---

## 6. Agronomic co-benefits

The agronomic case for ERW in SSA is, in some respects, stronger than the carbon case:

- **Liming effect.** Basalt raises soil pH by typically 0.2–0.5 units at 10–20 t/ha. The mechanism is identical to lime (cation release neutralises H⁺), so anywhere that calcic lime improves yield, basalt should too.
- **Macronutrients.** Ca, Mg, K released as cations; P released from accessory apatite. Multiple studies report higher tissue Ca, K, and grain K after basalt application.
- **Silicon.** Basalt is the only practical bulk source of plant-available Si for cereals (rice, sorghum, maize, wheat), where Si improves drought tolerance and reduces pest pressure.
- **CEC.** ERW raises cation exchange capacity, improving fertiliser use efficiency.
- **Yield responses observed.** +9–20% on temperate cereals (oats, corn, soybean); +71% Y1 to +79% Y2 on smallholder maize in the Kisumu/Kenya trial (Haque et al. 2025). The headline tropical numbers are very large but rest on a small evidence base.
- **Lime substitution.** A basalt pass every 3–5 years may substitute for routine maintenance liming, with implications for the existing GAIA economics.

---

## 7. SSA-specific evidence and reasons to prioritise

Why SSA is a strong ERW candidate:

1. **Acid soils everywhere.** Large fractions of cropland in Central and East Africa already have acidity saturation >10–20% (this is exactly what `erw-1-layers-soilgrids.R` maps). ERW addresses the same constraint as lime but adds a carbon revenue stream.
2. **Climate favours fast weathering.** Mean annual temperature and rainfall across most of SSA's cropping zones put it close to the global optimum for silicate dissolution kinetics.
3. **Existing yield gaps are huge.** The marginal benefit of a unit of yield uplift is high; the smallholder Kenya trial saw +$326/ha at a single application.
4. **Basalt is available locally.** East Africa Rift, the Ethiopian highlands, parts of West Africa (Cameroon, Nigeria), and Southern Africa have extensive basalt outcrops and existing quarry infrastructure, reducing the transport-cost penalty that dominates ERW economics.
5. **CDR finance is a new income source.** SSA farmers do not currently access compliance carbon markets at scale; ERW is one of the few CDR pathways where smallholders are directly involved in the activity.

Headwinds specific to SSA:
- Grinding and transport infrastructure is thin outside South Africa, Kenya, and a few hubs.
- MRV in smallholder contexts is hard — Isometric/Puro protocols assume soil-sampling cadences that may not be practical without aggregator support.
- Land tenure and the question of who owns the carbon credit are unresolved.
- Smallholder cash flow: 10–20 t/ha of rock is heavy and visible; without subsidy or upfront credit advance, farmers cannot finance it.

---

## 8. Risks and concerns

- **Heavy metals.** Ni and Cr from olivine and ultramafic feedstocks have been shown to leach into soil pore water and groundwater (up to 17% Ni mobility in acid forest soils). Mitigation: restrict to mafic basalts with documented chemistry; cap application by Ni/Cr load rather than just by tonnage.
- **Dust exposure.** Sub-10 µm silicate dust is a respiratory hazard during grinding and spreading. PPE and wet-spreading protocols mitigate but do not eliminate.
- **Pedogenic carbonate.** Some of the alkalinity precipitates as soil carbonate rather than being exported. In semi-arid regions this fraction can be large and is currently a major MRV uncertainty.
- **Verification.** Realised CDR ≠ theoretical CDR. The Swiss trial is the cautionary case; without site-specific MRV, model-only credits risk being over-issued.
- **Lifecycle emissions.** Grinding, transport, and spreading consume fossil energy. At long haul distances (>500 km) the emissions can erode a large share of the gross CDR.
- **Soil biota.** Most field trials show neutral or positive effects on microbial and earthworm communities, but long-term data is thin.

---

## 9. Economics and MRV (2025 state of the art)

- **Cost range.** Recent University-of-Alberta and IEA-aligned estimates put levelised cost of CDR via ERW at **$16–343/t CO₂** in North America, with most pathways landing in $80–200/t. Cost is dominated by feedstock transport and grinding energy, not by spreading.
- **Credit market.** ERW credits transacted in 2024–2025 in the **$100–250/tCO₂** range, with leading buyers being Frontier, Microsoft, Stripe, and JPMorgan.
- **MRV protocols.** Isometric's Enhanced Weathering Protocol (used to verify InPlanet's first credits in Q1 2025) and Puro.earth's 2025 ERW Edition are the two reference standards. Both require **direct measurement** (soil cation budgets, leachate chemistry, or dissolved-inorganic-carbon flux) rather than purely model-based crediting.
- **Net vs gross.** Credits are issued only on **net** CDR after subtracting lifecycle emissions, the pedogenic-carbonate fraction, and a leakage/permanence buffer.

---

## 10. How the GAIA ERW pipeline implements this

The repository's `erw-*` scripts realise the modelling outlined above. The components are:

### Soil + crop foundations
- SSA mask and cropland filter (`erw-1-layers-soilgrids.R`).
- SoilGrids properties (pH, ECEC, exchangeable acidity, bulk density, bases).
- SPAM crop layers (area, production, yield) for 23 crops (`erw-2-layers-spam.R`).
- EcoCrop-based yield-loss function (`erw-5-crop-yield-loss-function.R`) for the agronomic side: the response of yield to acidity is the same whether the corrective amendment is lime or basalt. Crop-tolerance parameters live in `erw-4-crop-parameters.R`.

### Basalt-specific layers
| Component                                | Role                                                                |
|------------------------------------------|---------------------------------------------------------------------|
| `erw-3-basalt-requirements.R`            | Computes lime-equivalent CaCO₃ rates (Kamprath/Cochrane/LiTAS) via `limer::limeRate`, then converts to t basalt/ha using user-set feedstock chemistry (CaO/MgO mass fractions), the Lewis-2021 reactive-fraction calibration, and a grain-size lever. Produces both LiTAS-targeted rates and uniform 10/20/50 t/ha rates. |
| `erw-9-cdr-yield.R`                      | Per-pixel CDR (t CO₂/ha): climate-and-pH scaling on the per-tonne CDR potential, with an aridity-driven pedogenic-carbonate deduction (UNEP 1992 classes using MAP as v1 proxy for AI=P/PET). |
| `erw-basalt-access.R`                    | Delivered basalt price ($/t) from quarry-gate price + cost-distance × $/min/t. Uses GLiM (basic volcanic) + MAP friction surface. Also exports a transport-km raster for the LCA component. |
| `erw-energy-country.R`                   | Per-country electricity price + grid CI rasters; drives spatial grinding economics and grinding LCA. |
| `erw-yield-fit.R` / `erw-yield-predict.R`| Optional Bayesian hierarchical model fitted to the manually-curated ERW field-trial dataset (`erw-trial-data.csv`). Replaces EcoCrop response in `erw-7` when output rasters are present. |

### Economics and supply
- `erw-7-profitability-function.R` — decomposed cost (quarry + grinding + transport + spreading), derived per-pixel LCA, MRV deduction, time-resolved CDR (NPV regime), and four allocation rules (targeted + uniform 10/20/50). Emits agronomic-only, CDR-only, and combined gross-margin layers.
- `erw-8-sensitivity-analysis.R` — five sweeps: prices × MRV × yields × grain size × allocation rule.
- `erw-supply.R` — supply-constrained deployment ranking by GM-per-tonne-basalt; supply curves for 1–500 Mt/yr caps.

### Headline output
**Map of profitable basalt-ERW hectares in SSA, separated by (a) agronomic profitability alone, (b) CDR revenue alone, (c) combined.** Region (c) is the policy-relevant one and is expected to be substantially larger than either alone — that is the core thesis the pipeline tests.

---

## 11. Key open questions for the modelling

1. What is the right CDR-rate function for SSA cropping systems? The Beerling-group reactive-transport model is calibrated mostly on US/UK soils; a simple climate-and-pH regression calibrated to the Kenya, Brazil, and India trials may be more honest.
2. How do we handle the pedogenic-carbonate fraction in semi-arid SSA? It can be 20–50% of alkalinity in dry zones — pure ocean-export accounting overstates CDR there.
3. Is basalt fines supply elastic in SSA? Quarry capacity is finite. A supply-constrained version of the analysis (basalt as a scarce input with a rising price) is more realistic than treating it as infinitely available at quarry price.
4. Should the analysis be at SPAM crop resolution or aggregate to cereals / legumes / RTBs / commodity? Per-crop credibility of the yield response is weaker for ERW than for lime.
5. Is the unit of analysis the pixel (5–10 arcmin) or the farm? Smallholder MRV is the binding constraint; some aggregator structure (cooperatives, off-takers) is implicit in any deployable solution.

---

## 12. Selected references

- Beerling, D. J. et al. (2020). *Potential for large-scale CO₂ removal via enhanced rock weathering with croplands.* Nature 583, 242–248.
- Beerling, D. J. et al. (2024). *Enhanced weathering in the US Corn Belt delivers carbon removal with agronomic benefits.* PNAS 121 (9), e2319436121.
- Beerling, D. J. et al. (2025). *Transforming US agriculture for carbon removal with enhanced weathering.* Nature. doi:10.1038/s41586-024-08429-2
- Haque, F. et al. (2025). *Agronomic Performance of Enhanced Rock Weathering in a Tropical Smallholder System: A Maize Trial in Kenya.* CDRXIV preprint 410 (Flux Carbon / UNCCD). <https://cdrxiv.org/preprint/410>.
- Baek, S. H. et al. (2023). *Impact of climate on the global capacity for enhanced rock weathering on croplands.* Earth's Future 11, e2023EF003698. doi:10.1029/2023EF003698.
- Dupla, X., Bertagni, M. B. & Grand, S. (2025). *Three Years of Field Trials Indicate a Sustained Enhanced Rock Weathering Signal with Limited CO₂ Removal.* Environmental Science & Technology 59 (48), 25751–25764. doi:10.1021/acs.est.5c09820.
- Dupla, X. et al. (2023). *Potential accumulation of toxic trace elements in soils during enhanced rock weathering.* European Journal of Soil Science. doi:10.1111/ejss.13343.
- Edwards, D. P. et al. (2017). *Climate change mitigation: potential benefits and pitfalls of ERW in tropical agriculture.* Biology Letters.
- Hartmann, J. et al. (2013). *Enhanced chemical weathering as a geoengineering strategy.* Reviews of Geophysics.
- Carbon Direct (2025). *2025 Criteria for High-Quality CDR: Enhanced Rock Weathering.*
- Isometric (2024). *Enhanced Weathering Protocol v1.0.*
- Puro.earth (2025). *ERW Methodology Edition 2025 v1.*
- UK Government (2025). *Enhanced rock weathering: evidence on potential environmental impacts and social implications.*

---

## 13. Recommended next steps

1. **Bayesian yield-uplift dataset growth.** `erw-yield-fit` currently has ~14 trial rows; the priors dominate. Each new published ERW field trial materially tightens the posterior — the dataset should be appended as new results are published.
2. **CGIAR-CSI Global Aridity Index upgrade.** `erw-9` uses MAP alone as a proxy for AI = P/PET in the pedogenic-carbonate deduction. The 1 km AI dataset is a strict improvement.
3. **Process-model cross-check.** Run the Beerling-group cropland reactive-transport model on a sample of SSA pixels and compare to `erw-9`'s climate-scaled output. If systematic bias appears, recalibrate the climate factor.
4. **Country-level credit eligibility.** Encode Article-6 corresponding-adjustment status into the `erw-supply` ranking — credits from countries that restrict export should be discounted.
5. **Aggregator finance structures.** The headline GM layer assumes the farmer captures the full credit revenue. Sensitivity analysis on aggregator-take fractions (10–40%) would clarify where smallholder economics actually clear.
6. **Headline-figures script.** A single script that takes `economics_erw/` rasters and emits the report-ready maps and tables (profitable-area maps by allocation rule and regime; per-country totals; break-even surfaces).

The geospatial machinery (SoilGrids stack, SPAM crops, EcoCrop response, FAOSTAT price plumbing, `limer` agronomic lime rates) is in place. The work that remains is dataset growth, aridity-index upgrade, and downstream reporting — not new model components.
