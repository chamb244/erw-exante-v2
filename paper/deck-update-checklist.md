# Deck update checklist — `ERW_public_private_returns_walkthrough.pptx`

*Prepared 2026-07-11. The deck (25 slides) predates the net-export re-lead, the
`uniform-20` carbon lead, the CDR-rate ordering fix, and the robustness recompute. It
now disagrees with `manuscript.tex` on seven slides. This is a report only — the
`.pptx` has not been edited. Numbers below are the current canonical outputs
(`erw/erw-11`, `erw/erw-12`, `erw_provisional_engine.py`), equilibrium steady state,
net-export accounting.*

## The one editorial decision behind most of the changes

The manuscript now **leads the carbon case on uniform-20**, because the targeted
lime-requirement dose is CDR-minimal by construction (the acidity sink is a soil
property, near-constant across doses, while gross removal scales with the rock
applied). Leading the public envelope on targeted understates it ~1.9× in area and
~3.1× in removal. Targeted is still the lead for the private and intersection
geography.

Every carbon slide below therefore has **two** possible fixes: (A) re-lead it on
uniform-20 to match the paper, or (B) keep it on targeted but correct the stale
values and add a line noting the public case is larger under uniform doses. Pick one
convention and apply it consistently across slides 9, 18, 20, 21, 24. I recommend (A)
for consistency with the paper the deck accompanies.

## Slide-by-slide

| # | current slide text | issue | corrected value |
|---|---|---|---|
| **9** | price ladder, "equilibrium, targeted": 0.35 / 1.65 / 2.51 / 4.84 / 8.76 Mha at \$100/150/250/350/500 | wrong lead + wrong basis | uniform-20: **0.63 / 3.16 / 5.23 / 13.25 / 19.26 Mha**; % treated 1.9 / 9.7 / 16.1 / 40.7 / 59.1; durable CDR 3.5 / 15.1 / 22.9 / 54.1 / 71.1 Mt |
| **13** | "the headline is equilibrium × targeted, net-export" | half-true now | headline regime is still equilibrium; targeted leads private/intersection, **uniform-20 leads the carbon case**. Reword to "equilibrium, net-export; targeted for the agronomic case, uniform-20 for the carbon case" |
| **18** | "1.7 Mha durable public area · 9.4% of treated" | wrong lead | uniform-20: **3.2 Mha · 9.7% of treated** (targeted 1.65 Mha / 9.4% if kept on targeted) |
| **20** | "\$446 / tCO₂ median marginal abatement cost" | unweighted median, mislabeled | **area-weighted median \$372** (uniform-20) or **\$426** (targeted). \$446 is the *unweighted* pixel median — the manuscript no longer uses it |
| **21** | "Three levers: 1 higher price · 2 lower delivered cost · 3 more durable CDR/t" | price and cost are **one** lever | The public test is homogeneous of degree zero in price and cost — they enter only through the ratio (p−m)/c. There are **two** structurally distinct levers: the price–cost ratio and durable CDR per tonne. Recast slide as two, or keep three but add "price and delivered cost act through a single ratio (p−m)/c" |
| **23** | "robust core ~0.8 Mha · ~0.5 M farms · ~\$0.75 B" | NPV-basis, superseded | equilibrium net-export: **core 0.59 Mha / 0.35 M farms / \$0.54 B**; **candidate 1.14 Mha / 0.70 M farms / \$0.99 B**. No pixel exceeds a 0.58 robustness score |
| **24** | "median MAC is \$446" | same as slide 20 | area-weighted \$372 (uniform-20) / \$426 (targeted) |

## Smaller fixes

- **Slides 1 & 4** — "44 SSA countries". This is a pre-existing inconsistency (also
  in the manuscript abstract): `erw-11` enumerates 45 areas, the model docs say 47.
  Not caused by this round of edits, but pick one number and reconcile the mask before
  it ships. Flagged in `PROPOSAL-revisions-sensitivity.md` §1.5.
- **Slide 10** — "F = 0.88 tCO₂ per tCaCO**₂**-eq" is a typo for tCaCO**₃**-eq
  (calcium *carbonate*). The value 0.88 and the mass balance are correct.

## What is still correct — leave alone

- **Slide 14** — "≈ \$3.5 B yield for ≈ \$1.74 B rock (~2:1 per cycle)" matches the
  engine exactly (targeted private return \$3,496 M, cost \$1,743 M).
- **Slide 11** — over-liming "4.31 → 4.02 Mha, −7%" matches `overliming_sensitivity.csv`.
- **Slide 17** — private envelope "4.3 Mha · \$3.5 B" is current.
- **Slide 19** — "4.3 private / 1.7 public / 6.9 combined; 2.1 Mha combined-only" is
  the targeted decomposition and is current. (If slide 18 is re-led on uniform-20,
  keep slide 19 on targeted — the combined-only story is a targeted-allocation result;
  just make sure the two slides don't read as the same allocation.)
- **Slide 12** — kinetic-saturation framing ("what binds is MAC > price, not
  kinetics") is unaffected.

## Consistency note if you re-lead slides on uniform-20

Slides 17 (private) and 19 (combined-only) are genuinely targeted-allocation results
and should stay targeted. Slides 9/18/20 are carbon-case slides and move to uniform-20.
The deck will then mix allocations across adjacent slides — which is exactly what the
paper does — so add a one-line allocation tag to each results slide to keep it legible.
