#!/usr/bin/env python3
"""
Refinement 1 -- over-liming private penalty (PROTOTYPE).

Idea: the agronomic return is credited today at BASELINE acidity relief and never
penalized for OVERSHOOT. When an applied dose raises soil pH past the crop's
optimum ceiling (micronutrient lockout, P retrogradation), yield declines. We
evaluate the crop's pH suitability at the POST-application pH and haircut the
agronomic return accordingly. This is the same surplus alkalinity (beyond the
soil's acidity demand) that exports as durable CDR under net-export accounting --
so over-liming and CDR are two faces of over-application.

STATUS: prototype. Grounded parts = direction + EcoCrop pH ceilings. Uncertain
parts (flag as sensitivity): buffer constant k_beta, and the realized alkalinity
fraction (effective_NV). Conservative: penalty erodes the gain toward 0 (does not
yet go net-negative below baseline).
"""
import numpy as np, pandas as pd, rasterio
from rasterio.warp import reproject, Resampling
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt

import os; ROOT=os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))); DATA=f"{ROOT}/data"; FIG=f"{ROOT}/paper/figures"; TBL=f"{ROOT}/paper/tables"
CARBON,MRV,F = 150.0,20.0,0.88
EFF_NV = 0.0995645835337625     # t CaCO3-eq per t basalt (reference reactive)
K_BETA = 1.0                    # buffer: t CaCO3/ha per pH unit = K_BETA * ECEC  (SENSITIVITY)
PH_NEUTRAL = 6.5
CROPS=['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL',
 'POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
# EcoCrop-style upper optimal (PHOPMX) and absolute max (PHMAX) pH per crop (standard values)
PH_OPT_MAX = {'MAIZ':7.0,'SORG':7.5,'BEAN':7.0,'CHIC':8.0,'LENT':8.0,'WHEA':7.5,'BARL':7.8,
 'ACOF':6.5,'RCOF':6.5,'PMIL':7.5,'SMIL':7.5,'POTA':6.5,'SWPO':6.5,'CASS':7.0,'COWP':7.0,
 'PIGE':7.0,'SOYB':7.0,'GROU':7.0,'SUGC':7.5,'COTT':8.0,'COCO':7.0,'TEAS':5.5,'TOBA':6.5}
PH_ABS_MAX = {'MAIZ':8.0,'SORG':8.5,'BEAN':8.0,'CHIC':9.0,'LENT':9.0,'WHEA':8.5,'BARL':8.5,
 'ACOF':7.0,'RCOF':7.0,'PMIL':8.0,'SMIL':8.0,'POTA':7.5,'SWPO':7.5,'CASS':8.0,'COWP':8.0,
 'PIGE':8.0,'SOYB':8.0,'GROU':7.5,'SUGC':8.5,'COTT':8.5,'COCO':7.5,'TEAS':6.5,'TOBA':7.5}
BI={'ha':1,'agro':5,'bas':7,'cdrg':8,'cnet':9,'crev':10,'gmc':11}

with rasterio.open(f"{DATA}/economics_erw/targeted/MAIZ_equilibrium.tif") as ds:
    TR,CRS,H,W = ds.transform,ds.crs,ds.height,ds.width
def grid(path,band,how=Resampling.bilinear):
    d=np.full((H,W),np.nan,np.float32)
    with rasterio.open(path) as s:
        reproject(rasterio.band(s,band),d,src_transform=s.transform,src_crs=s.crs,dst_transform=TR,dst_crs=CRS,resampling=how)
        if s.nodata is not None: d[d==s.nodata]=np.nan
    return d
pH0 = grid(f"{DATA}/soilgrids_properties_cropland.tif",2)
ECEC= grid(f"{DATA}/soilgrids_properties_cropland.tif",9)
LR  = np.nan_to_num(grid(f"{DATA}/caco3_kamprath.tif",1,Resampling.average))   # acidity demand t CaCO3/ha
Smaint = np.nan_to_num(grid(f"{DATA}/caco3_merlos_maintenance.tif",1,Resampling.average))  # net-export sink (equil)
beta = np.maximum(K_BETA*np.nan_to_num(ECEC), 2.0)

def final_pH(A):   # A = applied alkalinity t CaCO3-eq/ha (array)
    ph = np.where(np.isfinite(pH0), pH0, 6.0).astype(np.float32)
    acid = pH0 < PH_NEUTRAL
    # acidic soils: rise toward neutral until acidity demand met, then overshoot
    frac = np.clip(np.where(LR>0.1, A/np.maximum(LR,0.1), 10.0), 0, 1)
    ph_acid = ph + frac*(PH_NEUTRAL-ph)
    surplus_acid = np.maximum(A-LR,0)
    ph_acid = np.where(A>LR, PH_NEUTRAL + surplus_acid/beta, ph_acid)
    # already-neutral/alkaline soils: any base overshoots
    ph_neu = ph + A/beta
    out = np.where(acid, ph_acid, ph_neu)
    return np.clip(out, ph, 8.5)

def ypen(final, crop):
    o,m = PH_OPT_MAX[crop], PH_ABS_MAX[crop]
    return np.where(final<=o, 1.0, np.maximum(1-((final-o)/(m-o))**2,0))

def primitives(alloc, penalize):
    z=np.zeros((H,W)); na=z.copy();nbc=z.copy();ncr=z.copy();ws=z.copy();cdrt=z.copy()
    for c in CROPS:
        with rasterio.open(f"{DATA}/economics_erw/{alloc}/{c}_equilibrium.tif") as ds:
            arr=ds.read([BI['ha'],BI['agro'],BI['bas'],BI['cdrg'],BI['cnet'],BI['crev'],BI['gmc']]).astype(np.float32); nod=ds.nodata
        if nod is not None: arr=np.where(arr==nod,np.nan,arr)
        ha,agro,bas,cdrg,cnet,crev,gmc=arr
        if penalize:
            A = np.nan_to_num(cdrg)/F          # reacted alkalinity t CaCO3-eq/ha (= gross CDR / 0.88)
            agro = agro * ypen(final_pH(A), c)
        dfn=np.isfinite(gmc)&np.isfinite(ha)&(ha>0); w=np.where(dfn,ha,0.0)
        na +=np.where(dfn,np.nan_to_num(agro)*w,0); nbc+=np.where(dfn,np.nan_to_num(bas)*w,0)
        ncr+=np.where(dfn,np.nan_to_num(crev)*w,0); ws+=w; cdrt+=np.where(dfn,np.nan_to_num(cnet)*w,0)
    ok=ws>0; wsm=np.where(ok,ws,1)
    AGRO=np.where(ok,na/wsm,np.nan); BAS=np.where(ok,nbc/wsm,np.nan); CDRN=np.where(ok,ncr/wsm,np.nan)/(CARBON-MRV)
    # net-export
    g=np.where(ok,cdrt/wsm,np.nan); phi=np.where(np.isfinite(g)&(g>0),np.maximum(1-F*Smaint/g,0),0.0)
    return dict(AGRO=AGRO,BAS=BAS,CDRN=CDRN*phi,WSUM=np.where(ok,ws,np.nan),CDRT=cdrt*phi,ok=ok)

def summ(P,m):
    S=lambda x: float(np.nansum(np.where(m,x*P['WSUM'],0)))
    return dict(area=round(float(np.nansum(np.where(m,P['WSUM'],0)))/1e6,2),
                priv=int(round(S(P['AGRO'])/1e6)),pub=int(round(S(P['CDRN']*(CARBON-MRV))/1e6)),
                cost=int(round(S(P['BAS'])/1e6)),cdr=round(float(np.nansum(np.where(m,P['CDRT'],0)))/1e6,1))

rows=[]; hump={}
for alloc in ['targeted','uniform_10','uniform_20','uniform_50']:
    for tag,pen in [('base',False),('over-lime',True)]:
        P=primitives(alloc,pen); ok=P['ok']
        priv=(P['AGRO']-P['BAS'])>0; Rc=P['CDRN']*(CARBON-MRV); comb=(P['AGRO']+Rc-P['BAS'])>0
        rows.append(dict(alloc=alloc,accounting=tag,**{'env':'Private',**summ(P,priv&ok)}))
        rows.append(dict(alloc=alloc,accounting=tag,**{'env':'Combined',**summ(P,comb&ok)}))
        if tag=='over-lime' or tag=='base':
            hump.setdefault(tag,{})[alloc]=int(round(float(np.nansum(np.where(ok,P['AGRO']*P['WSUM'],0)))/1e6))
df=pd.DataFrame(rows); df.to_csv(f"{TBL}/overliming_compare.csv",index=False)
print(df.to_string(index=False))

# hump figure: total private return ($M) vs uniform rate, base vs over-lime
xr=[0,10,20,50]  # 0 stands for targeted (lime-req)
fig,ax=plt.subplots(figsize=(7,4.4),dpi=140)
for tag,mk,lab in [('base','--o','without over-liming penalty'),('over-lime','-o','with over-liming penalty')]:
    y=[hump[tag]['targeted'],hump[tag]['uniform_10'],hump[tag]['uniform_20'],hump[tag]['uniform_50']]
    ax.plot(xr,y,mk,lw=2,label=lab)
ax.set_xticks(xr); ax.set_xticklabels(['targeted\n(lime req.)','10','20','50'])
ax.set_xlabel('Uniform application rate (t/ha)'); ax.set_ylabel('Total private return over treated land ($M)')
ax.set_title('Over-liming makes the private return hump-shaped in dose'); ax.legend(); ax.grid(alpha=0.3)
fig.tight_layout(); fig.savefig(f"{FIG}/overliming_hump.png",bbox_inches="tight"); print("saved overliming_hump.png")
