#!/usr/bin/env python3
"""Over-liming penalty SENSITIVITY band over the two uncertain parameters:
 - k_beta: soil buffer (t CaCO3/ha per pH unit = k_beta * ECEC)
 - m_A   : realized-alkalinity multiplier on A = gross_CDR/0.88
Scenarios: LOW penalty (m_A=0.5, k_beta=2.0), CENTRAL (1.0,1.0), HIGH (1.5,0.5).
Efficient: reads each raster once, applies all scenarios."""
import numpy as np, pandas as pd, rasterio
from rasterio.warp import reproject, Resampling
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
import os; ROOT=os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))); DATA=f"{ROOT}/data"; FIG=f"{ROOT}/paper/figures"; TBL=f"{ROOT}/paper/tables"
CARBON,MRV,F=150.0,20.0,0.88; PH_NEUTRAL=6.5
CROPS=['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL','POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
PH_OPT_MAX={'MAIZ':7.0,'SORG':7.5,'BEAN':7.0,'CHIC':8.0,'LENT':8.0,'WHEA':7.5,'BARL':7.8,'ACOF':6.5,'RCOF':6.5,'PMIL':7.5,'SMIL':7.5,'POTA':6.5,'SWPO':6.5,'CASS':7.0,'COWP':7.0,'PIGE':7.0,'SOYB':7.0,'GROU':7.0,'SUGC':7.5,'COTT':8.0,'COCO':7.0,'TEAS':5.5,'TOBA':6.5}
PH_ABS_MAX={'MAIZ':8.0,'SORG':8.5,'BEAN':8.0,'CHIC':9.0,'LENT':9.0,'WHEA':8.5,'BARL':8.5,'ACOF':7.0,'RCOF':7.0,'PMIL':8.0,'SMIL':8.0,'POTA':7.5,'SWPO':7.5,'CASS':8.0,'COWP':8.0,'PIGE':8.0,'SOYB':8.0,'GROU':7.5,'SUGC':8.5,'COTT':8.5,'COCO':7.5,'TEAS':6.5,'TOBA':7.5}
SCEN={'low':(0.5,2.0),'central':(1.0,1.0),'high':(1.5,0.5)}   # (m_A, k_beta)
with rasterio.open(f"{DATA}/economics_erw/targeted/MAIZ_equilibrium.tif") as ds: TR,CRS,H,W=ds.transform,ds.crs,ds.height,ds.width
def grid(p,b,how=Resampling.bilinear):
    d=np.full((H,W),np.nan,np.float32)
    with rasterio.open(p) as s:
        reproject(rasterio.band(s,b),d,src_transform=s.transform,src_crs=s.crs,dst_transform=TR,dst_crs=CRS,resampling=how)
        if s.nodata is not None: d[d==s.nodata]=np.nan
    return d
pH0=grid(f"{DATA}/soilgrids_properties_cropland.tif",2); ECEC=np.nan_to_num(grid(f"{DATA}/soilgrids_properties_cropland.tif",9))
LR=np.nan_to_num(grid(f"{DATA}/caco3_kamprath.tif",1,Resampling.average)); Smaint=np.nan_to_num(grid(f"{DATA}/caco3_merlos_maintenance.tif",1,Resampling.average))
def final_pH(A,kbeta):
    beta=np.maximum(kbeta*ECEC,1.0); ph=np.where(np.isfinite(pH0),pH0,6.0).astype(np.float32); acid=pH0<PH_NEUTRAL
    frac=np.clip(np.where(LR>0.1,A/np.maximum(LR,0.1),10.0),0,1); ph_a=ph+frac*(PH_NEUTRAL-ph)
    ph_a=np.where(A>LR,PH_NEUTRAL+np.maximum(A-LR,0)/beta,ph_a); ph_n=ph+A/beta
    return np.clip(np.where(acid,ph_a,ph_n),ph,8.5)
def ypen(final,c):
    o,m=PH_OPT_MAX[c],PH_ABS_MAX[c]; return np.where(final<=o,1.0,np.maximum(1-((final-o)/(m-o))**2,0))
rows=[]
for alloc in ['targeted','uniform_10','uniform_20','uniform_50']:
    z=np.zeros((H,W)); nbc=z.copy();ws=z.copy();cdrt=z.copy()
    na={s:z.copy() for s in ['base']+list(SCEN)}
    for c in CROPS:
        with rasterio.open(f"{DATA}/economics_erw/{alloc}/{c}_equilibrium.tif") as ds:
            ha,agro,bas,cdrg,cnet=ds.read([1,5,7,8,9]).astype(np.float32); nod=ds.nodata; gmc=ds.read(11).astype(np.float32)
        if nod is not None:
            for a in [ha,agro,bas,cdrg,cnet,gmc]: a[a==nod]=np.nan
        dfn=np.isfinite(gmc)&np.isfinite(ha)&(ha>0); w=np.where(dfn,ha,0.0); A0=np.nan_to_num(cdrg)/F
        nbc+=np.where(dfn,np.nan_to_num(bas)*w,0); ws+=w; cdrt+=np.where(dfn,np.nan_to_num(cnet)*w,0)
        na['base']+=np.where(dfn,np.nan_to_num(agro)*w,0)
        for s,(mA,kb) in SCEN.items():
            pen=np.nan_to_num(agro)*ypen(final_pH(A0*mA,kb),c)
            na[s]+=np.where(dfn,pen*w,0)
    ok=ws>0; wsm=np.where(ok,ws,1); BAS=np.where(ok,nbc/wsm,np.nan)
    g=np.where(ok,cdrt/wsm,np.nan); phi=np.where(np.isfinite(g)&(g>0),np.maximum(1-F*Smaint/g,0),0.0)
    for s in ['base']+list(SCEN):
        AGRO=np.where(ok,na[s]/wsm,np.nan); m=((AGRO-BAS)>0)&ok
        rows.append(dict(alloc=alloc,scenario=s,priv_M=int(round(float(np.nansum(np.where(m,AGRO*ws,0)))/1e6)),
                         area_Mha=round(float(np.nansum(np.where(m,ws,0)))/1e6,2)))
df=pd.DataFrame(rows); df.to_csv(f"{TBL}/overliming_sensitivity.csv",index=False)
piv=df.pivot(index='alloc',columns='scenario',values='priv_M').reindex(['targeted','uniform_10','uniform_20','uniform_50'])
print(piv.to_string());
for a in piv.index:
    b=piv.loc[a,'base']; print(f"{a}: reduction {100*(1-piv.loc[a,'high']/b):.0f}% (high) .. {100*(1-piv.loc[a,'low']/b):.0f}% (low), central {100*(1-piv.loc[a,'central']/b):.0f}%")
# band figure
labs=['targeted\n(lime req.)','uniform 10','uniform 20','uniform 50']; x=np.arange(4)
base=piv['base'].values; lo=piv['low'].values; hi=piv['high'].values; ce=piv['central'].values
fig,ax=plt.subplots(figsize=(7.5,4.6),dpi=140)
ax.plot(x,base,'--o',color='#4477aa',lw=2,label='no penalty (base)')
ax.plot(x,ce,'-o',color='#e8843c',lw=2,label='over-liming, central')
ax.fill_between(x,hi,lo,color='#e8843c',alpha=0.22,label='sensitivity band (low–high)')
ax.set_xticks(x); ax.set_xticklabels(labs,fontsize=9); ax.set_ylabel('Private return ($M)'); ax.grid(axis='y',alpha=0.3)
ax.set_title('Over-liming penalty on the private return: central estimate and sensitivity band'); ax.legend(fontsize=9)
fig.tight_layout(); fig.savefig(f"{FIG}/overliming_sensitivity.png",bbox_inches='tight'); print('saved overliming_sensitivity.png')
