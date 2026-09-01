# Net-export CDR accounting: what changed and why (memo for coauthors)

> **[2026-09-01] Numbers in this memo are superseded.** The pipeline was re-run
> on the Arrhenius + pH-6.0 basis (erw-9 temperature factor now Arrhenius,
> Ea = 68.8 kJ/mol; pH-factor peak moved 5.0 → 6.0; yield sweep capped at 1.8×)
> after the ESROC-anchored citation review (`litrature/citation-review.md`).
> Current headline (equilibrium net-export, $150/$20, targeted): private 4.31 /
> public 1.95 / intersection 1.32 / combined 7.61 Mha; combined-only 2.67;
> uniform-20 public 3.95 Mha / 20.4 Mt; MAC medians $276 (uniform-20) / $330
> (targeted); core 0.65 / candidate 1.22 Mha. The memo's *reasoning* stands;
> quote numbers only from the 2026-09-01 tables in `docs/tables/`.

*Short version: our CDR figures previously credited carbon removal for alkalinity
that is actually consumed neutralizing soil acidity - the same alkalinity that
delivers the yield benefit. On acid soils that carbon is re-released, not
removed. We now deduct it. The correction is large (it cuts year-1 credited CDR
by ~80%), it is mass-balance, not a tuned parameter, and it implies that durable
CDR is mostly a steady-state (maintenance) phenomenon, not a year-1 one.*

## 1. The geochemistry in one paragraph

When basalt weathers it consumes CO2 and produces alkalinity - bicarbonate
(HCO3-) plus base cations (Ca2+, Mg2+). That alkalinity can do one of two things,
and **they draw on the same pool**:

- **Neutralize soil acidity** (displace exchangeable Al3+/H+, raise pH). This is
  the *agronomic/private* benefit. But neutralizing acidity consumes the
  bicarbonate and **releases the CO2 back to the atmosphere**
  (HCO3- + H+ -> H2O + CO2; Al3+ hydrolysis supplies the protons). So this
  portion removes **no** net carbon - it is carbon-neutral, exactly like lime.
- **Export as bicarbonate** with drainage to rivers and the ocean. This is the
  *public/CDR* benefit - durable removal for >10,000 years.

This is precisely why agricultural lime is not a CDR technology even though it
raises yields the same way. ERW is better than lime only to the extent its
alkalinity **exports beyond** what the soil's acidity consumes. On an acid soil,
the first tranche of weathering pays down the acidity debt (yield benefit, no
CDR); only the surplus removes carbon.

## 2. What the model did wrong, and the fix

The previous `erw-9` credited CDR for **all** weathered alkalinity (scaled by
climate/kinetic factors and a small pedogenic-carbonate loss keyed to aridity).
It never subtracted the alkalinity consumed neutralizing exchangeable acidity -
so on acid soils it counted the same alkalinity twice: once as a yield benefit
and once as carbon removal. That is internally inconsistent.

The fix is a mass balance:

> **net-export CDR = max( gross CDR − F × S , 0 )**

where **S** is the soil's exchangeable acidity expressed as a lime requirement
(t CaCO3/ha) - which `erw-3` already computes (Kamprath / LiTAS) - and
**F = 0.88 t CO2 per t CaCO3-eq** is the CO2 re-released per unit of acidity
neutralized. F is not tuned: it falls straight out of the feedstock's own
constants (CDR_eff = 87.6 kg CO2/t and effective neutralizing value = 99.6 kg
CaCO3-eq/t -> 87.6/99.6 = 0.88). The per-regime sink differs (Section 4).

This is the principled way to reproduce the "public returns peak at higher soil
pH than private returns" intuition (the stylized slide): it is not a kinetic
effect and should **not** be reproduced by moving the pH peak of the dissolution
factor (which would be backwards - real dissolution is faster at low pH). It is
an alkalinity-accounting effect.

## 3. The dose-design implication (important and non-obvious)

A direct corollary - and a genuinely interesting economics point: **the
agronomically optimal dose is CDR-minimal.** The lime-requirement (targeted)
dose is sized to neutralize acidity, so essentially all of its alkalinity is
consumed on the agronomic service and almost none exports. To remove carbon you
must apply **beyond** the acidity demand, so the surplus alkalinity leaches.

So the two benefit streams do not merely differ in space - they pull the
application rate in **opposite directions**. Maximizing private return points to
the lime requirement; maximizing CDR points to over-application past it (extra
rock that delivers carbon but no extra yield). The "stacked" case therefore
requires a dose above the agronomic optimum, with the carbon payment compensating
for the surplus rock. This reframes the uniform-rate scenarios (10/20/50 t/ha):
their higher CDR is not a modeling artifact - it is real surplus alkalinity
exporting, bought at the cost of rock the agronomy doesn't need. A natural new
scenario is a **CDR-targeted rate = lime requirement + an export surplus**.

## 4. The regime implication: durable CDR is a steady-state phenomenon

The acidity sink depends on the regime:

- **Year-1 / NPV:** the sink is the soil's *standing* exchangeable acidity (large).
  The first application largely pays it down -> little export -> CDR collapses.
- **Equilibrium / maintenance:** the standing acidity has already been remediated;
  the per-period sink is only the *annual re-acidification* (small). The
  maintenance dose mostly exports -> CDR survives.

The data show exactly this:

| Regime | Allocation | Gross CDR (Mt) | Net-export CDR (Mt) | Retained |
|---|---|--:|--:|--:|
| NPV | Targeted | 81.1 | 19.0 | 23% |
| NPV | Uniform 20 | 101.4 | 19.2 | 19% |
| Equilibrium | Targeted | 26.4 | 19.4 | 73% |
| Equilibrium | Uniform 20 | 101.4 | 88.4 | 87% |

So the headline carbon story should be told on the **equilibrium regime**, not
year-1/NPV. Year-1 ERW on acid soils is, to first order, *liming with a small
carbon tail*.

## 5. Consequences for the envelopes (NPV, targeted)

| Quantity | Gross (old) | Net-export (new) |
|---|--:|--:|
| Public-sufficient area | 1.75 Mha | **0.14 Mha** |
| Intersection area | 0.97 Mha | **0.14 Mha** |
| Median marginal abatement cost | \$406/tCO2 | **\$1,254/tCO2** |

Under proper accounting the NPV public/carbon envelope nearly disappears (the
typology map goes almost entirely "private-only"), while the **equilibrium**
public envelope remains substantial (targeted public 2.23 -> 1.65 Mha;
intersection 1.46 -> 1.20 Mha). The private (yield) envelope is unaffected - it
never depended on the carbon accounting.

## 6. The one caveat to state plainly

This is a **first-order bound**. It assumes the acidity sink is filled before any
alkalinity exports (sequential). In reality weathering, neutralization, and
leaching happen at once and over years; some alkalinity exports even on acid
soils (especially under heavy leaching), and re-acidification keeps regenerating
the sink. So the truth lies **between** the old "gross" (all exports) and this new
"net" (sink filled first). We will present both as bounds and lead the carbon
case with the equilibrium regime, where the two converge.

## 7. What changes in the paper

- New methods subsection deriving the net-export deduction.
- Carbon/public results led on the equilibrium regime; year-1/NPV public shown as
  an upper-bound contrast.
- Updated CDR totals, public-envelope areas, and MAC.
- Revised the slides-4/5 schematic to the data-grounded version (private peaks on
  acid soils; public peaks on mildly acid soils where alkalinity exports).
- `erw-9` updated to compute net-export CDR (per-regime sink).
