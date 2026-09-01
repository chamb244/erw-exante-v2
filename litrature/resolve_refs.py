#!/usr/bin/env python3
"""Resolve priority ESROC references to DOIs + OA PDF URLs.
Outputs litrature/ref-resolution.json + a review table ref-resolution.tsv."""
import json, re, time, urllib.request, urllib.parse, sys

refs = json.load(open('ew-esroc-refs.json'))

# (ref_num, slug, topic) — curated from the five section reports
WANTED = [
    # stoichiometry / CDR ceiling
    (126,'renforth2019-natcomm','stoichiometry: eta=1.5, Steinour'),
    (18,'renforth2012-ijggc','stoichiometry: modified Steinour, thermo ocean bound'),
    (37,'renforth-henderson2017-revgeo','ocean storage, 15-20% loss, 0.8 charge ratio'),
    (125,'lewis2021-appgeo','basalt 6x CDR spread, reactivity, Cr/Ni'),
    (132,'moller-dupla-appgeo','basalt bulk-chemistry data quality'),
    # global/regional potentials
    (19,'beerling2020-nature','0.5-2 Gt/yr, national cost curves'),
    (23,'strefler2018-erl','basalt $200 vs dunite $60, grinding-p80, 4.9Gt'),
    (24,'baek2023-earthsfuture','Africa 1.2-1.6 tCO2/ha/yr, SCEPTER'),
    (245,'tu2026-commsust','tropical hotspots, income-group shares'),
    (517,'chen2023-stoten','0.22 Gt/yr calibrated lower bound'),
    (14,'hartmann-kempe2008','0.24 Gt/yr empirical bound'),
    (17,'kohler2010-pnas','olivine 3.7 Gt/yr'),
    (22,'beerling2025-nature','US corn belt acidity/pH projection'),
    (20,'kantzas2022-natgeo','UK RTM, pedogenic carbonate fig'),
    # kinetics / pH / temperature
    (221,'brantley2023-science','Arrhenius T control'),
    (58,'deng2022-natcomm','T/runoff dependence'),
    (56,'white-blum1995-gca','natural watershed T dependence'),
    (222,'pvstrandmann2022-frontclim','low-T dissolution rates'),
    (223,'iff2024-frontclim','T dependence + Ni'),
    (225,'white-brantley2003-chemgeo','lab-field rate gap'),
    (59,'west2012-geology','supply vs kinetic limitation'),
    (238,'maher-chamberlain2014-science','hydrologic control'),
    (239,'maher2010-epsl','residence time control'),
    (214,'bertagni-porporato2022-stoten','alkalinisation capture efficiency (pH factor)'),
    (161,'power2025-frontclim','low-pH CO2 speciation, dose decline'),
    (216,'holden2024-stoten','tropical acidity obviates CDR, 98% strong-acid'),
    # grain size
    (182,'rimstidt2012-gca','SSA-rate relations'),
    (184,'renforth2015-appgeo','GSA vs BET'),
    (208,'harrington2024-stoten','grain size not independent predictor'),
    (65,'harrington2023-appgeo','river carbonate 16-27% loss'),
    (164,'gillman2002-appgeo','basalt dust CEC plateau 10-25 t/ha'),
    # dose / application
    (75,'goll2021-natgeo','CDR efficiency declines with rate'),
    (172,'calabrese-erw','dose saturation modelling'),
    # net-export / losses / lags
    (68,'kanzaki-lag-erl','CEC/BS lag years-decades — KEY for lambda'),
    (354,'hamilton2007-gbc','liming CO2 charge balance — F provenance'),
    (29,'west-mcbride2005-aee','ag lime emission factor'),
    (231,'dietzen-rosing2023-ijggc','conservative strong-acid proxy'),
    (357,'brantley2025-revgeo','rates fall 10-100x over 10yr'),
    (66,'zhang-river-erl','river degassing <5%/>15%'),
    (31,'raymond2025-natwater','SIC redissolution recovers penalty'),
    (275,'zhang-carrying-capacity','riverine carrying capacity'),
    (372,'chiquier2022-ees','CDR payback timescales'),
    (353,'kantola2023-gcb','lysimeter strong-acid 0.1-1.8%, plant uptake'),
    (298,'zamanian2016-esr','pedogenic carbonate review'),
    (286,'huang-globalsic','global SIC aridity'),
    (111,'klemme2022-cee','tropical peat CO2 offset'),
    (434,'reershemius-suhrhoff2023-gcb','Kantola CDR indistinguishable from zero'),
    (435,'derry2025-gcb','field CDR uncertainty'),
    # agronomy
    (93,'xu2025-gcb','SOC meta-analysis +3.8%'),
    (42,'wang2021-gcb','liming SOC meta-analysis'),
    (47,'swoboda2022-stoten','rock dust agronomy review'),
    (650,'vonuexkull-mutert1995','30% acid soils global'),
    (620,'vanstraaten2002-rocksforcrops','SSA agrominerals book'),
    (556,'haque2024-kenya','Kenya smallholder +$326/ha'),
    (444,'beerling-cornbelt','US corn belt field trial yield/NUE'),
    (388,'ramos2022-geoscifront','maize field yield 1.1-1.7x'),
    (129,'dupla2023-ejss','heavy metals thresholds/accumulation'),
    (98,'tepas2023-frontclim','olivine Ni groundwater limits'),
    # costs / LCA / MRV
    (542,'mercer2024-gri','MRV cost $15-71'),
    (133,'madankan-renforth2023-ijggc','basalt production/reserves'),
    (543,'li2024-frontclim','grinding cost $/t'),
    (428,'zhang-transport-est','transport-dominated LCA'),
    (544,'kroeger2026-est','co-benefits N2O into LCA/TEA'),
    (209,'lefebvre-lca','ERW LCA Brazil'),
    (408,'moosdorf2014-est','transport LCA global'),
    (414,'taylor2015-natcc','spreading-dominated cost'),
    (559,'oppon2023-ecolecon','Global South distributional'),
    # modelling frameworks
    (110,'kanzaki2022-gmd-scepter','SCEPTER model'),
    (252,'bertagni-smew-james','SMEW model'),
]

def http_json(url):
    req = urllib.request.Request(url, headers={'User-Agent':'erw-exante-ref-audit/1.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

out = []
for num, slug, topic in WANTED:
    cit = refs.get(str(num), '')
    doi = None
    m = re.search(r'DOI[:\s]*(10\.\S+?)(?:\.|,|;|\s|$)', cit, re.I)
    if m:
        doi = m.group(1).rstrip('.,;')
    entry = {'ref': num, 'slug': slug, 'topic': topic, 'citation': cit, 'doi_in_text': doi}
    if not doi:
        q = urllib.parse.quote(cit[:250])
        try:
            j = http_json(f'https://api.crossref.org/works?query.bibliographic={q}&rows=3')
            items = j['message']['items']
            entry['crossref_candidates'] = [
                {'doi': it.get('DOI'), 'title': (it.get('title') or [''])[0][:120],
                 'year': (it.get('issued',{}).get('date-parts',[[None]])[0][0]),
                 'container': (it.get('container-title') or [''])[0][:60],
                 'author1': (it.get('author',[{}])[0].get('family','') if it.get('author') else ''),
                 'score': it.get('score')}
                for it in items]
        except Exception as e:
            entry['crossref_error'] = str(e)
        time.sleep(0.4)
    out.append(entry)
    print(f"{num} {slug}: {'DOI in text: '+doi if doi else 'crossref: ' + (entry.get('crossref_candidates',[{}])[0].get('doi','FAILED') if entry.get('crossref_candidates') else 'FAILED')}", flush=True)

json.dump(out, open('ref-resolution.json','w'), indent=1)
print(f"\n{len(out)} refs processed -> ref-resolution.json")
