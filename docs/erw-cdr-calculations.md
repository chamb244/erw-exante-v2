# Carbon Dioxide Removal in the Ex-Ante ERW Pipeline

## A technical derivation of the per-pixel CDR calculation, with sources for every mechanism and constant

This report documents exactly how the pipeline turns a tonne of applied basalt
into a quantity of durably removed carbon dioxide. It walks the full chain
implemented in `erw/erw-3-basalt-requirements.R` (feedstock chemistry and the
per-tonne potential) and `erw/erw-9-cdr-yield.R` (the spatial climate, soil, and
accounting terms), states each governing equation, gives the numerical default,
and cites the peer-reviewed source that grounds each assumption and mechanism.

Every bracketed reference `[n]` resolves in the **References** section. Where a
value is a modelling choice rather than a measured constant, this is stated
plainly and the choice is defended against the cited range.

---

## 1. Overview — the calculation as one chain

Durable CDR (tonnes CO₂ per hectare) at a cropland pixel is built in five
conceptual moves, then corrected by a sixth:

1. **Stoichiometric ceiling** — the maximum CO₂ a tonne of basalt could remove,
   fixed by its Ca and Mg oxide content (pure chemistry).
2. **Reactive fraction** — only a fraction of that ceiling actually weathers on a
   decadal horizon.
3. **Grain-size factor** — finer grinding exposes more surface area and speeds
   reaction.
4. **Climate & soil-pH factor** — temperature, moisture, and soil acidity rescale
   the reaction rate relative to a temperate reference site.
5. **Pedogenic-carbonate deduction** — in dry soils some alkalinity re-precipitates
   as carbonate locally, re-releasing CO₂.
6. **Net-export correction** — alkalinity consumed neutralizing the soil's own
   exchangeable acidity re-releases its CO₂ (as agricultural lime does) and is
   *not* durable removal; only alkalinity exported beyond the acidity demand counts.

Assembled, the per-hectare durable removal is

$$
\mathrm{CDR}_{\text{net}}(x)
= \max\!\Big(\underbrace{D(x)\cdot \tfrac{1}{1000}\,\Phi(x)\,C_{\max}\,(1-p_{\text{ped}}(x))}_{\text{gross removal}}
\;-\; \underbrace{F\cdot S(x)}_{\text{acidity re-release}}\;,\; 0\Big)
$$

where $D$ is the basalt application rate (t ha⁻¹), $C_{\max}$ the stoichiometric
ceiling (kg CO₂ t⁻¹), $\Phi$ the effective reactive fraction (grain × climate ×
pH), $p_{\text{ped}}$ the pedogenic-carbonate fraction, $F$ the CO₂ re-released
per tonne of acidity neutralized, and $S$ the soil's acidity expressed as a lime
requirement (t CaCO₃-eq ha⁻¹). Each term is derived below.

### Symbols and default values

| Symbol | Meaning | Default | Units | Set in |
|---|---|---|---|---|
| $f_{\text{CaO}}, f_{\text{MgO}}$ | basalt oxide mass fractions | 0.10 / 0.07 | – | `erw-3` |
| $C_{\max}$ | stoichiometric CDR ceiling | 309.8 | kg CO₂ / t basalt | `erw-3` |
| $\phi_0$ | reference reactive fraction | 0.20 | – | `erw-3` |
| $d$ | grain size | 50 | µm | `erw-3` |
| $g$ | grain-size factor | 1.414 | – | `erw-3` |
| $\phi_{\text{ref}}=\phi_0 g$ | reference reactive fraction (grain-adjusted) | 0.283 | – | `erw-9` |
| $T_{\text{ref}}, P_{\text{ref}}$ | climate reference anchors | 11 / 1000 | °C / mm | `erw-9` |
| $\Phi$ | effective reactive fraction (capped at 1) | per pixel | – | `erw-9` |
| $p_{\text{ped}}$ | pedogenic-carbonate fraction | 0–0.90 | – | `erw-9` |
| $F$ | CO₂ re-released per t CaCO₃-eq neutralized | 0.88 | t CO₂ / t CaCO₃ | `erw-9` |
| $S$ | soil acidity as lime requirement | per pixel | t CaCO₃ / ha | `erw-3` |

---

## 2. Feedstock chemistry — the Ca and Mg content

**What the model assumes.** A representative tropical-belt basalt fine with
$f_{\text{CaO}}=0.10$ and $f_{\text{MgO}}=0.07$ by mass (`erw-3`, the `basalt`
list). Minor oxides (K₂O 1.5 %, Na₂O 2.5 %, P₂O₅ 0.3 %) and trace metals
(Ni 100 ppm, Cr 200 ppm) are carried for nutrient and risk screening but do not
enter the CDR term.

**Why these values.** Basalts carry their weathering "fuel" as CaO ≈ 8–12 % and
MgO ≈ 5–10 % by mass. For calibration, the six commercial ERW basalts assayed by
Lewis et al. (2021) [1] (their Table 6, p. 10) report *elemental* Ca = 4.08–6.72 %
and Mg = 1.30–5.86 %, i.e. CaO ≈ 5.7–9.4 % and MgO ≈ 2.2–9.7 % — so the model's
10 % CaO sits at/just above the top of that particular set and 7 % MgO mid-range,
consistent with the broader basalt population (Renforth 2012 [44], Abstract p. 229;
compiled GEOROC dataset in Lewis 2021 [1]). The pair is a representative default,
exposed as an override once quarry-specific assays are available.

---

## 3. The stoichiometric CDR ceiling

**Mechanism.** When a Ca- or Mg-silicate weathers under a CO₂-charged soil
solution, each mole of divalent base cation released is charge-balanced by two
moles of bicarbonate:

$$
\text{CaSiO}_3 + 2\,\text{CO}_2 + 3\,\text{H}_2\text{O}
\;\rightarrow\;
\text{Ca}^{2+} + 2\,\text{HCO}_3^- + \text{H}_4\text{SiO}_4 .
$$

So the ceiling is **2 mol CO₂ per mol of Ca²⁺ or Mg²⁺**. Using molar masses
(CaO 56.08, MgO 40.30, CO₂ 44.01 g mol⁻¹):

$$
\text{1 g CaO} \rightarrow \frac{2\times 44.01}{56.08} = 1.570\ \text{g CO}_2,
\qquad
\text{1 g MgO} \rightarrow \frac{2\times 44.01}{40.30} = 2.185\ \text{g CO}_2 .
$$

Per tonne of basalt,

$$
C_{\max} = \big(f_{\text{CaO}}\cdot 1.570 + f_{\text{MgO}}\cdot 2.185\big)\times 1000
= (0.10\cdot1.570 + 0.07\cdot2.185)\times1000 \approx \mathbf{309.8\ kg\ CO_2\,t^{-1}} .
$$

**Source.** The 1:2 cation-to-CO₂ bicarbonate stoichiometry is the mechanistic
basis of ERW CDR accounting (Hartmann et al. 2013 [45]). The cation-based
"maximum uptake" calculation from oxide chemistry, and the resulting **≈ 0.3 t CO₂
per t basalt** for basic rocks, trace to Renforth (2012) [44] and are used at
scale by Beerling et al. (2020) [2] and Strefler et al. (2018) [4]. It is an
**upper bound** in two senses: it assumes complete dissolution, and it credits the
full 2 mol CO₂ per cation, which only holds while carbon is carried as dissolved
bicarbonate — on downstream carbonate precipitation (Ca²⁺ + 2 HCO₃⁻ $\rightarrow$ CaCO₃ +
CO₂ + H₂O) half is re-released, so the long-term net can fall toward ~1 mol CO₂
per mol Ca (Renforth 2019 [15]). Both reductions are applied below (pedogenic
deduction, §7; net-export, §9).

---

## 4. The reactive (effective) fraction

**What the model assumes.** Only $\phi_0 = 0.20$ of the stoichiometric ceiling
is realized on the accreditation horizon at the reference grain size and climate
(`erw-3`, `reactive_fraction_ref`).

**Why.** Field and mesocosm studies consistently report realized CDR far below
the stoichiometric ceiling because dissolution is incomplete on decadal
timescales, secondary minerals sequester cations, and cation exchange delays
export. Lewis et al. (2021) [1] report CDR of 1.3–8.5 t CO₂ ha⁻¹ over 15 yr at
50 t ha⁻¹ — i.e. **26–170 kg CO₂ per tonne basalt actually realized**, against
the ~310 kg ceiling. Their per-basalt spread (Cragmill ≈ 9 %, Blue Ridge ≈ 21 %,
Tichum ≈ 57 % of stoichiometric over 15 yr) brackets $\phi_0=0.20$ as a central
value. Basalt field trials (Kantola et al. 2023 [7]; Larkin et al. 2022 [8]) and
the uncertainty analyses of Reershemius & Suhrhoff (2024) [16]) sit within this
band. A cool-temperate reality check sits at the low end: Dupla et al. (2025) [46]
found detectable dissolution but CO₂-removal rates < 10 % of some other studies
over ~1000 days of Swiss vineyard trials. The model therefore treats $\phi_0=0.20$
as a defensible central anchor (not a single measured constant), later scaled up
in warm/wet climates via the climate factor and swept in `erw-8`.

---

## 5. The grain-size factor

**Mechanism.** Dissolution is surface-reaction-limited, so rate scales with
specific surface area, which for a given mass scales inversely with particle
diameter. The model uses

$$
g = \left(\frac{d_{\text{ref}}}{d}\right)^{\beta},
\qquad d_{\text{ref}}=100\ \mu\text{m},\ \ \beta=0.5,
$$

giving $g=(100/50)^{0.5}=\mathbf{1.414}$ at the 50 µm default.

**Why $\beta=0.5$.** Empirically, silt-dominated basalt fines (<45 µm) weather at
roughly twice the rate of sand-dominated material (150–500 µm), implying
$\beta\approx0.35$–$0.5$. The square-root value is the parameter-free midpoint
(rate ∝ √surface-area) and avoids introducing an extra free constant.
Grain-size control on weathering rate and the associated grinding-energy penalty
are quantified by Strefler et al. (2018) [4] (E ≈ 0.07 GJ t⁻¹ at 50 µm rising to
≈ 3 GJ t⁻¹ at 2 µm) and used in the ERW potential estimates of Beerling et al.
(2020) [2]. Grain size is the model's dominant decision variable and is swept
10–500 µm in `erw-8`.

**Reference reactive fraction after grinding.** `erw-9` combines the two:

$$
\phi_{\text{ref}} = \phi_0\, g = 0.20\times 1.414 = \mathbf{0.283}.
$$

At the reference climate this yields an effective per-tonne removal of
$\phi_{\text{ref}}C_{\max}=0.283\times309.8\approx \mathbf{87.6\ kg\ CO_2\,t^{-1}}$
(`CDR_eff_kg_per_t_ref`), consistent with the Lewis (2021) mesocosm midpoint.

---

## 6. The climate and soil-pH factor

The reference reactive fraction is anchored to a temperate-humid site (US Corn
Belt, $T_{\text{ref}}=11$ °C, $P_{\text{ref}}=1000$ mm). A dimensionless factor
rescales it per pixel:

$$
\Phi(x) = \min\!\Big(\phi_{\text{ref}}\cdot f_{\text{MAT}}\cdot f_{\text{MAP}}\cdot f_{\text{pH}},\ 1\Big),
$$

$$
f_{\text{MAT}} = \mathrm{clamp}\!\left(
\exp\!\Big[-\tfrac{E_a}{R}\Big(\tfrac{1}{T} - \tfrac{1}{T_{\text{ref}}}\Big)\Big],
\,0.3,\,3.0\right),
\qquad
f_{\text{MAP}} = \mathrm{clamp}\!\left(\tfrac{\text{MAP}}{1000},\,0.3,\,3.0\right),
$$

with $T$ in kelvin, $E_a = 68.8$ kJ mol⁻¹, and $T_{\text{ref}} = 284.15$ K (11 °C).

**Temperature term (Arrhenius; headline since 2026-09).** Silicate dissolution is
thermally activated, so the model applies the standard kinetic form directly,
normalized to 1 at $T_{\text{ref}}$. The activation energy is the silicate value
of White & Blum (1995) [43], the same value used by Cascade Climate's Weathering
Potential Explorer. Basalt-specific dissolution experiments support the form:
Gudbrandsson et al. (2011) [40] measured crystalline basalt over 5–75 °C, and
Gíslason & Oelkers (2003) [41] basaltic glass over 6–150 °C; Palandri & Kharaka
(2004) [42] tabulate the activation energies used in reactive-transport ERW
models, and Brantley et al. (2023) [57] and Deng et al. (2022) [58] establish the
exponential temperature control at watershed and global scale. The former linear
multiplier clamp(MAT/11) is retained in `erw-9` as a conservative sensitivity
variant (`CLIMATE_TEMP_MODE <- "linear"`); area-weighted over SSA, Arrhenius
raises gross CDR by ~27% (capped) relative to it.

**Moisture term.** Weathering export requires water moving through the profile;
CDR flux rises with precipitation and drainage. The canonical field demonstration
is White & Blum (1995) [43], who show Si and Na weathering fluxes rising
systematically with runoff across watersheds; the dependence underpins the global
ERW capacity maps of Baek et al. (2023) [5] and Beerling et al. (2020) [2].

**pH term (acid catalysis).** Silicate dissolution is acid-catalyzed: the rate
rises as pH falls (higher H⁺ activity), so acidic soils dissolve basalt faster.
The standard three-mechanism rate law,
$r = k_{\text{acid}}\,a_{\text{H}^+}^{\,n} + k_{\text{neutral}} + k_{\text{base}}\,a_{\text{H}^+}^{-m}$,
is compiled by Palandri & Kharaka (2004) [42]; basalt-specific pH data
(Gíslason & Oelkers 2003 [41]; Gudbrandsson et al. 2011 [40]) show dissolution
rate rising sharply below neutral pH. But dissolution is only half of CDR: the
carbon-capture *efficiency* of the generated alkalinity collapses below pH ~5,
where DIC is almost entirely dissolved CO₂ and dissolution first neutralizes
standing acidity rather than exporting bicarbonate (Bertagni & Porporato 2022
[54]; Holden et al. 2024 [55]; Power et al. 2025 [56]). The model therefore uses
a unimodal (triangular) factor peaking at pH 6.0 — between the pH-5
capture-collapse threshold and carbonic-acid pK$_{a1}$ = 6.35 (moved from a
peak of 5.0 in v2.2 and earlier):

$$
f_{\text{pH}} =
\begin{cases}
0.5 & \text{pH} < 4\\
0.5 + 0.25(\text{pH}-4) & 4 \le \text{pH} < 6\\
1.0 - 0.25(\text{pH}-6) & 6 \le \text{pH} < 8\\
0.5 & \text{pH} \ge 8
\end{cases}
$$

The declining arm above pH 6 follows the acid-catalyzed dissolution kinetics of
White & Brantley (2003) [11] and Brantley et al. (2008) [12]; the rising arm
below pH 6 encodes the capture-efficiency collapse. The 0.5 floor below pH 4
(rather than 0) reflects that low-pH capture is a lag/discounting problem, not a
permanent zero (Kanzaki et al. 2025 [59]). The piecewise-linear form and floor
value remain modelling choices; the whole factor is flagged in code as a **v1
empirical proxy** to be replaced by a reactive-transport surrogate (Kanzaki et
al. 2023 [10]) when calibration data allow.

---

## 7. The pedogenic-carbonate deduction

**Mechanism.** In semi-arid and arid soils a substantial fraction of the Ca/Mg
alkalinity released by weathering precipitates *locally* as secondary
(pedogenic) CaCO₃/MgCO₃ instead of exporting as bicarbonate. Carbonate
precipitation releases roughly half the CO₂ the silicate originally consumed
(Ca²⁺ + 2 HCO₃⁻ $\rightarrow$ CaCO₃ + CO₂ + H₂O), so this alkalinity does not deliver
durable removal and must be deducted:

$$
\text{exported fraction} = 1 - p_{\text{ped}}(x).
$$

**Keying on aridity.** $p_{\text{ped}}$ is binned on the Aridity Index
(AI = MAP / PET) using UNEP (1992) classes [13]:

| AI = MAP/PET | Class | $p_{\text{ped}}$ |
|---|---|---|
| < 0.05 | Hyperarid | 0.90 |
| 0.05–0.20 | Arid | 0.70 |
| 0.20–0.50 | Semi-arid | 0.40 |
| 0.50–0.65 | Dry sub-humid | 0.15 |
| > 0.65 | Humid | 0.00 |

When the CGIAR-CSI Global Aridity Index raster (Zomer et al. 2022 [37]) is
present the deduction is keyed directly on AI; otherwise `erw-9` falls back to a
MAP-only proxy with the same class boundaries, which over-deducts in cool
highlands (Ethiopia, Kenya, Rwanda) where low PET keeps true AI humid.

**Sources.** Renforth (2019) [15] quantifies the "≈ 0.5 mol CO₂ re-released per
mol CaCO₃ precipitated" penalty; Harrington et al. (2023) [47] measure a concrete
16–27 % CDR reduction from carbonate precipitation during riverine transport;
Kanzaki et al. (2023) [10] treat it as a permanence-loss term; and the Beerling
et al. (2020) supplementary accounting [2] flags it. AI bands and dataset: UNEP
(1992) [13]; Zomer et al. (2022) [37].

**Open question.** Whether ERW-formed pedogenic carbonate is durable (~10⁴ yr) or
transient is contested: fertilizer-derived strong acids can re-dissolve it and
re-release the CO₂, in which case it should not be credited as storage at all. The
exact loss fraction and its aridity scaling are among the least-constrained
numbers in the whole calculation — the aridity bins here are a deliberately coarse
v1 proxy, and reviewers will (rightly) push on the loss coefficients.

---

## 8. Assembling the per-tonne and per-hectare gross removal

Per tonne of basalt at pixel $x$:

$$
c(x) = \Phi(x)\, C_{\max}\,\big(1-p_{\text{ped}}(x)\big) \quad[\text{kg CO}_2\,\text{t}^{-1}],
$$

and the **gross** per-hectare removal for an application rate $D(x)$ (t ha⁻¹):

$$
\mathrm{CDR}_{\text{gross}}(x) = D(x)\cdot \frac{c(x)}{1000}\quad[\text{t CO}_2\,\text{ha}^{-1}].
$$

$D(x)$ comes from `erw-3`: either the agronomically **targeted** lime-equivalent
rate (basalt-to-lime ratio $1/\text{effective\_NV}=1/0.0996\approx 10.04$ t basalt
per t CaCO₃-eq, applied to the LiTAS lime requirement) or a **uniform** 10/20/50
t ha⁻¹ counterfactual. The targeted rate uses the LiTAS lime-requirement method
of Aramburu Merlos et al. (2023) [35]; uniform rates match the modelling
convention of Beerling et al. (2020) [2], Baek et al. (2023) [5], and Kantola et
al. (2023) [7].

---

## 9. The net-export correction — the load-bearing accounting step

This is the single most consequential step and the main methodological update in
this version of the pipeline.

**The problem.** The gross removal above credits carbon for *all* weathered
alkalinity. But on an acid soil, alkalinity has two competing fates drawing on
one pool:

- **Neutralize exchangeable acidity** (displace Al³⁺/H⁺, raise pH). This is the
  agronomic benefit — but neutralizing acidity consumes the bicarbonate and
  **releases the CO₂ back to the atmosphere** (HCO₃⁻ + H⁺ $\rightarrow$ H₂O + CO₂, with the
  protons supplied by Al³⁺ hydrolysis). No net carbon is removed. This is exactly
  why agricultural lime is *not* a CDR technology even though it raises yield the
  same way.
- **Export as bicarbonate** to rivers and the ocean. This is durable removal
  (>10⁴ yr).

Counting the acidity-consumed tranche as CDR double-counts the same alkalinity —
once as yield benefit, once as removal.

**The fix.** Deduct the acidity sink, a mass balance:

$$
\boxed{\ \mathrm{CDR}_{\text{net}}(x) = \max\!\big(\mathrm{CDR}_{\text{gross}}(x) - F\cdot S(x),\ 0\big)\ }
$$

- $S(x)$ = the soil's acidity as a lime requirement (t CaCO₃-eq ha⁻¹), already
  computed by `erw-3` (Kamprath / LiTAS). **Regime-dependent:** year-1/NPV use
  the *standing* exchangeable acidity (large); equilibrium uses only the *annual
  re-acidification* increment (small).
- $F$ = CO₂ re-released per tonne of CaCO₃-equivalent acidity neutralized. It is
  **not a tuned parameter** — it falls out of the feedstock's own constants:

$$
F = \frac{\text{CDR\_eff}}{\text{effective\_NV}\times 1000}
  = \frac{87.6}{99.6} \approx \mathbf{0.88}\ \text{t CO}_2\,(\text{t CaCO}_3)^{-1}.
$$

**Consequences.** Because standing acidity is large, the year-1 deduction removes
~80 % of credited CDR; at equilibrium only the small annual re-acidification is
deducted, so most removal survives. Durable CDR is therefore largely a
**steady-state (maintenance)** phenomenon, and year-1 ERW on acid soils is, to
first order, *liming with a small carbon tail*.

**Sources.** The carbon-fate rule — bicarbonate produced against *strong/mineral*
acid (including exchangeable soil acidity) is a net CO₂ source, only bicarbonate
produced against *carbonic* acid is a sink — is established in the
agricultural-liming carbon-accounting literature (West & McBride 2005 [38];
Hamilton et al. 2007 [39], *Global Biogeochemical Cycles*). The most direct ERW
statement of the mechanism is Dietzen & Rosing (2023) [48], whose protocol states
that non-carbonic acids must be accounted for whenever soil pH (H₂O) is below
**6.3**: as pH falls, mineral dissolution rises but CO₂-capture *efficiency* falls
because H⁺/exchangeable acidity consumes the released alkalinity, so naïve
cation-based accounting over-credits CDR on acid soils. That only *exported* alkalinity is durable removal — and that
cation-release mass balance is an upper bound needing a downstream-loss correction
— is the central message of the ERW MRV literature (Reershemius et al. 2023 [50];
Suhrhoff et al. 2024 [49]; Zhang et al. 2022 [51]; Kanzaki et al. 2023 [10];
Levy et al. 2024 [32]).

**One caveat, stated plainly.** This is a first-order *sequential* bound: it
assumes the acidity sink is filled before any alkalinity exports. In reality
weathering, neutralization, and leaching proceed simultaneously, so some
alkalinity exports even on acid soils, and re-acidification continually
regenerates the sink. The truth lies between the gross ("all exports") and net
("sink filled first") bounds; the pipeline writes both `cdr_yield_*` (gross) and
`cdr_yield_*_netexport` (net) rasters and leads the carbon case on the
equilibrium regime, where the two converge.

---

## 10. Regime dependence and time-resolved crediting

The same per-hectare removal is credited under three temporal regimes (in
`erw-7`):

- **Year-1** — one up-front application; CDR accrues over a 5-year phasing
  (30/25/20/15/10 %, ~80 % by year 5), first-order-kinetics-shaped
  (Kanzaki et al. 2023 [10]; Beerling et al. 2020 SI [2]).
- **NPV @ 10 %** — the 5-year CDR tail is discounted by
  $\text{CDR\_NPV\_FACTOR}=\sum_t f_t/(1+r)^t \big/ \sum_t f_t \approx 0.79$.
- **Equilibrium** — steady-state maintenance dose only; the net-export sink is
  the small annual re-acidification, so durable removal is largest here.

---

## 11. Worked example (illustrative pixel)

A warm, wet, moderately acid cropland pixel: MAT = 20 °C, MAP = 1200 mm,
soil pH = 5.0, humid ($p_{\text{ped}}=0$), targeted rate $D=15$ t ha⁻¹,
standing acidity $S_{\text{std}}=3.0$ t CaCO₃ ha⁻¹, maintenance
$S_{\text{maint}}=0.30$ t CaCO₃ ha⁻¹. (Numbers on the 2026-09 Arrhenius +
pH-6.0 basis.)

| Step | Computation | Result |
|---|---|---|
| $f_{\text{MAT}}$ | clamp(exp[−8275.7·(1/293.15 − 1/284.15)]) | 2.45 |
| $f_{\text{MAP}}$ | clamp(1200/1000) | 1.20 |
| $f_{\text{pH}}$ | $0.5+0.25(5-4)$ | 0.75 |
| $\Phi$ | min(0.283·2.45·1.20·0.75, 1) | 0.623 |
| $c$ (per t) | 0.623·309.8·(1−0) | 193 kg t⁻¹ |
| Gross CDR | 15·193/1000 | 2.90 t ha⁻¹ |
| Net (year-1) | max(2.90 − 0.88·3.0, 0) | **0.26 t ha⁻¹** |
| Net (equilibrium) | max(2.90 − 0.88·0.30, 0) | **2.63 t ha⁻¹** |

The collapse from 2.90 $\rightarrow$ 0.26 t ha⁻¹ in year-1 (91% of gross consumed by the
standing acidity), and its survival at equilibrium, is the net-export effect in
miniature.

---

## 12. Assumptions and limitations

| # | Assumption / mechanism | Status | Upgrade path |
|---|---|---|---|
| 1 | 10 %/7 % CaO/MgO basalt | Representative; override per quarry | Quarry assays via `erw-basalt-access` |
| 2 | 1:2 cation:CO₂ stoichiometry | Well-established chemistry | — |
| 3 | 0.20 reference reactive fraction | Central of a wide (0.08–0.55) field range | Site calibration as trials accrue |
| 4 | $\beta=0.5$ grain-size exponent | Defensible midpoint (0.35–0.5) | Feedstock-specific SSA-rate data |
| 5 | Linear climate multipliers | v1 empirical proxy | Reactive-transport surrogate [10] |
| 6 | Triangular pH factor | v1 proxy; true rate monotone in H⁺ | Kinetic dissolution model |
| 7 | Aridity-binned pedogenic loss | Coarse; MAP proxy over-deducts highlands | CGIAR-CSI AI raster [37] |
| 8 | Net-export sequential bound | First-order; presented with gross bound | Coupled transport-reaction |

The two quantities the downstream economics is most sensitive to — the realized
reactive fraction (Step 4) and the pedogenic/net-export loss (Steps 7 and 9) —
are also the least empirically resolved, which is why they are carried explicitly
as bounds and swept in `erw-8` rather than fixed silently.

---

## 13. Provenance of every number and formula

Each quantity in this report traces to one of three kinds of source: a **standard
physical constant**, an **in-model derivation or modelling choice** (whose
provenance is a specific line in the pipeline code, not a journal page), or a
**literature-anchored value** (traced to an exact page / table / figure /
equation, with a confidence flag from the source-verification pass). Line numbers
refer to the scripts as committed. Confidence: **V** = verified from full text,
**A** = confirmed from the paper's abstract only (full text paywalled), **C** =
modelling choice / convention rather than a single measured value.

### 13.1 Standard physical constants

| Quantity | Value | Source and locus |
|---|---|---|
| Molar mass CaO / MgO | 56.08 / 40.30 g mol⁻¹ | IUPAC/CIAAW standard atomic weights 2021 [52] (Ca 40.078, Mg 24.305, O 15.999) |
| Molar mass CO₂ / CaCO₃ | 44.01 / 100.09 g mol⁻¹ | IUPAC/CIAAW 2021 [52] (C 12.011) |
| 1 mol Ca²⁺/Mg²⁺ $\rightarrow$ 2 mol CO₂ (bicarbonate basis) | stoichiometry | Hartmann et al. 2013 [45], **Eq. (8), §2.1** (forsterite reaction) — **V**; Beerling et al. 2020 [2], Methods "CDR", Eqs (4)–(5) |

### 13.2 In-model derivations and modelling choices (provenance = code line)

| Quantity | Value | Code locus |
|---|---|---|
| CaO / MgO mass fraction | 0.10 / 0.07 | `erw-3.R:55–56` (choice; §13.3) |
| Grain size $d$ | 50 µm | `erw-3.R:67` (decision variable) |
| Reference reactive fraction $\phi_0$ | 0.20 | `erw-3.R:74` (anchored; §13.3) |
| Theoretical CCE (1.783, 2.481 g/g) | 0.352 | `erw-3.R:82–84` (molar-mass arithmetic) |
| Stoichiometric ceiling $C_{\max}$ (1.570, 2.185 g/g) | 309.8 kg t⁻¹ | `erw-3.R:87–91` |
| Grain-size factor $g=(100/d)^{0.5}$ | 1.414 | `erw-3.R:100–102` ($\beta=0.5$ choice; §13.3) |
| Grinding curve $E=0.07(50/d)^{1.2}$ | — | `erw-3.R:113–118` (anchored to Strefler; §13.3) |
| Effective NV | 0.0996 t t⁻¹ | `erw-3.R:130` |
| Basalt-to-lime ratio $1/\text{NV}$ | 10.04 | `erw-3.R:131` |
| Reference effective CDR | 87.6 kg t⁻¹ | `erw-3.R:132` |
| $\phi_{\text{ref}}=\phi_0 g$ | 0.283 | `erw-9.R:48` |
| $T_{\text{ref}}, P_{\text{ref}}$ | 11 °C, 1000 mm | `erw-9.R:83–84` (US Corn Belt normal) |
| $f_{\text{MAT}}$ Arrhenius, $E_a$ = 68.8 kJ/mol, clamp [0.3, 3.0] | — | `erw-9.R` §3 (White & Blum 1995 [43]) |
| $f_{\text{pH}}$ triangular, peak 6.0 | — | `erw-9.R` §3 (Bertagni & Porporato [54]; Holden [55]) |
| $\text{climate\_factor}=f_{\text{MAT}}f_{\text{MAP}}f_{\text{pH}}$ | — | `erw-9.R:96` |
| Pedogenic fractions 0.90/0.70/0.40/0.15/0 | — | `erw-9.R:152–163` (bands from §13.3) |
| Reactive fraction cap at 1 | — | `erw-9.R:181` |
| Per-tonne CDR $c(x)$ | — | `erw-9.R:186` |
| CDR yield $= D\cdot c/1000$ | — | `erw-9.R:194` |
| $F=\text{CDR\_eff}/(\text{NV}\times1000)$ | 0.88 | `erw-9.R:233` |
| Net-export $\max(\text{gross}-F S,0)$ | — | `erw-9.R:240–244` |
| CDR phasing 30/25/20/15/10 % | — | `erw-7.R:106` (shape from §13.3) |
| Discount rate | 10 % | `erw-7.R:100` |
| CDR NPV factor | ≈ 0.79 | `erw-7.R:109–111` |

### 13.3 Literature-anchored values (source, exact locus, confidence)

| Quantity | Source — exact locus | Conf. |
|---|---|---|
| Representative basalt CaO/MgO | Lewis 2021 [1], **Table 6, p. 10** (elemental Ca 4.08–6.72 %, Mg 1.30–5.86 %); Renforth 2012 [44], **Abstract, p. 229** | V / A |
| Stoichiometric max ≈ 0.3 t CO₂ t⁻¹ (basic rock) | Renforth 2012 [44], **Abstract, p. 229**; Lewis 2021 [1], **Table 6 p. 10** ($R_{\text{CO}_2}$(CaO+MgO) = 0.13–0.30), formula **Eq. (5), p. 13** | A / V |
| Reactive fraction ~0.20 (realized/stoichiometric) | Lewis 2021 [1], **Table 5, p. 5** (15-yr CDR 1.3–8.5 t ha⁻¹ at 50 t ha⁻¹: Cragmill 1.3 $\rightarrow$ Tichum 8.5; ≈ 9–57 % of stoichiometric); Abstract p. 1; §4.1 p. 13 | V |
| Low-end realized fraction (< 10 %) | Dupla et al. 2025 [46], **Abstract** | A |
| Grinding energy 0.07 GJ t⁻¹ @ 50 µm; 3 GJ t⁻¹ @ 2 µm | Strefler 2018 [4], **"Mining, crushing and grinding" subsection (~p. 7); Fig. 1 (lower axis); SI C, Eq. C1** | V |
| Grain-size $\rightarrow$ dissolution-rate scaling ($\beta\approx0.35$–0.5) | Strefler 2018 [4], **Eq. (3) & Fig. 1 (~p. 3); Eqs (1)–(2), SI B** ($\beta$ is a modelling convention grounded in surface-area kinetics) | V / C |
| Temperature (Arrhenius) dependence | Gudbrandsson et al. 2011 [40]; Gíslason & Oelkers 2003 [41]; Palandri & Kharaka 2004 [42] (activation-energy tables) | V |
| Moisture / runoff dependence | White & Blum 1995 [43] | V |
| pH acid-catalysis rate law | Palandri & Kharaka 2004 [42] (three-mechanism rate law); Gíslason & Oelkers 2003 [41]; White & Brantley 2003 [11] | V |
| Aridity bands 0.05/0.20/0.50/0.65 | UNEP 1992 [13], reproduced verbatim in IPCC SRCCL 2019 [53], **Ch. 3 §3.1.1, Fig. 3.1, p. ~255** (note: Zomer 2022 [37] uses a 0.03 hyperarid variant — not used here) | V |
| Pedogenic carbonate re-releases ≈ 0.5 mol CO₂ per mol CaCO₃ | Renforth 2019 [15], **Eq. (3), Introduction**; Beerling 2020 [2], Methods "CDR", **Eq. (5)** (1 mol CO₂/mol Ca vs 1.72 via ocean) | V |
| Carbonate-precipitation CDR loss 16–27 % | Harrington et al. 2023 [47], **Abstract** | A |
| Acidity-consumed alkalinity ≠ CDR; pH (H₂O) 6.3 threshold | Dietzen & Rosing 2023 [48], **Abstract** | A |
| Ocean-transport permanence / leakage (~9 % silicate) | Kanzaki et al. 2023 [10], **Results/Discussion, Fig. 2** | V |
| LiTAS lime-requirement method (targeted rate) | Aramburu Merlos 2023 [35], **§4.1.6, Eqs (11)–(12)** ($a=0.60,\ b=0.92$) | V |
| Uniform rates 10/20/50 t ha⁻¹ | Beerling 2020 [2] baseline **40 t ha⁻¹ yr⁻¹** (Methods "Baseline simulations"); Baek 2023 [5] 10 t ha⁻¹; Kantola 2023 [7] 50 t ha⁻¹ | A |
| CDR phasing shape (first-order, ~80 % by yr 5) | Kanzaki 2023 [10]; Beerling 2020 [2] SI | C |

**Note on two thresholds.** (i) The pipeline's hyperarid break is 0.05 (UNEP 1992
/ IPCC SRCCL), *not* the 0.03 in Zomer et al. (2022); if the CGIAR-CSI raster is
loaded its own scaling is respected but the class breaks stay at the code values.
(ii) Renforth (2012)'s "~0.3 t CO₂ t⁻¹" and its cation-uptake formula could only
be verified at the abstract; the in-text derivation is behind a paywall and is
therefore marked **A**.

---

## References

1. Lewis, A. L., et al. (2021). Effects of mineralogy, chemistry and physical properties of basalts on carbon capture potential and plant-nutrient element release via enhanced weathering. *Applied Geochemistry*, 132, 105023. https://doi.org/10.1016/j.apgeochem.2021.105023
2. Beerling, D. J., et al. (2020). Potential for large-scale CO₂ removal via enhanced rock weathering with croplands. *Nature*, 583, 242–248. https://doi.org/10.1038/s41586-020-2448-9
4. Strefler, J., Amann, T., Bauer, N., Kriegler, E., & Hartmann, J. (2018). Potential and costs of carbon dioxide removal by enhanced weathering of rocks. *Environmental Research Letters*, 13(3), 034010. https://doi.org/10.1088/1748-9326/aaa9c4
5. Baek, S. H., et al. (2023). Impact of climate on the global capacity for enhanced rock weathering on croplands. *Earth's Future*, 11, e2023EF003698. https://doi.org/10.1029/2023EF003698
7. Kantola, I. B., et al. (2023). Improved net carbon budgets in the U.S. Midwest through direct measured impacts of enhanced weathering. *Global Change Biology*, 29(24), 7012–7028. https://doi.org/10.1111/gcb.16903
8. Larkin, C. S., et al. (2022). Quantification of CO₂ removal in a large-scale enhanced weathering field trial on an oil palm plantation in Sabah, Malaysia. *Frontiers in Climate*, 4, 959229. https://doi.org/10.3389/fclim.2022.959229
10. Kanzaki, Y., Planavsky, N. J., & Reinhard, C. T. (2023). New estimates of the storage permanence and ocean co-benefits of enhanced rock weathering. *PNAS Nexus*, 2(4), pgad059. https://doi.org/10.1093/pnasnexus/pgad059
11. White, A. F., & Brantley, S. L. (2003). The effect of time on the weathering of silicate minerals. *Chemical Geology*, 202(3–4), 479–506. https://doi.org/10.1016/j.chemgeo.2003.03.001
12. Brantley, S. L., Kubicki, J. D., & White, A. F. (Eds.) (2008). *Kinetics of Water-Rock Interaction*. Springer. https://doi.org/10.1007/978-0-387-73563-4
13. UNEP (1992). *World Atlas of Desertification*. United Nations Environment Programme, London: Edward Arnold.
15. Renforth, P. (2019). The negative emission potential of alkaline materials. *Nature Communications*, 10, 1401. https://doi.org/10.1038/s41467-019-09475-5
16. Reershemius, T., & Suhrhoff, T. J. (2024). On error, uncertainty, and assumptions in calculating carbon dioxide removal rates by enhanced rock weathering. *Global Change Biology*, 30(1), e17025. https://doi.org/10.1111/gcb.17025
32. Levy, C. R., et al. (2024). Enhanced rock weathering for carbon removal — monitoring and mitigating potential environmental impacts on agricultural land. *Environmental Science & Technology*, 58(39), 17215–17226. https://doi.org/10.1021/acs.est.4c02368
35. Aramburu Merlos, F., Silva, J. V., Baudron, F., & Hijmans, R. J. (2023). Estimating lime requirements for tropical soils: Model comparison and development. *Geoderma*, 432, 116421. https://doi.org/10.1016/j.geoderma.2023.116421
37. Zomer, R. J., Xu, J., & Trabucco, A. (2022). Version 3 of the Global Aridity Index and Potential Evapotranspiration Database. *Scientific Data*, 9, 409. https://doi.org/10.1038/s41597-022-01493-1
38. West, T. O., & McBride, A. C. (2005). The contribution of agricultural lime to CO₂ emissions in the United States: dissolution, transport, and net emissions. *Agriculture, Ecosystems & Environment*, 108(2), 145–154. https://doi.org/10.1016/j.agee.2005.01.002
39. Hamilton, S. K., Kurzman, A. L., Arango, C., Jin, L., & Robertson, G. P. (2007). Evidence for carbon sequestration by agricultural liming. *Global Biogeochemical Cycles*, 21, GB2021. https://doi.org/10.1029/2006GB002738
40. Gudbrandsson, S., Wolff-Boenisch, D., Gíslason, S. R., & Oelkers, E. H. (2011). An experimental study of crystalline basalt dissolution from 2 ≤ pH ≤ 11 and temperatures from 5 to 75 °C. *Geochimica et Cosmochimica Acta*, 75(19), 5496–5509. https://doi.org/10.1016/j.gca.2011.06.035
41. Gíslason, S. R., & Oelkers, E. H. (2003). Mechanism, rates, and consequences of basaltic glass dissolution: II. An experimental study of the dissolution rates of basaltic glass as a function of pH and temperature. *Geochimica et Cosmochimica Acta*, 67(20), 3817–3832. https://doi.org/10.1016/S0016-7037(03)00176-5
42. Palandri, J. L., & Kharaka, Y. K. (2004). *A compilation of rate parameters of water–mineral interaction kinetics for application to geochemical modeling*. USGS Open-File Report 2004-1068. https://pubs.usgs.gov/publication/ofr20041068
43. White, A. F., & Blum, A. E. (1995). Effects of climate on chemical weathering in watersheds. *Geochimica et Cosmochimica Acta*, 59(9), 1729–1747. https://doi.org/10.1016/0016-7037(95)00078-E
44. Renforth, P. (2012). The potential of enhanced weathering in the UK. *International Journal of Greenhouse Gas Control*, 10, 229–243. https://doi.org/10.1016/j.ijggc.2012.06.011
45. Hartmann, J., West, A. J., Renforth, P., Köhler, P., De La Rocha, C. L., Wolf-Gladrow, D. A., Dürr, H. H., & Scheffran, J. (2013). Enhanced chemical weathering as a geoengineering strategy to reduce atmospheric carbon dioxide, supply nutrients, and mitigate ocean acidification. *Reviews of Geophysics*, 51(2), 113–149. https://doi.org/10.1002/rog.20004
46. Dupla, X., Bertagni, M. B., & Grand, S. (2025). Three years of field trials indicate a sustained enhanced rock weathering signal with limited CO₂ removal. *Environmental Science & Technology*, 59(48), 25751–25764. https://doi.org/10.1021/acs.est.5c09820
47. Harrington, K. J., Hilton, R. G., & Henderson, G. M. (2023). Implications of the riverine response to enhanced weathering for CO₂ removal in the UK. *Applied Geochemistry*, 152, 105643. https://doi.org/10.1016/j.apgeochem.2023.105643
48. Dietzen, C., & Rosing, M. T. (2023). Quantification of CO₂ uptake by enhanced weathering of silicate minerals applied to acidic soils. *International Journal of Greenhouse Gas Control*, 125, 103872. https://doi.org/10.1016/j.ijggc.2023.103872
49. Suhrhoff, T. J., Reershemius, T., Wang, J., Jordan, J. S., Reinhard, C. T., & Planavsky, N. J. (2024). A tool for assessing the sensitivity of soil-based approaches for quantifying enhanced weathering: a US case study. *Frontiers in Climate*, 6, 1346117. https://doi.org/10.3389/fclim.2024.1346117
50. Reershemius, T., Kelland, M. E., Jordan, J. S., et al. (2023). Initial validation of a soil-based mass-balance approach for empirical monitoring of enhanced rock weathering rates. *Environmental Science & Technology*, 57(48), 19497–19507. https://doi.org/10.1021/acs.est.3c03609
51. Zhang, S., Planavsky, N. J., Katchinoff, J., Raymond, P. A., Kanzaki, Y., Reershemius, T., & Reinhard, C. T. (2022). River chemistry constraints on the carbon capture potential of surficial enhanced rock weathering. *Limnology & Oceanography*, 67(S2), S148–S157. https://doi.org/10.1002/lno.12244
52. Prohaska, T., Irrgeher, J., Benefield, J., et al. (2022). Standard atomic weights of the elements 2021 (IUPAC Technical Report). *Pure and Applied Chemistry*, 94(5), 573–600. https://doi.org/10.1515/pac-2019-0603
53. IPCC (2019). Desertification (Chapter 3). In *Climate Change and Land: an IPCC Special Report (SRCCL)*. Mirzabaev, A., Wu, J., Evans, J., et al. https://www.ipcc.ch/srccl/chapter/chapter-3/
54. Bertagni, M. B., & Porporato, A. (2022). The carbon-capture efficiency of natural water alkalinization: implications for enhanced weathering. *Science of The Total Environment*, 838, 156524. https://doi.org/10.1016/j.scitotenv.2022.156524
55. Holden, F. J., Davies, K., Bird, M. I., Hume, R., Green, H., Beerling, D. J., & Nelson, P. N. (2024). In-field carbon dioxide removal via weathering of crushed basalt applied to acidic tropical agricultural soil. *Science of The Total Environment*, 955, 176568. https://doi.org/10.1016/j.scitotenv.2024.176568
56. Power, I. M., Hatten, V. N. J., Guo, M., Schaffer, Z. R., Rausis, K., & Klyn-Hesselink, H. (2025). Are enhanced rock weathering rates overestimated? A few geochemical and mineralogical pitfalls. *Frontiers in Climate*, 6, 1510747. https://doi.org/10.3389/fclim.2024.1510747
57. Brantley, S. L., Shaughnessy, A., Lebedeva, M. I., & Balashov, V. N. (2023). How temperature-dependent silicate weathering acts as Earth's geological thermostat. *Science*, 379(6630), 382–389. https://doi.org/10.1126/science.add2922
58. Deng, K., Yang, S., & Guo, Y. (2022). A global temperature control of silicate weathering intensity. *Nature Communications*, 13, 1521. https://doi.org/10.1038/s41467-022-29415-0
59. Kanzaki, Y., Planavsky, N. J., Zhang, S., Jordan, J., Suhrhoff, T. J., & Reinhard, C. T. (2025). Soil cation storage is a key control on the carbon removal dynamics of enhanced weathering. *Environmental Research Letters*, 20(7), 074055. https://doi.org/10.1088/1748-9326/ade0d5

*References [1]–[37] match the master catalogue in `docs/erw-parameters.md`. [38]–[59] were added and DOI-verified for this report to source the weathering-kinetics, stoichiometry, net-export, and constant-provenance items specifically. Page/table/equation loci in §13.3 were located by direct inspection of each source; items marked **A** were confirmable only at the abstract because the full text is paywalled.*
