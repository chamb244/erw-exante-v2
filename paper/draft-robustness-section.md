# Draft manuscript edits: robustness section + supporting text

> **[2026-09-01] Numbers in this memo are superseded.** The pipeline was re-run
> on the Arrhenius + pH-6.0 basis (erw-9 temperature factor now Arrhenius,
> Ea = 68.8 kJ/mol; pH-factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×)
> after the ESROC-anchored citation review (`litrature/citation-review.md`).
> Current headline (equilibrium net-export, $150/$20, targeted): private 4.31 /
> public 1.95 / intersection 1.32 / combined 7.61 Mha; combined-only 2.67;
> uniform-20 public 3.95 Mha / 20.4 Mt; MAC medians $276 (uniform-20) / $330
> (targeted); core 0.65 / candidate 1.22 Mha. The memo's *reasoning* stands;
> quote numbers only from the 2026-09-01 tables in `docs/tables/`.

*Status: **APPLIED** to `paper/manuscript.tex` (2026-07-10). Kept as a record of what
changed and why. Numbers are from `erw/erw-11-private-public-envelopes.R` §2–3, computed on
the headline basis (equilibrium steady state, net-export accounting, targeted allocation) so
the robustness analysis matches the regime the carbon case is led on.*

*Supersedes an earlier version of this file that quoted `erw_sensitivity_harness.py`
(core 0.94 Mha, candidate 1.32 Mha; CDR-rate swing 1.52 Mha). Those numbers came from a
243-point grid that (i) scaled the CDR-rate multiplier on already-deducted net removal
rather than gross, (ii) omitted λ, and (iii) treated carbon price, MRV and delivered cost
as three independent axes when they are not. They should not be cited.*

---

## What was wrong

The paper led the carbon case on **equilibrium, net-export** (correctly), but §`sec:robust`,
the tornado, and the core-targeting map were computed on the **NPV, gross** grid
(`core_priority_npv.png`). That is a regime mismatch a careful referee would catch. It also
inverted the lever ranking: on the NPV/gross basis delivered cost dominated; on the headline
basis it does not, once you notice that cost is not a separate mechanism.

## The four effective knobs

Both envelope tests are homogeneous of degree zero in the delivered cost. Divide through by
the cost multiplier `c`:

```
private :  AGRO * (y/c)                    > BAS
public  :  cdr_net(r, λ) * ((p − m)/c)     > BAS
```

So the intersection depends on the five economic parameters only through **four** effective
knobs: `y/c`, `(p−m)/c`, `r`, `λ`. Verified exactly — `(y,c,p)` = `(1,1,150)`, `(2,2,280)`,
`(0.5,0.5,85)` and `(1.5,1.5,215)` all give 1.2002 Mha.

The sweep is therefore a `5 × 4 × 3 × 3 = 180`-point grid over those four, not a
five-dimensional grid with partly redundant axes.

## Results on the headline basis

Baseline intersection **1.20 Mha**. No pixel exceeds a robustness score of **0.58** — the
doubly-justified case is inherently parameter-sensitive.

| tier | area (Mha) | farms (M) | crop value ($M) | CDR (Mt) |
|---|--:|--:|--:|--:|
| core (≥50% of grid) | 0.59 | 0.35 | 544 | 2.51 |
| candidate (≥33%) | 1.14 | 0.70 | 988 | 3.73 |

Geography (Mha, core / candidate): Cameroon 0.43 / 0.57, Guinea 0.15 / 0.38, Ethiopia
0.002 / 0.09, Tanzania 0.011 / 0.03, Sierra Leone 0 / 0.03, DRC 0 / 0.02. Two countries hold
two-thirds of the candidate tier. Madagascar, named in the earlier draft, contributes
0.004 Mha — drop it from the prose.

## Tornado (one-at-a-time, around Central)

| knob | swing (Mha) | acts on |
|---|--:|---|
| CDR rate `r` (×0.5–1.5) | **1.61** | public |
| net-price/cost ratio `(p−m)/c` (30–230) | **1.59** | public |
| yield/cost ratio `y/c` (×0.5–2.0) | 0.76 | private |
| net-export partition `λ` (0–1) | 0.26 | public |
| *[delivered cost `c` (×0.5–2.0)]* | *2.36* | *both* |
| — its public channel only | 1.66 | public |
| — its private channel only | 0.76 | private |

Two readings.

**The CDR rate and the price–cost ratio are effectively tied on the intersection** (1.61 vs
1.59). The CDR rate's clear lead shows up in the carbon-only envelope (§`sec:public`), not
here, because the intersection is jointly constrained by an agronomic test that the CDR rate
does not enter. The paper should not claim a decisive CDR-rate lead on the intersection.

**Delivered cost is not the dominant lever; it is the only lever pulled twice.** Its raw
2.36 Mha swing decomposes into a public channel (1.66 Mha, holding `y/c` fixed) and a private
channel (0.76 Mha, holding `(p−m)/c` fixed). That 0.76 is *exactly* the yield swing — as it
must be, since yield moves `y/c` and nothing else. The earlier finding that "delivered cost
is by far the dominant lever, larger than carbon price, CDR rate and yield combined"
(`envelope-analysis-memo.md` §4) was an aggregation artifact.

The reassuring corollaries survive: the yield benefit — the most uncertain input, given the
thin field-trial base — is among the least influential, and λ, the most-scrutinized modeling
choice, is the least influential of all.

## What was applied to the manuscript

1. §`sec:robust` rewritten on the headline basis, with the four-knob derivation, the new
   core/candidate numbers, and the cost decomposition stated explicitly.
2. `fig:core` replaced: `core_priority_npv.png` → two panels,
   `robustness_intersection_eqnx.png` + `core_priority_eqnx.png`.
3. Methods robustness paragraph: names the 180-point four-knob grid, states that the carbon-
   only envelope reduces to two knobs, and that `r` scales gross removal.
4. Discussion, "CDR-quantification risk not price risk": the claim now carries its margin —
   `δ_t` leads on the carbon-only envelope (4.9 vs 4.6 Mha) and ties on the intersection.
   What distinguishes it is the *shape* of its response (super-linearity), not its local
   slope.

`tab:regimes` is unchanged and still reports NPV alongside equilibrium — that table is
*about* the regime contrast, and its numbers (equilibrium targeted public 2.23 gross → 1.65
net; CDR 26 → 19 Mt) reproduce exactly.

## Still open

- `erw_sensitivity_harness.py` continues to scale `r` on net removal and to treat the three
  price/cost levers as independent. It now carries a comment saying so and pointing at
  `erw-12`. Its named-scenario table (Conservative / Central / Optimistic) is unaffected by
  the ordering issue at `r = 0.5` and `r = 1.5` only because both floor and ceiling happen to
  fall where the compression is small; do not extend it to larger `r` without fixing it.
- The Q6 "where field data would most improve the model" paragraph promised by the abstract
  is still not in the Discussion.
