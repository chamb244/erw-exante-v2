# Sensitivity of the public (carbon-only) return envelope

*Companion to `paper/envelope-analysis-memo.md` and `paper/PROPOSAL-revisions-sensitivity.md`.
Canonical code: `erw/erw-12-public-envelope-sensitivity.R`. Basis: equilibrium regime,
targeted allocation, net-export accounting, $150/tCO₂, MRV $20/tCO₂ — the manuscript
headline. All numbers regenerate in ~1 min from the committed `economics_erw` rasters.*

## 0. An accounting discrepancy to resolve first

The committed `data/economics_erw/**` rasters were written **before** commit `16b6321`
wired the net-export deduction into `erw-7`. `erw-12` §0 verifies this directly: band 9
`_cdr_net_tha` equals `max(gross − LCA, 0)` to within 9e-7 tCO₂/ha, with no `F·S` term.
The `cdr_yield_*_netexport.tif` outputs of `erw-9` do not exist on disk either.

Two consequences, both currently live:

| path | deduction applied | targeted public envelope |
|---|---|--:|
| `erw/erw-11-private-public-envelopes.R` | none (reads band 9 directly) | **2.23 Mha** (gross) |
| `paper/analysis/erw_provisional_engine.py` (`apply_netexport`) | once | **1.65 Mha** (net-export) |

`erw-11` is cited as the canonical path but silently reports the *gross* numbers — the
pre-correction values that `paper/netexport-cdr-memo.md` §5 tabulates (public 2.23,
intersection 1.46). The Python engine reproduces the published headline
(private 4.31 / public 1.65 / intersection 1.20 / combined 6.85 Mha) — but only because
it deducts once from rasters that were never deducted from.

**The trap.** `PROPOSAL-revisions-sensitivity.md` §4 step 1 instructs re-running `erw-7`
and confirming `erw-11` reproduces Table 2. Doing so makes `erw-11` correct and makes the
engine **double-deduct**. Whoever re-runs `erw-7` must delete `apply_netexport` from the
engine in the same change.

`erw-12` sidesteps this entirely: it reads band 8 `_cdr_gross_tha` — gross under both the
old and the re-run `erw-7` — and applies the deduction itself, with λ exposed as a dial.

## 1. The public envelope has two knobs, not five

Public-sufficiency is `cdr_net(r,λ)·(p − m) > BAS·c`. Since `cdr_net` depends on neither
price nor cost, the envelope depends on carbon price `p`, MRV cost `m`, and the
delivered-cost multiplier `c` **only through the single ratio `(p − m)/c`**. Verified over
seven distinct `(p,m,c)` triples sharing ratio 130 — including `($400, $10, ×3.0)` and
`($85, $20, ×0.5)` — all giving 1.6508 Mha, spread exactly 0.

The five-lever tornado in `erw_sensitivity_harness.py` therefore treats one knob as three.
Its public-envelope ranking (carbon 2.16 > delivered cost 1.61 > MRV 0.57 Mha) is fully
explained by how wide each band happens to be in `(p−m)/c` — spans of 2.9×, 2.0× and 1.3×
respectively. It measures the bands, not the model.

Band-free local elasticities at Central give the honest ranking:

| quantity | value |
|---|--:|
| `d lnA / d ln[(p−m)/c]` | +1.33 |
| `d lnA / d ln[CDR rate r]` | **+1.72** |
| `d lnA / d λ` | −0.39 |

## 2. The CDR-rate lever is systematically compressed

The harness applies its CDR-rate multiplier to the *already-deducted* net CDR. Physically
`r` multiplies **gross** CDR (reactive fraction × grain size × climate factor × exported
fraction), while the acidity sink `F·S` and the LCA term are fixed subtrahends:

```
cdr_net(r, λ) = max( max(r·GROSS − λ·F·S, 0) − LCA , 0 )
```

The `max(·,0)` over a fixed subtrahend makes `cdr_net` super-linear in `r`, so scaling net
compresses the lever on both sides:

| r | correct (scales gross) | harness (scales net) |
|--:|--:|--:|
| 0.75 | 0.74 Mha | 0.91 Mha |
| 1.00 | 1.65 | 1.65 |
| 1.50 | 2.56 | 2.32 |
| 2.00 | **5.90** | **2.68** |
| 3.00 | 12.33 | 6.98 |

At a 2× CDR rate — the exact lever `envelope-analysis-memo.md` §5 highlights — the public
envelope is 5.90 Mha, not 2.68. That memo's "+181%" is really **+257%**.

Within the harness's ±50% band the distortion is modest (both floor at zero at `r = 0.5`),
so the published tornado is not badly wrong. The damage is to the large-`r` claims the
investor argument leans on.

Two independent derivations agree, which is the check worth trusting: the elasticity ratio
`e_r / e_ratio = 1.29` equals the median `GROSS/cdr_net` amplifier at the *marginal* pixels
(1.33). The all-pixel mean amplifier (1.91) is the wrong weighting — pixels far inside the
envelope have cheap CDR and a small amplifier.

## 3. λ is the smallest structural lever, not the largest worry

The net-export partition — `net_export = max(gross − λ·F·S, 0)`, with λ=1 the sequential
bound and λ=0 gross — is the single most-scrutinised modelling choice
(`netexport-cdr-memo.md` §6). It moves the public envelope only:

| λ | public Mha | public Mt | median MAC |
|--:|--:|--:|--:|
| 0.00 (gross) | 2.23 | 6.33 | $305 |
| 0.50 | 1.97 | 5.59 | $361 |
| 1.00 (sequential) | 1.65 | 4.85 | $426 |

This supports PROPOSAL §2.1: report **1.97 Mha [1.65, 2.23]** as one number with a band,
rather than two competing accountings. The choice that attracts the most referee attention
is not the one that drives the answer.

## 4. Leading on `targeted` understates the carbon case ~2×

The acidity sink `F·S` is a soil property, near-constant across allocation rules, while
gross CDR scales with dose. So the lime-requirement dose is **CDR-minimal by construction** —
the quantitative form of the dose-design corollary in `netexport-cdr-memo.md` §3:

| allocation | gross tCO₂/ha | F·S | cdr_net | public Mha | public Mt | median MAC |
|---|--:|--:|--:|--:|--:|--:|
| targeted | 1.67 | 0.43 | 0.88 | 1.65 | 4.85 | $426 |
| uniform_20 | 3.94 | 0.42 | 2.50 | 3.16 | 15.11 | $372 |
| uniform_50 | 9.85 | 0.42 | 6.82 | 3.38 | 41.83 | $348 |

Leading the carbon case on `targeted` understates the public envelope by 1.9× in area and
3.1× in tonnage. This is the open decision flagged in the engine header
(*"public/VCM case is much larger at uniform-50, so targeted may understate it"*),
now quantified under correct accounting.

## 5. What this implies for the manuscript

1. **Resolve the accounting path** before anything else (§0). One canonical implementation.
2. **Collapse the tornado.** Report `(p−m)/c` as one lever. The current three-lever
   presentation invites a referee to notice they are algebraically the same knob.
3. **Fix the CDR-rate ordering** in the harness. It strengthens the paper's own thesis —
   the CDR rate becomes *more* dominant, not less.
4. **Swap the two accounting bounds for a λ band** (§3), and state that λ is a minor lever.
5. **Decide the headline allocation** (§4) on stated grounds, since it moves the public
   envelope by ~2×.

The paper's central claim — *ERW's carbon case is CDR-quantification risk, not price risk* —
survives all of this, and is in fact better supported once the price/cost levers are
collapsed and the CDR-rate lever is scaled correctly. But it currently reaches that
conclusion partly by accident.

## 6. Caveats

- The deduction is applied to area-weighted primitives, not per-crop then averaged. Because
  `max(·,0)` is nonlinear these differ slightly. `erw-11` and the Python engine make the
  same approximation, so the comparison is like-for-like.
- The delivered-cost multiplier `c` scales cost but not the transport **emissions** term in
  LCA. Decoupling cost from emissions is a modelling choice, and it is what makes the
  `(p−m)/c` collapse exact. A cost lever that also moved haul distance would break it.
- Panel (a) of the figure has a sharp step near `r ≈ 1.8` where a cluster of pixels crosses
  the threshold together. Not investigated; it does not affect any reported number.
- Elasticities are local to Central and computed by central differences in log space
  (`h = 0.02`). They rank levers; they do not extrapolate.
