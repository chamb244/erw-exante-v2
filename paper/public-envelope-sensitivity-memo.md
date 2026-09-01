# Sensitivity of the public (carbon-only) return envelope

> **[2026-09-01] Numbers in this memo are superseded.** The pipeline was re-run
> on the Arrhenius + pH-6.0 basis (erw-9 temperature factor now Arrhenius,
> Ea = 68.8 kJ/mol; pH-factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×)
> after the ESROC-anchored citation review (`litrature/citation-review.md`).
> Current headline (equilibrium net-export, $150/$20, targeted): private 4.31 /
> public 1.95 / intersection 1.32 / combined 7.61 Mha; combined-only 2.67;
> uniform-20 public 3.95 Mha / 20.4 Mt; MAC medians $276 (uniform-20) / $330
> (targeted); core 0.65 / candidate 1.22 Mha. The memo's *reasoning* stands;
> quote numbers only from the 2026-09-01 tables in `docs/tables/`.

*Companion to `paper/envelope-analysis-memo.md` and `paper/PROPOSAL-revisions-sensitivity.md`.
Canonical code: `erw/erw-12-public-envelope-sensitivity.R`. Basis: equilibrium regime,
net-export accounting, $150/tCO₂, MRV $20/tCO₂. The carbon case is led on **uniform-20**;
targeted values are given for contrast. All numbers regenerate in ~2 min from the
`economics_erw` rasters.*

## 0. The accounting discrepancy — resolved

The committed `economics_erw` rasters used to predate commit `16b6321`, which wired the
net-export deduction into `erw-7`. Band 9 `_cdr_net_tha` carried no `F·S` term, so
`erw-11` (which reads band 9 directly) silently reported **gross** numbers — public
2.23 Mha — while `erw_provisional_engine.py` deducted once and reproduced the published
headline. Two "canonical" paths, two different answers.

**Resolution.** `erw-7` was re-run, so band 9 now genuinely carries net-export. The
engine's `apply_netexport()` helper — which would have double-deducted against the new
rasters — has been removed. All three paths now agree:

| path | targeted public | uniform-20 public |
|---|--:|--:|
| `erw-11` | 1.65 Mha | 3.16 Mha |
| `erw_provisional_engine.py` | 1.65 Mha | 3.16 Mha |
| `erw-12` | 1.65 Mha | 3.16 Mha |

`erw-12` §0 asserts which accounting the on-disk rasters carry, every run. It reads band 8
`_cdr_gross_tha` — gross under either convention — and applies the deduction itself with λ
exposed, so its numbers are invariant to whether `erw-7` has been re-run. That invariance
was tested: re-running `erw-7` flipped the §0 verdict from "NO net-export" to "NET-EXPORT"
and left every `erw-12` output byte-identical.

## 1. The public envelope has two knobs, not five

Public-sufficiency is `cdr_net(r,λ)·(p − m) > BAS·c`. Since `cdr_net` depends on neither
price nor cost, the envelope depends on carbon price `p`, MRV cost `m`, and the
delivered-cost multiplier `c` **only through the single ratio `(p − m)/c`**. Verified over
seven distinct `(p,m,c)` triples sharing ratio 130 — including `($400, $10, ×3.0)` and
`($85, $20, ×0.5)` — all giving 3.1631 Mha, spread exactly 0.

The five-lever tornado in `erw_sensitivity_harness.py` therefore treats one knob as three.
Its public-envelope ranking (carbon > delivered cost > MRV) is fully explained by how wide
each band happens to be in `(p−m)/c`. It measures the bands, not the model.

Band-free local elasticities at Central:

| quantity | uniform-20 | targeted |
|---|--:|--:|
| `d lnA / d ln[(p−m)/c]` | +1.05 | +1.33 |
| `d lnA / d ln[CDR rate r]` | **+1.19** | **+1.72** |
| `d lnA / d λ` | −0.14 | −0.39 |

## 2. The CDR-rate lever is systematically compressed

The harness applies its CDR-rate multiplier to the *already-deducted* net CDR. Physically
`r` multiplies **gross** CDR (reactive fraction × grain size × climate factor × exported
fraction), while the acidity sink `F·S` and the LCA term are fixed subtrahends:

```
cdr_net(r, λ) = max( max(r·GROSS − λ·F·S, 0) − LCA , 0 )
```

The `max(·,0)` over a fixed subtrahend makes `cdr_net` super-linear in `r`, so scaling net
compresses the lever on both sides (uniform-20):

| r | correct (scales gross) | harness (scales net) |
|--:|--:|--:|
| 0.75 | 1.54 Mha | 1.75 Mha |
| 1.00 | 3.16 | 3.16 |
| 1.50 | 4.93 | 4.59 |
| 2.00 | **12.56** | **5.99** |
| 3.00 | 22.99 | 16.07 |

Two independent derivations agree, which is the check worth trusting: the elasticity ratio
`e_r / e_ratio = 1.14` equals the median `GROSS/cdr_net` amplifier at the *marginal* pixels
(1.16). The all-pixel mean amplifier is the wrong weighting — pixels far inside the
envelope have cheap CDR and a small amplifier.

`erw-11`'s CDR-rate sweep has been corrected to scale gross; it now reports 12.56 Mha at
`r=2` rather than 5.99. The harness still scales net, and carries an explicit comment
saying so and pointing at `erw-12`.

## 3. λ is the smallest structural lever, not the largest worry

The net-export partition — `net_export = max(gross − λ·F·S, 0)`, with λ=1 the sequential
bound and λ=0 gross — is the single most-scrutinised modelling choice
(`netexport-cdr-memo.md` §6). It moves the public envelope only:

| λ | uniform-20 Mha | uniform-20 Mt | median MAC | targeted Mha |
|--:|--:|--:|--:|--:|
| 0.00 (gross) | 3.51 | 17.79 | $333 | 2.23 |
| 0.50 | 3.34 | 16.42 | $352 | 1.97 |
| 1.00 (sequential) | 3.16 | 15.11 | $372 | 1.65 |

This supports PROPOSAL §2.1: report **3.34 Mha [3.16, 3.51]** as one number with a band,
rather than two competing accountings. The choice that attracts the most referee attention
is not the one that drives the answer.

## 4. Why the carbon case is led on uniform-20

The acidity sink `F·S` is a soil property, near-constant across allocation rules, while
gross CDR scales with dose. So the lime-requirement dose is **CDR-minimal by construction** —
the quantitative form of the dose-design corollary in `netexport-cdr-memo.md` §3:

| allocation | gross tCO₂/ha | F·S | cdr_net | public Mha | public Mt | median MAC |
|---|--:|--:|--:|--:|--:|--:|
| targeted | 1.67 | 0.43 | 0.88 | 1.65 | 4.85 | $426 |
| uniform_20 | 3.94 | 0.42 | 2.50 | 3.16 | 15.11 | $372 |
| uniform_50 | 9.85 | 0.42 | 6.82 | 3.38 | 41.83 | $348 |

Leading the carbon case on `targeted` understates the public envelope by 1.9× in area and
3.1× in tonnage. `targeted` remains the lead for the private envelope and the targeting
geography.

**The honest cost of this switch.** Re-leading on uniform-20 *weakens* the paper's
"CDR rate dominates" claim, and this must be stated. uniform-20's sink is a smaller share
of its gross removal (0.42/3.94 = 11%, versus 0.43/1.67 = 26% at targeted), so the marginal
amplifier falls from 1.33 to 1.16 and the CDR-rate elasticity from 1.72 to 1.19. In the
one-at-a-time tornado the CDR rate (4.93 Mha swing) now only narrowly exceeds the
price–cost ratio (4.60 Mha), where on targeted it was 2.56 vs 2.16. And at the ±33% step
the delivered-cost lever is *marginally the stronger* of the two. The CDR-rate dominance
survives, but as a property of large moves in δ_t rather than of local slopes.

Note also that the treated-cropland denominator is allocation-specific: 17.6 Mha
(acid-eligible) for targeted, 32.6 Mha (all cropland the 23 SPAM crops occupy) for
uniform-20. Percentage shares are comparable across prices within an allocation, never
across allocations. At $150 the *share* that clears is nearly identical (9.7% vs 9.4%) —
uniform-20 wins on the carbon case by treating more land and exporting more of each tonne's
alkalinity, not by clearing a larger fraction of what it treats.

## 5. What changed in the manuscript

1. §`sec:public` re-led on uniform-20, with the dose-design reason stated up front.
2. `tab:priceladder` recomputed on uniform-20 (targeted in brackets), with the
   allocation-specific denominator flagged.
3. `fig:mac` and `fig:cdrrate` regenerated on the headline equilibrium net-export basis
   (they were previously on the gross-NPV basis — PROPOSAL §1.1).
4. A paragraph added deriving the `(p−m)/c` collapse, and the gross-scaling requirement.
5. The abstract's median MAC corrected: `$446` was the *unweighted* pixel median, reported
   as area-weighted. Area-weighted is `$426` (targeted), `$372` (uniform-20).
6. Methods robustness paragraph now names λ as a swept lever and cites `erw-12`.

7. §`sec:robust` and `fig:core` recomputed on the headline equilibrium net-export basis,
   closing the regime mismatch of PROPOSAL §1.1. See `draft-robustness-section.md`.

The intersection collapses too, but to **four** knobs rather than two, since the private test
survives: `y/c`, `(p−m)/c`, `r`, `λ`. Delivered cost is the only parameter that moves two of
them, which is why earlier drafts read it as the dominant lever — its 2.36 Mha swing is a
1.66 Mha public channel plus a 0.76 Mha private channel, and that 0.76 is exactly the yield
swing. Core tier 0.59 Mha, candidate 1.14 Mha; no pixel exceeds a robustness score of 0.58.

## 6. Caveats

- The deduction is applied to area-weighted primitives, not per-crop then averaged. Because
  `max(·,0)` is nonlinear these differ slightly. `erw-11` and the engine make the same
  approximation, so the comparison is like-for-like.
- `erw-7` clamps `max(gross − F·S, 0)` *before* subtracting LCA; the old engine subtracted
  both and clamped once. The two differ only where `gross < F·S`, and by under 0.05 Mha on
  every envelope (visible as Optimistic public 8.80 vs the previously published 8.76).
- The delivered-cost multiplier `c` scales cost but not the transport **emissions** term in
  LCA. Decoupling cost from emissions is what makes the `(p−m)/c` collapse exact. A cost
  lever that also moved haul distance would break it.
- `erw-11` prints an *unweighted* median MAC (401 at uniform-20); `erw-12` reports the
  area-weighted one (372). Both are correct, they answer different questions.
- Over-liming (§`sec:overlime`) erodes the private return at high uniform doses (~5% at
  uniform-20) but leaves the public envelope untouched, since public-sufficiency does not
  depend on yield. It is therefore not an argument against the uniform-20 carbon lead.
- Elasticities are local to Central and computed by central differences in log space
  (`h = 0.02`). They rank levers; they do not extrapolate.
