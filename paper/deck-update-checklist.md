# Deck update checklist — `ERW_public_private_returns_walkthrough.pptx`

*Prepared 2026-07-11; **fully revised 2026-09-01** against the Arrhenius + pH-6.0
re-run (erw-9 temperature factor now Arrhenius with Ea = 68.8 kJ/mol; triangular
pH factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×; all rasters, maps and
tables regenerated). The deck (25 slides) predates both the 2026-07 net-export
re-lead AND the 2026-09 re-run, so nearly every quantitative slide is now stale.
This is a report only — the `.pptx` has not been edited. Numbers below are the
current canonical outputs (`erw/erw-11`, `erw/erw-12`, 2026-09-01 run),
equilibrium steady state, net-export accounting.*

## The one editorial decision behind most of the changes

The manuscript **leads the carbon case on uniform-20**, because the targeted
lime-requirement dose is CDR-minimal by construction (the acidity sink is a soil
property, ~0.42 tCO₂/ha at any dose, while gross removal scales with the rock
applied). Leading the public envelope on targeted understates it **2.0×** in area
and **3.6×** in removal. Targeted is still the lead for the private and
intersection geography. Recommendation unchanged: re-lead carbon slides on
uniform-20 (option A) for consistency with the paper.

## Slide-by-slide

| # | current slide text | issue | corrected value (2026-09-01 run) |
|---|---|---|---|
| **9** | price ladder, "equilibrium, targeted": 0.35 / 1.65 / 2.51 / 4.84 / 8.76 Mha at \$100/150/250/350/500 | wrong lead + two model bases old | uniform-20: **1.40 / 3.95 / 7.00 / 23.06 / 27.98 Mha**; % treated 4.3 / 12.1 / 21.5 / 70.7 / 85.8; durable CDR 7.8 / 20.4 / 33.3 / 100.6 / 115.6 Mt. (Targeted if kept: 0.49 / 1.95 / 2.88 / 8.35 / 13.42 Mha.) Note the new steep step between \$250 and \$350. |
| **13** | "the headline is equilibrium × targeted, net-export" | half-true | headline regime is still equilibrium; targeted leads private/intersection, **uniform-20 leads the carbon case**. Also add one line: "temperature response Arrhenius (Ea = 68.8 kJ/mol); pH optimum at 6" if the deck states model mechanics |
| **17** | private envelope "4.3 Mha · \$3.5 B" | still correct | **unchanged** (4.31 Mha, \$3,496 M — the private side does not depend on the CDR surface) |
| **18** | "1.7 Mha durable public area · 9.4% of treated" | wrong lead + old basis | uniform-20: **3.95 Mha · 12.1% of treated** (targeted: 1.95 Mha / 11.1%) |
| **19** | "4.3 private / 1.7 public / 6.9 combined; 2.1 Mha combined-only" | old basis | targeted: **4.3 private / 2.0 public / 1.3 intersection / 7.6 combined; 2.7 Mha combined-only** |
| **20** | "\$446 / tCO₂ median marginal abatement cost" | unweighted + old basis | **area-weighted median \$276** (uniform-20) or **\$330** (targeted). Bonus talking point: \$276 sits at the upper edge of the published cost synthesis IQR (\$137–276, Suhrhoff et al. 2026) |
| **21** | "Three levers: 1 higher price · 2 lower delivered cost · 3 more durable CDR/t" | price and cost are **one** lever | Two structurally distinct levers: the price–cost ratio (p−m)/c and durable CDR per tonne. Doubling the CDR rate now takes the public envelope **3.95 → 22.5 Mha (~6×)** |
| **23** | "robust core ~0.8 Mha · ~0.5 M farms · ~\$0.75 B" | superseded twice | equilibrium net-export, 2026-09 run: **core 0.65 Mha / 0.38 M farms / \$0.60 B**; **candidate 1.22 Mha / 0.76 M farms / \$1.06 B**. Max robustness score 0.61. Cameroon 0.46/0.61, Guinea 0.16/0.38 (core/candidate Mha) — four-fifths of the candidate tier in two countries |
| **24** | "median MAC is \$446" | same as slide 20 | area-weighted \$276 (uniform-20) / \$330 (targeted) |

## Smaller fixes

- **Slides 1 & 4** — "44 SSA countries". Pre-existing inconsistency (44/45/47 across
  docs); pick one number and reconcile the mask before it ships.
- **Slide 10** — "F = 0.88 tCO₂ per tCaCO**₂**-eq" is a typo for tCaCO**₃**-eq. The
  value 0.88 and the mass balance are correct — and now carry citations (West &
  McBride 2005; Hamilton et al. 2007; Holden et al. 2024).
- **Slide 11** — over-liming: central reduction now **7%** at targeted (band 6–10%),
  uniform-50 central **20%** (band 3–99%). If the slide quotes "4.31 → 4.02 Mha",
  refresh from the regenerated `overliming_sensitivity.png`.
- **Slide 14** — "≈ \$3.5 B yield for ≈ \$1.74 B rock (~2:1 per cycle)" — still exact
  (private return \$3,496 M, cost \$1,743 M). **Leave alone.**
- **Slide 12** — kinetic-saturation framing unaffected. **Leave alone.**

## Consistency note if you re-lead slides on uniform-20

Slides 17 (private) and 19 (combined-only) are genuinely targeted-allocation results
and should stay targeted. Slides 9/18/20 are carbon-case slides and move to uniform-20.
The deck will then mix allocations across adjacent slides — which is exactly what the
paper does — so add a one-line allocation tag to each results slide to keep it legible.
