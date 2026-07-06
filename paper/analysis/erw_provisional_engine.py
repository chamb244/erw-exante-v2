#!/usr/bin/env python3
"""
PROVISIONAL Python compute engine for the private/public return-envelope analysis.
Mirrors the R pipeline (erw-7 output schema + erw-11 logic). Generates the paper's
figures/tables. This is the sandbox generator; erw/erw-11-*.R is the canonical
pipeline-native version. Both implement the same math.

WHY THIS FILE EXISTS: the scratch scripts used during drafting are ephemeral;
this consolidates the validated logic into the repo so work can resume.

ENVIRONMENT (rebuild on a fresh sandbox):
  pip install rasterio geopandas matplotlib --break-system-packages
  (R/terra/gdal are NOT available in the sandbox; this reads the GeoTIFFs directly.)

KEY CONSTANTS
  CARBON = 150 $/tCO2 ; MRV = 20 $/tCO2
  F = cdr_eff_per_t / (effective_NV*1000) = 87.64/99.56 = 0.88  (tCO2 re-released
      per t CaCO3-eq of acidity neutralized; from basalt_feedstock_chemistry.csv)
  Band order in economics_erw/{alloc}/{crop}_{regime}.tif (14 bands):
    1 _ha 2 _ya 3 _loss 4 _yresp_tha 5 _agro_return_usha 6 _basalt_tha
    7 _basalt_cost_usha 8 _cdr_gross_tha 9 _cdr_net_tha 10 _cdr_revenue_usha
    11 _gm_combined_usha 12 _gm_agro_only_usha 13 _gm_cdr_only_usha 14 _roi_combined

NET-EXPORT ACCOUNTING (the key model change; see paper/netexport-cdr-memo.md)
  net_export_CDR = max(gross_CDR - F * S, 0)
  S = acidity sink as lime requirement (t CaCO3/ha):
      NPV / year-1 -> caco3_kamprath.tif   (standing exchangeable acidity)
      equilibrium  -> caco3_merlos_maintenance.tif band 1 (annual re-acidification)
  Implemented per pixel as a multiplier phi = max(1 - F*S/gross_CDR_tha, 0),
  applied to CDRN (revenue-effective) and CDRT (physical).

HEADLINE = equilibrium regime + net-export CDR (both streams steady-state).

======================================================================
NEXT STEPS (agreed 2026-07-02, to implement on resume):
  REFINEMENT 1 -- over-liming private penalty (DO FIRST; well-grounded):
    Evaluate the crop pH-response at the POST-application pH, not baseline pH, so
    the agronomic return declines when a dose pushes pH past the crop's optimum
    (micronutrient lockout, P retrogradation). Data available:
      - soil pH: soilgrids_properties_cropland.tif band 2
      - ECEC (buffering): soilgrids_properties_cropland.tif band ~9 (see erw-3)
      - crop pH optimum/max: EcoCrop tables in erw-4 / ecocrop_parameters_hp.csv
      - EcoCrop relative-yield rasters: data/ecocrop_f/hp_crop_suitability_*_0.tif
    Effect: private return becomes hump-shaped in rate (peaks ~ lime requirement);
    mainly bites uniform 20/50 on mildly-acid soils -> shrinks their private &
    combined envelopes (can go yield-negative). Re-trace Table 2 + pH gradient fig.

  REFINEMENT 2 -- weathering/kinetic saturation (DO SECOND; as sensitivity band):
    D_eff = D_max * D / (K_d + D)  applied to reacted tonnage -> CDR concave in dose.
    K_d is a FREE parameter (no SSA calibration) -> report as a bound/sensitivity,
    NOT a calibrated point. Gives an interior public-optimal rate.

  THEN: with both, compute pixel-specific PRIVATE-optimal, PUBLIC-optimal, and
    COMBINED-optimal application rates (the analysis flagged in the RQ discussion).

  ALSO PENDING (regenerate on equilibrium net-export basis; currently NPV/gross):
    RQ4 robustness sweep + tornado ; RQ5 core-targeting map ; RQ6 data-priority table.
  OPEN DECISION: which allocation to feature in HEADLINE MAPS (targeted vs uniform-50);
    public/VCM case is much larger at uniform-50 (Table 2), so targeted may understate it.
======================================================================
"""
import os, numpy as np, pandas as pd, rasterio
from rasterio.features import rasterize
from rasterio.warp import reproject, Resampling
import geopandas as gpd

import os
ROOT = os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))  # repo root; override with ERW_ROOT
DATA = f"{ROOT}/data"; FIG = f"{ROOT}/paper/figures"; TBL = f"{ROOT}/paper/tables"
CARBON, MRV, F = 150.0, 20.0, 0.88
CROPS = ['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL',
 'POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
BI = {'ha':1,'agro':5,'bas':7,'cnet':9,'crev':10,'gmc':11}
FAO_ITEM = {'MAIZ':['Maize (corn)'],'SORG':['Sorghum'],'BEAN':['Beans, dry'],'CHIC':['Chick peas, dry'],
 'LENT':['Lentils, dry'],'WHEA':['Wheat'],'BARL':['Barley'],'ACOF':['Coffee, green'],'RCOF':['Coffee, green'],
 'PMIL':['Millet'],'SMIL':['Millet'],'POTA':['Potatoes'],'SWPO':['Sweet potatoes'],'CASS':['Cassava, fresh'],
 'COWP':['Cow peas, dry'],'PIGE':['Pigeon peas, dry'],'SOYB':['Soya beans'],'GROU':['Groundnuts, excluding shelled'],
 'SUGC':['Sugar cane'],'COTT':['Cotton seed'],'COCO':['Cocoa beans'],'TEAS':['Tea leaves'],'TOBA':['Unmanufactured tobacco']}
SSA_AREAS = {'Angola','Benin','Botswana','Burkina Faso','Burundi','Cameroon','Central African Republic','Chad',
 'Congo','Democratic Republic of the Congo','Equatorial Guinea','Eritrea','Eswatini','Swaziland','Ethiopia','Gabon',
 'Gambia','Ghana','Guinea','Guinea-Bissau',"Côte d'Ivoire",'Kenya','Lesotho','Liberia','Madagascar','Malawi','Mali',
 'Mauritania','Mozambique','Namibia','Niger','Nigeria','Rwanda','Senegal','Sierra Leone','Somalia','South Sudan',
 'Sudan (former)','Sudan','United Republic of Tanzania','Togo','Uganda','South Africa','Zambia','Zimbabwe'}
FARM_HA = {'AGO':2.0,'BDI':0.5,'BEN':1.7,'BFA':4.5,'BWA':5.0,'CAF':1.5,'CIV':3.0,'CMR':1.6,'COD':1.6,'COG':1.5,
 'DJI':2.0,'ERI':1.5,'ETH':1.0,'GAB':1.5,'GHA':1.2,'GIN':2.0,'GMB':1.5,'GNB':1.5,'GNQ':1.5,'KEN':1.0,'LBR':1.5,
 'LSO':1.0,'MDG':0.9,'MLI':4.0,'MOZ':1.5,'MRT':3.0,'MWI':0.8,'NAM':5.0,'NER':5.0,'NGA':1.8,'RWA':0.6,'SDN':5.0,
 'SEN':3.5,'SLE':1.5,'SOM':2.5,'SSD':2.0,'SWZ':1.5,'TCD':3.0,'TGO':1.6,'TZA':2.0,'UGA':1.1,'ZAF':3.0,'ZMB':2.5,'ZWE':2.0}
FARM_DEFAULT = 2.0

def crop_prices():
    d = pd.read_csv(f"{DATA}/FAOSTAT_data_en_4-24-2023.csv")
    d = d[(d.Year > 2015) & (d.Year <= 2020) & (d.Area.isin(SSA_AREAS))]
    return {c: (float(np.median(d[d.Item.isin(FAO_ITEM[c])]['Value'])) if len(d[d.Item.isin(FAO_ITEM[c])]) else np.nan) for c in CROPS}

def _grid(path, band, transform, crs, H, W, how=Resampling.average):
    dst = np.full((H, W), np.nan, np.float32)
    with rasterio.open(path) as s:
        reproject(rasterio.band(s, band), dst, src_transform=s.transform, src_crs=s.crs,
                  dst_transform=transform, dst_crs=crs, resampling=how)
        if s.nodata is not None: dst[dst == s.nodata] = np.nan
    return dst

def build_primitives(alloc, regime, price):
    ref = f"{DATA}/economics_erw/{alloc}/MAIZ_{regime}.tif"
    with rasterio.open(ref) as ds:
        H, W = ds.height, ds.width; TR = ds.transform; CRS = ds.crs
    prod = rasterio.open(f"{DATA}/spam_prod_processed.tif").read().astype(np.float32)
    z = np.zeros((H, W)); na=z.copy();nb=z.copy();ncr=z.copy();ws=z.copy();cdrt=z.copy();vop=z.copy()
    for ci, c in enumerate(CROPS):
        with rasterio.open(f"{DATA}/economics_erw/{alloc}/{c}_{regime}.tif") as ds:
            arr = ds.read([BI['ha'],BI['agro'],BI['bas'],BI['cnet'],BI['crev'],BI['gmc']]).astype(np.float32); nod = ds.nodata
        if nod is not None: arr = np.where(arr == nod, np.nan, arr)
        ha, agro, bas, cnet, crev, gmc = arr
        dfn = np.isfinite(gmc) & np.isfinite(ha) & (ha > 0); w = np.where(dfn, ha, 0.0)
        na += np.where(dfn, np.nan_to_num(agro)*w, 0); nb += np.where(dfn, np.nan_to_num(bas)*w, 0)
        ncr += np.where(dfn, np.nan_to_num(crev)*w, 0); ws += w; cdrt += np.where(dfn, np.nan_to_num(cnet)*w, 0)
        p = price[c]
        if np.isfinite(p): vop += np.where(dfn, np.nan_to_num(prod[ci])*p, 0)
    ok = ws > 0; wsm = np.where(ok, ws, 1)
    return dict(AGRO=np.where(ok,na/wsm,np.nan), BAS=np.where(ok,nb/wsm,np.nan),
                CDRN=np.where(ok,ncr/wsm,np.nan)/(CARBON-MRV), WSUM=np.where(ok,ws,np.nan),
                VOP=np.where(ok,vop,np.nan), CDRT=np.where(ok,cdrt,np.nan), ok=ok, TR=TR, CRS=CRS, H=H, W=W)

def apply_netexport(P, regime):
    sink_file = "caco3_kamprath.tif" if regime in ("npv","year1") else "caco3_merlos_maintenance.tif"
    S = np.nan_to_num(_grid(f"{DATA}/{sink_file}", 1, P['TR'], P['CRS'], P['H'], P['W']))
    g = np.where(P['WSUM']>0, P['CDRT']/P['WSUM'], np.nan)
    phi = np.where(np.isfinite(g) & (g>0), np.maximum(1 - F*S/g, 0), 0.0)
    Q = dict(P); Q['CDRN'] = P['CDRN']*phi; Q['CDRT'] = P['CDRT']*phi; Q['phi'] = phi
    return Q

def envelopes(P, carbon=CARBON, ymult=1, cmult=1, rmult=1):
    ga = P['AGRO']*ymult - P['BAS']*cmult
    gc = P['CDRN']*rmult*(carbon-MRV) - P['BAS']*cmult
    gco = P['AGRO']*ymult + P['CDRN']*rmult*(carbon-MRV) - P['BAS']*cmult
    return ga>0, gc>0, gco>0

def summarize(P, m):  # returns dict of $M / Mha / Mt over mask m
    S = lambda x: float(np.nansum(np.where(m, x*P['WSUM'], 0)))
    return dict(area_Mha=round(float(np.nansum(np.where(m, P['WSUM'], 0)))/1e6,2),
                priv_M=int(round(S(P['AGRO'])/1e6)), pub_M=int(round(S(P['CDRN']*(CARBON-MRV))/1e6)),
                cost_M=int(round(S(P['BAS'])/1e6)), cdr_Mt=round(float(np.nansum(np.where(m,P['CDRT'],0)))/1e6,1))

def table2_ladder(regime="equilibrium"):
    price = crop_prices(); rows = []
    for alloc in ['targeted','uniform_10','uniform_20','uniform_50']:
        P = apply_netexport(build_primitives(alloc, regime, price), regime); ok = P['ok']
        pr, pu, co = envelopes(P)
        for e, msk in [('Private',pr),('Public',pu),('Intersection',pr&pu),('Combined>0',co)]:
            rows.append(dict(Allocation=alloc, Envelope=e, **summarize(P, msk&ok)))
    df = pd.DataFrame(rows); df.to_csv(f"{TBL}/table2_envelopes_regen.csv", index=False)
    print(df.to_string(index=False)); return df

if __name__ == "__main__":
    print("Regenerating Table 2 (equilibrium, net-export)...")
    table2_ladder("equilibrium")
