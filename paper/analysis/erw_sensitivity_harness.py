#!/usr/bin/env python3
"""
Layered sensitivity harness for the private/public return-envelope analysis.

Design goal: one systematic, reproducible object that supports BOTH
communication (a small set of named scenarios) and rigor (a full-factorial
global sweep + one-at-a-time tornado). Built entirely on the analytic engine
in erw_provisional_engine.py, so every scenario is a closed-form re-evaluation
of three per-pixel primitives (AGRO, BAS, CDRN) -- no model re-run.

Five uncertain levers are swept, each mapped to a coherent Low/Central/High band:

  lever            central   low            high           enters
  ---------------  --------  -------------  -------------   ------------------
  carbon price p   150       100            250            public, combined
  MRV cost m       20        40             10             public, combined
  delivered cost   x1.0      x1.5           x0.75          all three
  CDR rate d_t     x1.0      x0.5           x1.5           public, combined
  yield uplift     x1.0      x0.75          x1.5           private, combined

The three NAMED scenarios stack the levers coherently:
  Conservative  = all levers at their ERW-unfavourable end
  Central       = manuscript baseline (Table 2)
  Optimistic    = all levers at their ERW-favourable end

Outputs (paper/tables/ and paper/figures/):
  sens_scenarios.csv          envelope areas/$/CDR under the 3 named scenarios
  sens_global_sweep.csv       every factorial combo x envelope areas
  sens_sweep_summary.csv      min/median/max envelope area across the sweep
  sens_tornado.csv            one-at-a-time swing of each lever (intersection + public)
  sens_robustness_core.csv    core/candidate targeting tiers from the sweep
  sens_scenario_tornado.png   2-panel communication figure
  robustness_core_headline.png  per-pixel robustness (core-targeting) map

Run:
  pip install rasterio geopandas matplotlib --break-system-packages
  ERW_ROOT=$(pwd) python3 paper/analysis/erw_sensitivity_harness.py
"""
import os, sys, itertools, warnings
import numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt

warnings.filterwarnings("ignore", category=RuntimeWarning)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import erw_provisional_engine as E   # reuse the validated primitives + math

ROOT = os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TBL  = f"{ROOT}/paper/tables"; FIG = f"{ROOT}/paper/figures"
os.makedirs(TBL, exist_ok=True); os.makedirs(FIG, exist_ok=True)

REGIME, ALLOC = "equilibrium", "targeted"   # manuscript headline
MRV_CENTRAL   = 20.0

# ----------------------------------------------------------------------------
# Generalised envelopes: like E.envelopes but with MRV as an explicit lever.
# CDRN in the engine is physical net-export tCO2/ha (crev/(CARBON-MRV)), so the
# revenue re-scales cleanly with any (carbon, mrv) pair.
def envelopes(P, carbon=150.0, mrv=MRV_CENTRAL, ymult=1.0, cmult=1.0, rmult=1.0):
    net_price = carbon - mrv
    ga = P['AGRO']*ymult - P['BAS']*cmult
    gc = P['CDRN']*rmult*net_price - P['BAS']*cmult
    gco = P['AGRO']*ymult + P['CDRN']*rmult*net_price - P['BAS']*cmult
    return ga > 0, gc > 0, gco > 0

def area_Mha(P, mask):
    return float(np.nansum(np.where(mask & P['ok'], P['WSUM'], 0)))/1e6

def cdr_Mt(P, mask):
    return float(np.nansum(np.where(mask & P['ok'], P['CDRT'], 0)))/1e6

def summarize(P, mask):
    pr = float(np.nansum(np.where(mask & P['ok'], P['AGRO']*P['WSUM'], 0)))/1e6
    return dict(area_Mha=round(area_Mha(P, mask), 2),
                private_M=int(round(pr)),
                cdr_Mt=round(cdr_Mt(P, mask), 1))

# ----------------------------------------------------------------------------
# Load headline primitives once (equilibrium, net-export).
# erw-7 now bakes the net-export deduction into band 9, so build_primitives()
# returns net-export CDR directly; the old E.apply_netexport() wrapper is gone.
#
# CAVEAT on the rmult lever below: it scales the ALREADY-DEDUCTED net CDR
# (r * cdr_net). Physically r multiplies GROSS CDR, and the acidity sink F*S and
# the LCA term are fixed subtrahends, so cdr_net is super-linear in r and this
# compresses the lever on both sides (at r=2 the public envelope is 5.90 Mha, not
# the 2.68 Mha reported here). Likewise `carbon`, `mrv` and `cmult` are not three
# independent levers: the public envelope depends on them only through the ratio
# (carbon - mrv)/cmult. See erw/erw-12-public-envelope-sensitivity.R, which
# reconstructs GROSS/S/LCA separately and does both correctly.
print(f"Loading headline primitives ({ALLOC} / {REGIME} / net-export)...")
price = E.crop_prices()
P = E.build_primitives(ALLOC, REGIME, price)

# ============================================================================
# 1) NAMED SCENARIOS  -- the communication layer
# ============================================================================
SCENARIOS = {
    "Conservative": dict(carbon=100, mrv=40, cmult=1.5,  rmult=0.5, ymult=0.75),
    "Central":      dict(carbon=150, mrv=20, cmult=1.0,  rmult=1.0, ymult=1.0),
    "Optimistic":   dict(carbon=250, mrv=10, cmult=0.75, rmult=1.5, ymult=1.5),
}
srows = []
for name, s in SCENARIOS.items():
    pr, pu, co = envelopes(P, **s)
    inter = pr & pu
    for env, m in [("Private", pr), ("Public", pu), ("Intersection", inter), ("Combined", co)]:
        srows.append(dict(scenario=name, envelope=env,
                          **{k: s[k] for k in ("carbon","mrv","cmult","rmult","ymult")},
                          **summarize(P, m)))
scen_df = pd.DataFrame(srows)
scen_df.to_csv(f"{TBL}/sens_scenarios.csv", index=False)
print("\n=== Named scenarios (targeted, equilibrium, net-export) ===")
print(scen_df.pivot(index="envelope", columns="scenario", values="area_Mha")
      .reindex(["Private","Public","Intersection","Combined"])[["Conservative","Central","Optimistic"]])

# ============================================================================
# 2) FULL-FACTORIAL GLOBAL SWEEP  -- the rigor layer
# ============================================================================
GRID = dict(
    carbon=[100, 150, 250],
    mrv=[10, 20, 40],
    cmult=[0.75, 1.0, 1.5],
    rmult=[0.5, 1.0, 1.5],
    ymult=[0.75, 1.0, 1.5],
)
keys = list(GRID)
combos = list(itertools.product(*[GRID[k] for k in keys]))
print(f"\nFull-factorial sweep: {len(combos)} combinations")

freq_inter = np.zeros_like(P['WSUM'], dtype=np.float32)   # per-pixel: in intersection
freq_comb  = np.zeros_like(P['WSUM'], dtype=np.float32)   # per-pixel: profitable combined
rows = []
for combo in combos:
    s = dict(zip(keys, combo))
    pr, pu, co = envelopes(P, **s)
    inter = pr & pu
    rows.append(dict(**s,
                     private_Mha=round(area_Mha(P, pr), 2),
                     public_Mha=round(area_Mha(P, pu), 2),
                     intersection_Mha=round(area_Mha(P, inter), 2),
                     combined_Mha=round(area_Mha(P, co), 2),
                     intersection_CDR_Mt=round(cdr_Mt(P, inter), 1),
                     public_CDR_Mt=round(cdr_Mt(P, pu), 1)))
    freq_inter += np.where(inter & P['ok'], 1, 0)
    freq_comb  += np.where(co & P['ok'], 1, 0)
sweep_df = pd.DataFrame(rows)
sweep_df.to_csv(f"{TBL}/sens_global_sweep.csv", index=False)

# distributional summary of each envelope across the whole grid
summ = []
for col in ["private_Mha","public_Mha","intersection_Mha","combined_Mha"]:
    v = sweep_df[col]
    summ.append(dict(envelope=col.replace("_Mha",""),
                     min=round(v.min(),2), p25=round(v.quantile(.25),2),
                     median=round(v.median(),2), p75=round(v.quantile(.75),2),
                     max=round(v.max(),2)))
summ_df = pd.DataFrame(summ)
summ_df.to_csv(f"{TBL}/sens_sweep_summary.csv", index=False)
print("\n=== Envelope area distribution across the full grid (Mha) ===")
print(summ_df.to_string(index=False))

# per-pixel robustness -> core / candidate targeting tiers
N = len(combos)
robust_i = np.where(P['ok'], freq_inter/N, np.nan)
core = robust_i >= 0.50
cand = robust_i >= 0.33
core_rows = [
    dict(tier="core (>=50% of grid)",      **summarize(P, core)),
    dict(tier="candidate (>=33% of grid)", **summarize(P, cand)),
]
pd.DataFrame(core_rows).to_csv(f"{TBL}/sens_robustness_core.csv", index=False)
print("\n=== Robust core-targeting tiers ===")
print(pd.DataFrame(core_rows).to_string(index=False))

# ============================================================================
# 3) ONE-AT-A-TIME TORNADO  -- around the Central baseline
# ============================================================================
CENTRAL = dict(carbon=150, mrv=20, cmult=1.0, rmult=1.0, ymult=1.0)
def inter_area(**kw):
    a = dict(CENTRAL); a.update(kw); pr, pu, _ = envelopes(P, **a); return area_Mha(P, pr & pu)
def public_area(**kw):
    a = dict(CENTRAL); a.update(kw); _, pu, _ = envelopes(P, **a); return area_Mha(P, pu)

LEVER_RANGE = dict(
    carbon=[100, 250], mrv=[40, 10], cmult=[1.5, 0.75], rmult=[0.5, 1.5], ymult=[0.75, 1.5])
LEVER_LABEL = dict(carbon="Carbon price ($100-250)", mrv="MRV cost ($40-10)",
                   cmult="Delivered cost (x1.5-0.75)", rmult="CDR rate (x0.5-1.5)",
                   ymult="Yield uplift (x0.75-1.5)")
base_i = inter_area(); base_p = public_area()
trows = []
for lev, (lo, hi) in LEVER_RANGE.items():
    i_lo, i_hi = inter_area(**{lev: lo}), inter_area(**{lev: hi})
    p_lo, p_hi = public_area(**{lev: lo}), public_area(**{lev: hi})
    trows.append(dict(lever=LEVER_LABEL[lev],
                      inter_low=round(i_lo,2), inter_high=round(i_hi,2),
                      inter_swing=round(abs(i_hi-i_lo),2),
                      public_low=round(p_lo,2), public_high=round(p_hi,2),
                      public_swing=round(abs(p_hi-p_lo),2)))
tor_df = pd.DataFrame(trows).sort_values("inter_swing", ascending=False)
tor_df.to_csv(f"{TBL}/sens_tornado.csv", index=False)
print(f"\n=== Tornado (baseline intersection {base_i:.2f} Mha, public {base_p:.2f} Mha) ===")
print(tor_df.to_string(index=False))

# ============================================================================
# 4) COMMUNICATION FIGURE  -- scenario bars + tornado
# ============================================================================
fig, ax = plt.subplots(1, 2, figsize=(13, 5))

# (a) scenario bars: four envelopes x three scenarios
envs = ["Private","Public","Intersection","Combined"]
scs = ["Conservative","Central","Optimistic"]
piv = scen_df.pivot(index="envelope", columns="scenario", values="area_Mha").reindex(envs)[scs]
x = np.arange(len(envs)); w = 0.26
cols = {"Conservative":"#b0553f", "Central":"#4472a8", "Optimistic":"#2c7a3f"}
for j, sc in enumerate(scs):
    ax[0].bar(x + (j-1)*w, piv[sc].values, w, label=sc, color=cols[sc])
ax[0].set_xticks(x); ax[0].set_xticklabels(envs, rotation=12)
ax[0].set_ylabel("Deployable area (Mha)")
ax[0].set_title("(a) Return envelopes under three scenarios\n(targeted, equilibrium, net-export)")
ax[0].legend(frameon=False, fontsize=9)
for j, sc in enumerate(scs):
    for xi, val in zip(x + (j-1)*w, piv[sc].values):
        ax[0].text(xi, val+0.05, f"{val:.1f}", ha="center", va="bottom", fontsize=7)

# (b) tornado on the intersection (doubly-justified) area
t = tor_df.sort_values("inter_swing")
y = np.arange(len(t))
for yi, (_, r) in zip(y, t.iterrows()):
    lo, hi = sorted([r["inter_low"], r["inter_high"]])
    ax[1].plot([lo, hi], [yi, yi], color="#4472a8", lw=8, solid_capstyle="butt")
ax[1].axvline(base_i, color="grey", ls="--", lw=1, label=f"baseline {base_i:.1f} Mha")
ax[1].set_yticks(y); ax[1].set_yticklabels(t["lever"], fontsize=9)
ax[1].set_xlabel("Intersection area (Mha)")
ax[1].set_title("(b) One-at-a-time sensitivity of the\ndoubly-justified (intersection) area")
ax[1].legend(frameon=False, fontsize=8, loc="lower right")
plt.tight_layout()
plt.savefig(f"{FIG}/sens_scenario_tornado.png", dpi=150)
print(f"\nWrote {FIG}/sens_scenario_tornado.png")

# ============================================================================
# 5) ROBUSTNESS / CORE-TARGETING MAP
# ============================================================================
try:
    fig2, ax2 = plt.subplots(figsize=(7, 6.5))
    ext = [E._grid.__defaults__ is None] if False else None
    im = ax2.imshow(robust_i, cmap="inferno", vmin=0, vmax=robust_i[np.isfinite(robust_i)].max() if np.isfinite(robust_i).any() else 1)
    ax2.set_title(f"Targeting robustness: fraction of {N} parameter\ncombinations under which a pixel is doubly-justified")
    ax2.axis("off")
    cb = fig2.colorbar(im, ax=ax2, shrink=0.7); cb.set_label("robustness score")
    plt.tight_layout(); plt.savefig(f"{FIG}/robustness_core_headline.png", dpi=150)
    print(f"Wrote {FIG}/robustness_core_headline.png")
except Exception as ex:
    print("map skipped:", ex)

print("\nDone. Tables -> paper/tables/sens_*.csv ; Figures -> paper/figures/sens_*.png")
