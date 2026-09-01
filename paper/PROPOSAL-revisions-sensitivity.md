# Proposal: revisions to the ERW ex-ante model and manuscript, plus a systematic sensitivity plan

> **[2026-09-01] Numbers in this memo are superseded.** The pipeline was re-run
> on the Arrhenius + pH-6.0 basis (erw-9 temperature factor now Arrhenius,
> Ea = 68.8 kJ/mol; pH-factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×)
> after the ESROC-anchored citation review (`litrature/citation-review.md`).
> Current headline (equilibrium net-export, $150/$20, targeted): private 4.31 /
> public 1.95 / intersection 1.32 / combined 7.61 Mha; combined-only 2.67;
> uniform-20 public 3.95 Mha / 20.4 Mt; MAC medians $276 (uniform-20) / $330
> (targeted); core 0.65 / candidate 1.22 Mha. The memo's *reasoning* stands;
> quote numbers only from the 2026-09-01 tables in `docs/tables/`.

*Prepared for the coauthors. Grounded in the committed code (`erw/erw-1`–`erw-11`, `paper/analysis/*.py`), the manuscript, and the two accounting memos. The Central numbers below reproduce Table 2 exactly (targeted, equilibrium, net-export: Private 4.31, Public 1.65, Intersection 1.20, Combined 6.85 Mha), confirmed by re-running the analytic engine.*

---

## 0. Summary

The model is in good shape: the net-export accounting is principled and implemented, the envelope decomposition is a genuine contribution, and the headline reproduces cleanly. The main gaps are not in the science but in (i) **making the robustness analysis consistent with the headline regime**, (ii) **turning three scattered "refinements" into swept parameters rather than separate bounds**, and (iii) **presenting uncertainty in a way an investor or editor can absorb in one look**.

I propose three things, in priority order:

1. **A single layered sensitivity object** (built and run - see §3) that replaces the current mix of one-off sweeps with one reproducible harness producing a named-scenario table, a full-factorial robustness map, and a tornado - all on the equilibrium net-export headline basis.
2. **Six targeted manuscript revisions** (§1), the most important being to recompute the robustness/core section on the headline regime and to fold the over-liming and net-export "bounds" into swept levers.
3. **A shorter list of model refinements** (§2), led by making the net-export deduction a swept partition (λ) instead of a single first-order bound, and porting the over-liming penalty into the R pipeline.

---

## 1. Manuscript revisions

**1.1 Recompute robustness and core-targeting on the headline regime (highest priority).**
The paper leads the carbon case on *equilibrium, net-export* (correctly), but the robustness subsection (§`sec:robust`), the tornado, and the core-targeting map are still computed on the *NPV, gross* grid (`core_priority_npv.png`, the envelope memo's tornado). That is a regime mismatch a careful referee will catch. On the NPV/gross basis, delivered cost was the dominant lever; on the equilibrium net-export basis it is **not** - the CDR rate is (§3.3). The harness in §3 recomputes all of this on the headline basis. Replace Figure `fig:core` and the §`sec:robust` numbers with the harness outputs, and state the regime explicitly in every robustness caption.

**1.2 Make the tornado the "which lever matters" figure, consistent with the CDR-rate thesis.**
The paper argues (§`sec:public`, Discussion) that the carbon case is *CDR-quantification risk, not price risk*. On the headline basis the tornado now **supports that claim directly**: the CDR-rate lever swings the intersection area by 1.52 Mha and the public envelope by 2.32 Mha, both larger than the carbon-price or delivered-cost swings. Currently the paper asserts this from the MAC algebra alone; the tornado makes it visual. Use panel (b) of `sens_scenario_tornado.png`.

**1.3 Fold "gross vs net-export" and "no penalty vs over-liming" into swept bands, not paired bounds.**
The manuscript reports two accounting bounds (gross/net) and two over-liming states (penalty/no-penalty) as separate contrasts. This reads as three different papers' worth of caveats. Recast each as a **single swept parameter** (the net-export partition λ in §2.1; the over-liming buffer band already exists) so the headline is one number with an uncertainty range, not a menu of accountings. This is cleaner and it is what the sensitivity harness expects.

**1.4 Add a short "data priorities" paragraph answering Question 6.**
The introduction poses six questions; Q6 ("which field data would most improve the model, and where") is currently answered only obliquely in the Limitations. The tornado answers it crisply: the top lever (realized CDR per tonne, δ_t) is also the least-resolved quantity, and it is set by the reactive fraction, grain size, climate factor, and pedogenic-carbonate loss. A three-sentence paragraph tying the tornado ranking to a field-measurement priority list closes the loop the introduction opens and strengthens the "economic and scientific frontier coincide" point.

**1.5 Reconcile internal inconsistencies before submission.**
- *Country count*: the manuscript says "44 SSA countries"; the model documentation says 47 and `erw-11` enumerates 45 areas. Pick one and reconcile the mask.
- *Over-liming variable*: the penalty is evaluated on the EcoCrop **pH** ceiling while the baseline yield response runs on **acidity saturation** (Al-saturation). This is defensible (over-liming is genuinely a pH phenomenon) but must be stated explicitly, per the referee-prep note, or a reviewer will read it as an error.
- *MRV framing*: the cost table cites the `$30` Levy pilot benchmark while using `$20`; keep, but make MRV a swept lever (it is, in the harness) since it enters revenue one-for-one with price.

**1.6 State the reproducibility path precisely.**
The headline numbers are generated by the analytic Python engine (`paper/analysis/erw_provisional_engine.py`); the canonical R path is `erw-11`. Before deposit, confirm `erw-11` reproduces Table 2 to the reported precision (it should, now that `erw-7` bakes the net-export deduction into `_cdr_net_tha`), and cite **one** path as canonical in the Data & Code section. The current text points only to `erw-11`; either validate that claim or add the engine.

---

## 2. Model revisions

**2.1 Replace the net-export first-order bound with a swept partition λ (highest priority).**
The current deduction, `net_export = max(gross − F·S, 0)`, assumes the acidity sink is fully paid down *before* any alkalinity exports (a sequential, first-order bound). The memo correctly notes the truth lies between gross and net. Rather than reporting two bounds, introduce a single partition parameter:

> `net_export = max(gross − λ·F·S, 0)`, λ ∈ [0, 1]

λ = 1 is today's net-export bound; λ = 0 is gross. Sweeping λ ∈ {0, 0.5, 1} turns "we report both bounds" into "durable CDR is X (range under simultaneous vs sequential weathering)". This is a one-line change in `erw-7`/`erw-9` and in the engine, and it makes the single most-scrutinized modeling choice a transparent dial.

**2.2 Port the over-liming penalty and kinetic-saturation refinements into the R pipeline.**
Both exist only as Python prototypes (`erw_overliming_prototype.py`, `erw_overliming_sensitivity.py`, `erw_kinetic_saturation.py`, `erw_optimal_rate.py`) and are not in `erw-7`/`erw-9`. For a replication package they should be optional flags in the R pipeline (`OVERLIME_PENALTY = TRUE/FALSE`, `KD = Inf/60/30/15`) so the headline and every refinement come from one codebase. The over-liming penalty is well-grounded and should probably be **on** in the headline for uniform rates; kinetic saturation should stay a reported band (K_d is uncalibrated for SSA).

**2.3 Add the pixel-specific optimal-rate analysis.**
`erw_optimal_rate.py` already computes private-, public-, and combined-optimal application rates per pixel using the two refinements. This is the natural payoff of the net-export dose-design corollary ("the agronomic optimum is CDR-minimal") and would be a strong new figure: a map of the combined-optimal dose, showing where it exceeds the lime requirement (i.e., where the carbon payment buys surplus rock). Promote it from prototype to a headline result.

**2.4 Give delivered cost a two-part structure and a defensible source set.**
Transport is currently purely linear in time (`$0.04/min/t`), with no fixed handling, no rail, no backhaul, no scale economies; and feedstock "sources" are *all* GLiM mafic outcrops, not operating quarries. Since delivered cost is a top-three lever (§3.3), two refinements are worth it: (i) a two-part haul cost (fixed loading/handling + per-km), swept; and (ii) intersecting the source mask with an active-quarry inventory, framing the current map as an upper bound on access. Both are already flagged in the referee prep.

**2.5 Sweep feedstock chemistry.**
CaO/MgO mass fractions (10%/7%) are fixed and set both δ_t (CDR per tonne) and the neutralizing value that drives F. A single representative basalt understates a real source of spatial heterogeneity. Add a chemistry band (e.g. CaO+MgO 12-22% by mass) to the sweep; it is cheap because δ_t scales linearly.

**2.6 Lower-priority, for the roadmap.**
Aggregator-take sensitivity (who captures the credit; 10-40% off the public stream) directly bears on where *smallholder* economics clear and is a natural distributional extension. Basalt supply-price feedback (rising marginal cost as deployment scales) would make `erw-supply` more realistic. Both are medium-term.

---

## 3. Systematic sensitivity plan and how to report it

The design principle: **one harness, two audiences.** A small set of named scenarios for communication; a full-factorial sweep and tornado for rigor; both from the same analytic primitives so nothing can drift out of sync. This is built and running: `paper/analysis/erw_sensitivity_harness.py` (imports the validated engine; adds MRV as an explicit lever; ~1 s to run the whole thing because every scenario is a closed-form re-evaluation of three per-pixel rasters).

### 3.1 The five levers and their bands

Each uncertain input is mapped to a coherent Low / Central / High band with a citation basis. These are the *only* knobs; everything else is held at the documented default.

| Lever | Low | Central | High | Basis |
|---|---|---|---|---|
| Carbon price (\$/tCO₂) | 100 | **150** | 250 | 2024-25 ERW credit range |
| MRV cost (\$/tCO₂) | 40 | **20** | 10 | first-of-kind (Levy 2024) → at-scale |
| Delivered cost (×) | 1.5 | **1.0** | 0.75 | haul-cost uncertainty; solar haulage at the low end |
| CDR rate δ_t (×) | 0.5 | **1.0** | 1.5 | reactive fraction / climate / pedogenic uncertainty |
| Yield uplift (×) | 0.75 | **1.0** | 1.5 | prior-dominated Bayesian fit; EcoCrop base |

### 3.2 Three reporting layers

**Layer 1 — Named scenarios (the communication headline).** Three coherent bundles: **Conservative** (every lever at its ERW-unfavorable end), **Central** (Table 2), **Optimistic** (every lever favorable). Reported as one compact table and a bar chart. This is the object to lead a talk or an investor memo with, because it answers "how good and how bad could this be?" in one glance:

| Envelope (Mha) | Conservative | **Central** | Optimistic |
|---|--:|--:|--:|
| Private | 1.36 | **4.31** | 8.73 |
| Public | 0.00 | **1.65** | 8.76 |
| Intersection | 0.00 | **1.20** | 5.44 |
| Combined | 1.64 | **6.85** | 14.24 |

The message that survives: the **private envelope never collapses to zero** and the **combined footprint is always the largest** - the qualitative story (private > public, carbon finance pivotal on the combined-only band) is robust - but the **public/carbon case is fragile**, vanishing entirely under conservative assumptions. That is the honest headline and it is more persuasive than a single point estimate.

**Layer 2 — Full-factorial sweep (the rigor backing).** All 3⁵ = 243 combinations, giving the distribution of each envelope across the whole grid and a per-pixel **robustness score** (fraction of combinations under which a pixel is doubly-justified). Reported as (i) an SI distribution table and (ii) a core-targeting map:

| Envelope | min | median | max |
|---|--:|--:|--:|
| Private | 1.4 | 4.3 | 8.7 |
| Public | 0.0 | 1.5 | 8.8 |
| Intersection | 0.0 | 1.0 | 5.4 |
| Combined | 1.6 | 7.0 | 14.2 |

The robust **core** (intersection under ≥50% of the grid) is **0.94 Mha**; the **candidate** tier (≥33%) is **1.32 Mha**. These replace the current NPV-basis core numbers and are the defensible "where to pilot" areas.

**Layer 3 — Tornado (which lever to worry about).** One-at-a-time swing around Central, on both the intersection and the public envelope:

| Lever | Intersection swing (Mha) | Public swing (Mha) |
|---|--:|--:|
| **CDR rate** | **1.52** | **2.32** |
| Carbon price | 1.25 | 2.16 |
| Delivered cost | 1.21 | 1.61 |
| Yield uplift | 0.38 | 0.00 |
| MRV cost | 0.30 | 0.57 |

### 3.3 The finding this surfaces

On the headline (equilibrium, net-export) basis, **the realized CDR rate is the single most important uncertain input** for both the doubly-justified and the carbon-only envelope - ahead of the carbon price and delivered cost. This is a reordering from the old NPV/gross tornado, where delivered cost dominated, and it is not incidental: it is the empirical counterpart of the paper's MAC argument. The economic lever and the scientific frontier are the same quantity. Yield uplift - the most-worried-about input, given the thin trial base - is the *least* influential, which is reassuring and worth stating.

### 3.4 The figure

`paper/figures/sens_scenario_tornado.png` is the two-panel communication object: (a) envelope bars under the three scenarios, (b) the intersection tornado. Paired with the robustness map (`robustness_core_headline.png`), these three panels are the entire sensitivity story and are legible to a non-technical audience. I recommend they become the paper's robustness figure and the corresponding SI table.

### 3.5 How to phrase it in the paper

Lead with **sign vs magnitude**: the *ordering* of the envelopes and the pivotal role of the combined-only band are robust across the whole grid; the *absolute hectares* are not, and depend most on the CDR rate. Report Central as the point estimate, the Conservative-Optimistic band as the range, and the tornado as the attribution. Three sentences and one figure carry it.

---

## 4. Suggested sequence

1. Wire λ (net-export partition) and the over-liming flag into `erw-7`/`erw-9`; confirm `erw-11` reproduces Table 2. *(model, ~half day)*
2. Re-run the sensitivity harness on the λ-swept engine; regenerate the robustness figure and core map. *(done for λ=1; trivial to extend)*
3. Rewrite §`sec:robust` on the headline basis using the harness outputs (draft text in `paper/draft-robustness-section.md`). *(manuscript)*
4. Add the Q6 data-priorities paragraph and reconcile the §1.5 inconsistencies. *(manuscript)*
5. Promote the optimal-rate map from prototype to a result if time allows. *(stretch)*

Files delivered with this proposal: the harness (`paper/analysis/erw_sensitivity_harness.py`), its outputs (`paper/tables/sens_*.csv`, `paper/figures/sens_scenario_tornado.png`, `paper/figures/robustness_core_headline.png`), and the draft robustness-section text (`paper/draft-robustness-section.md`).
