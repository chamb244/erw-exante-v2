# Citation review — anchoring the ERW paper to real, aligned literature

**Status: for joint review. Nothing here has been applied to `paper/manuscript.tex`, the `.bib` files, or the R/Python code.**

Prepared 2026-09-01 in response to the referee complaint that references are "not real and identifiable, and even when they are available they don't align with what they are being cited for."

Working materials in this folder:

- `ew-esroc_final_si_combined.pdf` — Suhrhoff et al. (2026), the anchor review (281 pp incl. SI)
- `ew-esroc.txt` / `ew-esroc-references.txt` / `ew-esroc-refs.json` — extracted text and the parsed 813-entry reference list
- `ref-resolution.json` / `ref-verification.json` — 69 priority references resolved to DOIs and verified against CrossRef + OpenAlex (title/author/year all checked)
- `papers/` + `papers/INDEX.md` — 24 downloaded PDFs; 44 more with verified DOIs (22 paywalled, 22 open-access but behind bot-walls — retrievable manually or via CGIAR access)

Reference numbers like **[ESROC 216]** are Suhrhoff et al.'s own numbering; every number cited below is resolved to a verified DOI in `ref-verification.json`.

---

## 1. The anchor source and how to cite it

**Suhrhoff, T.J., Dietzen, C., Kukla, T., Lunstrum, A., Reershemius, T., … Planavsky, N.J., Fuss, S. (2026). An Ecosystem of Carbon Dioxide Removal Reviews – Part 3: Enhanced Weathering.** Submitted to *Energy & Environmental Science* (V1). ~90 authors across Yale NCCC, PIK, Carbonplan, Heriot-Watt, and most of the field's active groups.

How to describe it when citing: a PRISMA/ROSES-compliant systematic review under the ESROC protocol. Web of Science (n=1,193) + Scopus (n=724) to a 2024-07 cutoff, ML-assisted screening, expert snowballing to 2025-04, final corpus of **241 peer-reviewed + 40 non-peer-reviewed EW-CDR studies** plus a separately coded set of **104 agronomic rock-flour studies**; hierarchical codebook applied by 34 contributors with two QA/QC rounds.

Note: it is a **submitted preprint**, not yet peer-reviewed. Use it as (a) the map to primary sources, which we then cite directly, and (b) a citable synthesis for distributional statements (flux medians, cost medians, vote counts) where no single primary source exists. Do not hang a load-bearing constant on it alone.

---

## 2. What is actually wrong with the current citations (audit results)

Full detail in the audit (§6 of this doc lists every fix). Verdict first: **`paper/references.bib` is mostly real** — all 26 DOIs resolve and titles/venues/years match CrossRef. The referee complaint traces to five concrete failure classes:

### 2.1 Misattributions (citation exists but does not support the claim)

| Where | Problem |
|---|---|
| `manuscript.tex:427` + `erw-parameters.md:290` | **Worst one.** The "$30/tCO₂ MRV pilot benchmark" is attributed to Levy et al. 2024 — verified: that paper is an environmental-impacts/monitoring review with **no cost figure**. Real anchor exists: Mercer et al. 2024 (LSE Grantham), EW MRV **$15–71/tCO₂** [ESROC 542] — downloaded. |
| `manuscript.tex:387` | **Wrong Weiss paper.** Cites Weiss et al. 2018 (*Nature*, 2015 surface); the code (`erw-basalt-access.R:101`) uses the **2019 friction surface from Weiss et al. 2020** (*Nat Med*, 10.1038/s41591-020-1059-1). `docs/references.bib` already has the right entry. |
| `manuscript.tex:258` | Table `tab:rates` says Skov et al. 2024 used "20 (up to 100) t/ha" — the trial used a **single rate of 18.86 t/ha**. |
| `manuscript.tex:136` | Oppong Danso 2025 characterized as "relative terms over short horizons" — it is a **five-season** trial reporting **absolute** gains. |
| `manuscript.tex:100` | Kantola 2017 (*Biol. Lett.* opinion piece, no yield data) cited for a yield claim. |
| `manuscript.tex:96` | Renforth 2019 (alkaline **industrial** materials) cited for ocean bicarbonate durability — the right anchor is Renforth & Henderson 2017 [ESROC 37]. |
| `erw-parameters.md:358–364` | Bayesian priors misattributed: intercept prior → Aramburu Merlos 2023 (a lime-requirement paper, no basalt yield data); `log_grain` prior → Strefler 2018 (a grinding-cost paper). |

### 2.2 Unidentifiable / incomplete entries

- `jordan2026` — `@misc`, "CDRXIV preprint", no DOI/URL. **Resolved: DOI 10.70212/cdrxiv.2026502.v1** (author/title exact match; PDF downloaded).
- `jack2013market` — real J-PAL/ATAI white paper, no URL in bib.
- Missing volume/issue/pages: `beerling2025nree` (6(10):672–686), `schiedung2026` (7(4):253–266), `vascosilva2025` (6(8):799–808), `levy2024` (58(39):17215–17226), `tu2026` (1(1)), `kroeger2026` (issue 8).

### 2.3 Wrong author names (looks fabricated to a checking referee)

- `paper/references.bib`: Lewis 2021 — "Wade, Philippa"→**Peter**, "Davies, Kirk"→**Kalu**. Schiedung 2026 — "Harrington, Kimber"→**Kirsty**, "Möller, Bernhard"→**Benjamin**, "Facq, Emilie"→**Ennio**, "Sweere, Theodore"→**Tim**.
- `docs/references.bib`: **`suhrhoff2024` has an entirely wrong author list** (the DOI belongs to Hasemer, Borevitz & Buss); Baek "Seifu"→**Seung**; Levy "Christopher"→**Charlotte**; Reershemius "Tim"→**Tom** (×2); `lewis2021` there additionally lists two people who are not authors.
- Name-form inconsistencies: "Aramburu-Merlos" vs journal's "Aramburu Merlos"; "Vasco Silva, João" vs Crossref "Silva, João Vasco".

### 2.4 Load-bearing claims with zero citations

- **The net-export accounting (tex 432–458) including F = 0.88** — the paper's most novel move, currently uncited. Verified anchors exist (§3.4 below).
- The over-liming penalty section (tex 460–472).
- **The entire solar-haulage results subsection (tex 818–837)**.
- All the cost constants: $10/t quarry gate, $0.04/min/t transport, $8/t spreading, $600/ha framing.
- EcoCrop at tex 389 (the `Recocrop` entry sits unused in `docs/references.bib`).
- brms / the Bayesian fit (tex 1025).

### 2.5 Structural

- `paper/references.bib` (29 entries) and `docs/references.bib` (39 entries) share only 12 keys and **disagree on the shared ones**. The geochemistry anchors the manuscript needs (`west2005`, `hamilton2007`, `renforth2012`, `whitebrantley2003`, `palandri2004`, `recocrop`, `weiss2020`…) live only in the docs bib.
- `docs/erw-parameters.md`'s [S1]–[S37] catalogue is not synchronized with either bib; several [S] items are company blogs, discontinued World Bank series, or reports cited for things they don't contain (e.g. [S17] UNEP *sand* report for basalt fines price; [S19] labelled "AfDB road-cost study" but resolving to the African Economic Outlook).

---

## 3. Parameter-by-parameter citation plan

Format: **parameter (current source) → proposed citations → alignment verdict**. ✅ = literature supports our choice; 🔧 = supported but needs reframing/caveat; ⚠️ = literature pushes against our choice (decision needed, see §4).

### 3.1 Feedstock chemistry & basalt rate (B2)

| Parameter | Current | Proposed anchors | Verdict |
|---|---|---|---|
| CaO 10% / MgO 7% | "Beerling 2020 SI" (vague) | Keep Beerling et al. 2020 [ESROC 19] with a real SI table pointer; add Lewis et al. 2021 [125] (basalt CDR varies **6×** with mineralogy) and Möller & Dupla 2025 [132] (published basalt analyses are systematically unreliable; only 16/56 pass QC totals — supports treating oxide fractions as a **decision variable**, which we already do) | ✅ strengthened |
| Max CDR ~310 kg CO₂/t | stoichiometry | Renforth 2012 [18] + Renforth 2019 [126] (modified Steinour equation; **η = 1.5**, not 2, under seawater buffering); note IAM consensus 0.3–0.33 t/t at complete dissolution | 🔧 must state η and the carbonate-hosted-CaO half-credit caveat |
| Reactive fraction 0.20 | Lewis 2021 mesocosm | Keep Lewis 2021 [125]; add White & Brantley 2003 [225] (field rates orders of magnitude below lab — the *mechanism* for a sub-unity factor) and Brantley 2025 [357] (rates decline 10–100× over 10 yr) | 🔧 reframe as bracketed by lab-field gap literature, single-trial caveat stays |
| Grain-size lever (Strefler form) | Strefler 2018 | Keep Strefler 2018 [23] for the **energy-cost** side; add Rimstidt et al. 2012 [182] + Renforth et al. 2015 [184] (SSA–rate relations, GSA vs BET) — and cite Harrington et al. 2023 [65] / 2024 [208] for the caveat that grain size **does not independently predict field fluxes** | ⚠️ §4.3 |
| Application-rate realism | — | ESROC compilation: **EW field median 20 t/ha** (IQR ~6–100) across 98 studies — directly supports LiTAS-targeted doses and the uniform-20 diagnostic | ✅ new supporting fact |

### 3.2 CDR surface: climate & pH factors (B3, `erw-9`)

| Parameter | Current | Proposed anchors | Verdict |
|---|---|---|---|
| Linear T factor @ 11 °C ref | Kanzaki 2023 "surrogate" (form is ours) | Brantley et al. 2023 *Science* [221] + Deng et al. 2022 [58] (Arrhenius-type exponential); Pogge von Strandmann 2022 [222] + Iff 2024 [223] (orders-of-magnitude lab contrast <10 °C vs >20 °C). Fun fact: 11 °C is exactly the **EW field-trial median temperature** in the ESROC corpus — citable as the anchor choice | ⚠️ §4.2 — linear form under-predicts warm SSA; Arrhenius variant is the better-supported formulation |
| P factor @ 1000 mm ref | "US Corn Belt normal" (uncited) | ESROC corpus: reported precipitation **median ≈ 1000 mm yr⁻¹** (IQR 600–1470) — our anchor is literally the field median. Mechanisms: Maher & Chamberlain 2014 [238], Maher 2010 [239] (drainage/residence time), Cipolla 2022 [ESROC 236] | ✅ finally properly anchored |
| Triangular pH factor peaked ~5 | White & Brantley (generic) | Two-mechanism product: kinetics rise below pH ~5.5 (Palandri & Kharaka [123]; Bandstra & Brantley [217]) × carbon-capture efficiency collapsing below pH ~5 (Bertagni & Porporato 2022 [214]; Holden et al. 2024 [216]; Power et al. 2025 [161]). ESROC explicitly endorses a **unimodal optimum in moderately acidic soils** | ⚠️ §4.1 — unimodal shape vindicated, but the peak likely belongs at ~5.5–6.5, not 5.0 |
| Pedogenic-carbonate deduction, aridity-binned | UNEP 1992 bands; fraction values unsourced | Direction well-supported: Zamanian et al. 2016 [298], Huang et al. 2024 *Science* [286], plus ESROC §4.1.2 (drier ⇒ more SIC). **No MAP thresholds exist in the literature** — keep UNEP bands as an operationalisation, cite [298]/[286] for direction, and add the Raymond et al. 2025 [31] caveat that SIC redissolution can partially recover the penalty (and that the ~50% penalty applies to the precipitated fraction, not 100%) | 🔧 |

### 3.3 Agronomic response (B6)

| Parameter | Current | Proposed anchors | Verdict |
|---|---|---|---|
| Yield uplift evidence base | ~14-trial Bayesian fit + EcoCrop | **There is no published meta-analytic % yield effect for EW** — our prior-dominated fit is honest and roughly state-of-the-art. Cite ESROC's vote count (129 positive : 26 neutral : 11 negative; 13/13 EW field studies positive) and field fold-changes **1.1–1.7×** (Beerling et al. 2024 corn belt [444]; Haque et al. 2025 Kenya [556] — both downloaded; Ramos 2022 [388]); Swoboda et al. 2022 [47] as the agronomy review; van Straaten 2002 *Rocks for Crops* [620] as the SSA-specific foundation | ✅ but see §4.4 on the 2.5× sweep bound |
| EcoCrop constraint-relief framing | uncited | Recocrop (Hijmans; entry exists in docs bib); ESROC's finding that yield response **does not scale with dose** but with the constraint being relieved is direct support for our structure | ✅ |
| Over-liming penalty | uncited | **Absent from ESROC.** Needs classic liming agronomy sources (outside this review). Candidate: von Uexküll & Mutert 1995 [650] for acid-soil context; proper over-liming sources still to be found | ⚠️ open gap |
| Kenya economics | — | Haque et al. 2025 [556]: **+USD 326/ha** revenue in a Kenyan smallholder maize trial — the single most on-point comparator for our private-envelope numbers | ✅ new |

### 3.4 Net-export accounting (the paper's core move)

| Parameter | Current | Proposed anchors | Verdict |
|---|---|---|---|
| F = 0.88 tCO₂/t CaCO₃-eq | **uncited** | ESROC Fig. 15a stoichiometry (2H⁺ + 2HCO₃⁻ → 2CO₂ + 2H₂O = 1 mol CO₂ per mol H⁺ ⇒ 0.88, exactly 2× the IPCC ag-lime EF because lime supplies half its neutralising capacity from carbonate carbon). Cite: West & McBride 2005 [29] + Hamilton et al. 2007 [354] (lime CO₂ charge-balance provenance — both entries already verified in docs bib), plus ESROC §3.4.2 for the charge-balance frame | ✅ **the review confirms 0.88 and warns against being talked down to 0.44** |
| The acidity-sink concept itself | uncited | Holden et al. 2024 [216] (5-yr tropical field: ~46% of dissolution driven by exchangeable acidity; strong-acid weathering can **obviate CDR in some tropical settings**); Bertagni & Porporato 2022 [214]; Kanzaki et al. 2025 [68]. ESROC: "a process **not considered in all global and regional model estimates**" — i.e. our accounting is ahead of the field, citable as such | ✅ major strengthening |
| λ sweep (gross ↔ sequential bound) | our construction | Kanzaki et al. 2025 [68] — lags from <1 yr to many decades as f(CEC, base saturation, hydrology); ESROC's framing: acidity neutralisation is largely a **delay with partial recovery**, not a permanent debit | 🔧 §4.5 — reframe λ=1 as a conservative crediting-horizon bound, not physical truth |
| 30/25/20/15/10% 5-yr phasing | "first-order-shaped" | Kanzaki et al. 2025 [68] (<50% of potential realised in decade 1 in high-CEC soils); Brantley 2025 [357] (rates fall 10–100× over 10 yr) | ⚠️ §4.5 — 5-yr full realisation is optimistic; needs an explicit "dissolution ≠ realised export" statement |
| Riverine/ocean losses (unmodelled) | unacknowledged | Renforth & Henderson 2017 [37]: ~15–20% combined river+ocean loss; Zhang et al. 2024 [66]: river degassing <5% typical, >15% in some regimes; Bertagni & Porporato [214]: >20% mixing loss at low latitudes. Justify omission explicitly and flag direction of bias | 🔧 limitation paragraph with numbers |

### 3.5 Costs, MRV, carbon price (B4/B5/B7)

| Parameter | Current | Proposed anchors | Verdict |
|---|---|---|---|
| MRV $20/tCO₂ | Levy 2024 (❌ misattributed) | **Mercer et al. 2024 (LSE GRI)** [542, downloaded]: EW MRV **$15–71/tCO₂**; ESROC: "a major uncertainty driver". Our $20 sits at the low end — defensible citing the GRI dataset ($15, 2024), but should be presented as a sensitivity band (erw-8 already sweeps 0–80, which is now perfectly anchored) | ✅ fixed + strengthened |
| Carbon price $150 | Frontier blog + cdr.fyi | Keep market refs but harden: CDR.fyi 2024 review (durable CDR weighted avg **$490→$320**; EW transactions cluster **$250–450**; supplier breakeven $349). $150 should be explicitly framed as a conservative floor / compliance-price scenario — it is **below every current market signal**, which strengthens the "public envelope is small at $150" result | 🔧 reframe helps us |
| Grinding energy (Strefler curve) | Strefler 2018 | Keep [23]; add ESROC LCA medians: comminution **median 66 kWh/t** (2–556), grinding+transport ≈ **80% of LCA emissions** — our two modelled LCA terms cover the right 80%. Li et al. 2024 [543] for geospatial grinding cost | ✅ |
| Transport LCA 0.12 kg CO₂/t·km | EEA/BEIS (EU factors) | ESROC distance-normalised set: **0.016–0.177, median 0.057 kg CO₂-eq/t·km** [multiple refs incl. 428]; our 0.12 is within range, above median — fine for SSA truck fleets, say so | ✅ |
| Quarry gate $10/t | UNEP sand report (❌) | USGS crushed-rock average **$17.50/t** + ESROC's own caveat that CDR-suitable fines are "likely not reported in published price statistics" (our defence, now citable); Madankan & Renforth 2023 [133] for reserves/production framing | 🔧 |
| Transport cost $0.04/min/t | van Essen (EU externalities ❌) | Needs a real SSA trucking-cost source — **not in ESROC**; open gap. Zhang et al. 2023 [428] and Kroeger et al. 2026 [544] for transport-dominance framing | ⚠️ open gap |
| Supply caps 1–500 Mt/yr | unsourced | Implied global basalt production **~115 Mt/yr**; US crushed stone 1,500 Mt/yr [ESROC Table 1; 133]. Frame 500 Mt against crushed-stone capacity, not basalt-specific production | 🔧 |
| Our MAC $372–426 median | — | ESROC harmonised cost corpus: **median $193–197/tCO₂**, IQR 137–276, p90 ~335 — we sit at/above p90, and ESROC says Global South medians are **<$250**. Must add a reconciliation: our $/t-rock is in line; our **denominator** (net-export CDR/t) is deliberately conservative. Decompose or invite the "why 2×?" referee question | ⚠️ §4.6 |

### 3.6 MRV/additionality framing (`sec:public`, discussion)

- The liming-substitution counterfactual: ESROC §4.6.6 — "only the **incremental** carbon removal relative to displaced practices can be considered additional" (+ West & McBride [29], Swoboda [47]). Directly relevant to SSA baselines where liming is rare — our envelope logic can cite this.
- **Careful:** ESROC's additionality chapter runs on carbon-accounting counterfactuals, not investment additionality. The only hook for our "intersection = least additional" argument is a bare mention of "financial additionality screens" in registry protocols (Isometric [431], Puro [432], Rainbow [504]). Cite those protocols for the screens' existence; the investment-additionality argument needs the CDM literature (Millock 2013 [ESROC 510]) — or we present it as our contribution, which it genuinely is.
- Registry reality worth citing in the MRV cost discussion: dominant registries require **primary + secondary validation** (two measurement stacks); gas-phase MRV not accepted; models not accepted as standalone MRV.

### 3.7 Heavy metals / ultramafic exclusion, N₂O, solar haulage

- **Ultramafic exclusion**: Dupla et al. 2023 [129, downloaded] (Cr 35–350, Ni 18–195 mg/kg in basalts; Cu/Ni exceed soil limits within years–decades at 40 t/ha/yr; Brazil/Germany regulate); te Pas et al. 2023 [98] + Iff et al. 2024 [223] (olivine Ni near groundwater limits). ESROC nuance to include: field studies mostly show **no** significant accumulation — our exclusion is precautionary, not empirically forced. ✅
- **N₂O (unmodelled)**: ESROC — majority of studies find EW *decreases* N₂O (no magnitudes anywhere); Kroeger et al. 2026 [544] is the only monetisation. Cite as an omitted *benefit* (bias direction favourable to us). ✅
- **Solar haulage subsection**: currently zero citations. Zhang et al. 2023 [428] (transport up to 90% of LCA under long haul) + Kroeger et al. 2026 [544] give the transport-dominance premise; the diesel→solar-electric cost-gap parameters still need an energy-economics source. ⚠️ partially open.

---

## 4. Decisions needed before integration (where the literature pushes back)

1. **pH-factor peak position.** ESROC vindicates the unimodal *shape* but implies the optimum sits ~5.5–6.5 (capture efficiency ≈ 0 below pH 5; kinetics minimum near neutral), not 5.0. Our current peak-at-5 likely **over-credits the most acidic Ferralsol/Acrisol pixels — exactly the pixels our model flags as attractive**. Options: (a) keep 5.0 with an explicit defence + sensitivity on peak position; (b) move the peak to ~5.5–6 and re-run (would shift the envelopes; magnitude unknown).
2. **Temperature factor.** The linear clamp is the weaker formulation; the Arrhenius variant we already built is the better-supported one. Options: promote Arrhenius to headline (raises gross CDR ~27% capped) or keep linear as deliberate conservatism with the Arrhenius variant as sensitivity — either is defensible, but the choice must be argued, not silent.
3. **Grain-size lever.** Harrington 2023/2024 + ESROC: grain size does **not** independently predict field weathering flux. Keep the Strefler lever for the *cost* side; add a caveat that the kinetic benefit of fine grinding is context-limited.
4. **Yield sweep upper bound 2.5×.** Field envelope tops out at **1.7×**. Either cap the sweep at ~1.8× or label >1.7× explicitly as extrapolation beyond the reviewed evidence.
5. **λ and the 5-yr phasing.** Reframe: λ=1 = conservative near-field crediting-horizon bound (ESROC hands us the language: "conservative crediting approaches must either discount delayed CDR ex ante or rely on ex post verification"); phasing tracks basalt dissolution, with realised export lagging (Kanzaki [68]: <50% in decade 1 for high-CEC soils; SSA variable-charge soils amplify this). Also state that the pedogenic and acidity deductions must apply to disjoint alkalinity pools (ESROC's double-counting warning) — worth a one-time check in `erw-9`/`erw-7` that they do.
6. **Cost-median reconciliation.** We are ~2× the literature median and opposite in sign to its Global-South-is-cheaper finding. The fix is presentational: decompose MAC = ($/t rock) ÷ (tCO₂/t rock) and show the numerator is in line while the denominator is the conservative net-export choice. If we don't write this paragraph, a referee will.
7. **MRV cost.** $20 now has a real anchor (GRI $15) but the Frontier-dataset figure is $71; present as a band and note the two-registry primary+secondary validation requirement as a cost driver.
8. **Remaining unanchored constants** (no ESROC help): SSA trucking $0.04/min/t; over-liming penalty parameters; discount rate 10%; the pedogenic-fraction values (0.90/0.70/0.40/0.15/0.00); the diesel→solar gap. These need dedicated sourcing or explicit "assumption" labelling.

---

## 5. Proposed integration order (after we review this doc)

1. **Mechanical bib fixes** (no science): author-name corrections, missing vol/iss/pages, `jordan2026` DOI, `jack2013market` URL, unify the two bibs (single `references.bib`, consistent keys), fix `docs/references.bib` `suhrhoff2024`.
2. **Swap misattributed citations**: weiss2018→weiss2020, Levy→Mercer for MRV, Kantola-2017-for-yield → corn-belt/Kenya trials, Renforth2019→Renforth&Henderson2017 for durability, Skov "up to 100" deletion, Oppong Danso recharacterisation.
3. **Add citations to the uncited load-bearing sections**: net-export (West 2005, Hamilton 2007, Holden 2024, Bertagni 2022, Kanzaki 2025 + ESROC), over-liming, solar haulage, EcoCrop, brms, cost constants.
4. **Add the reconciliation/caveat paragraphs** (§4 items 3, 5, 6, 7) and the new supporting facts (field-median 20 t/ha, 1000 mm median, Kenya +$326/ha, MAC decomposition).
5. **Model changes, if we decide on any** (§4 items 1, 2, 4) — separate commits, re-run affected surfaces, update numbers.
6. **Update `docs/erw-parameters.md`** so every constant's source line matches the new bib, and regenerate the technical report.

---

## 6. Complete fix list for the current bibs (mechanical)

From the verified audit — apply in step 1 above:

**paper/references.bib**
- `lewis2021`: Wade Philippa→Peter; Davies Kirk→Kalu
- `schiedung2026`: Harrington Kimber→Kirsty; Möller Bernhard→Benjamin; Facq Emilie→Ennio; Sweere Theodore→Tim; add 7(4):253–266
- `beerling2025nree`: add 6(10):672–686
- `vascosilva2025`: add 6(8):799–808; author form "Silva, João Vasco"
- `levy2024`: add 58(39):17215–17226; (docs bib: Christopher→Charlotte)
- `tu2026`: add vol 1(1); `kroeger2026`: add issue 8
- `jordan2026`: add DOI 10.70212/cdrxiv.2026502.v1 + URL
- `jack2013market`: add URL
- `aramburumerlos2023`: de-hyphenate to journal form; reconcile with docs `aramburu2023`
- replace `weiss2018` usage with `weiss2020` (10.1038/s41591-020-1059-1)

**docs/references.bib**
- `suhrhoff2024`: entire author list wrong for its DOI (10.3389/fclim.2024.1352825 = Hasemer, Borevitz & Buss) — decide which work was actually meant, then fix key+authors or DOI
- `baek2023`: Seifu→Seung; `reershemius2023`/`reershemius2024`: Tim→Tom (and restore the truncated title "…in Kantola et al., 2023"); `harrington2023`: Kirstine→Kirsty; `lewis2021`: remove the two non-authors; `zhang2022`: issue S1→S2

**New entries to add** (all DOIs verified; see `ref-verification.json` / `papers/INDEX.md` for the full 69): west2005, hamilton2007, holden2024, bertagni2022, kanzaki2025, power2025, renforth2017, renforth2012, mercer2024, dupla2023, swoboda2022, haque2025 (CDRXIV 410), xu2025, wang2021, vonuexkull1995, vanstraaten2002, strefler2018 (already present), brantley2023, deng2022, white2003, brantley2025, zhang2024 (river), harrington2023/2024, madankan2023, li2024, zhang2023 (TEA/LCA), kroeger2026 (present), moller2025, zamanian2016, huang2024, recocrop, burkner2017, suhrhoff2026 (the ESROC review itself).
