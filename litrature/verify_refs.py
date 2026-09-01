#!/usr/bin/env python3
"""Verify resolved DOIs against OpenAlex; record title/year/OA pdf url."""
import json, time, urllib.request, re

data = json.load(open('ref-resolution.json'))

# manual overrides for known-bad resolutions
OVERRIDES = {
 132: '10.1016/j.apgeochem.2025.106630',   # Moller & Dupla, Appl. Geochem. basalt data quality
 428: None,  # Zhang/Kroeger/Planavsky/Yao ES&T transport — resolve by search below
 542: 'REPORT:https://www.lse.ac.uk/granthaminstitute/publication/towards-improved-cost-estimates-for-monitoring-reporting-and-verification-of-carbon-dioxide-removal/',
 556: None,  # Haque Kenya — search
 620: 'BOOK:https://apps.worldagroforestry.org/downloads/Publications/PDFS/B13327.pdf',  # van Straaten Rocks for Crops
}

def oa_get(url):
    req = urllib.request.Request(url, headers={'User-Agent':'erw-ref-audit/1.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def openalex_by_doi(doi):
    try:
        return oa_get(f'https://api.openalex.org/works/doi:{doi}')
    except Exception as e:
        return {'error': str(e)}

def openalex_search(q, yr=None):
    u = f'https://api.openalex.org/works?search={urllib.parse.quote(q)}&per-page=3'
    try:
        return oa_get(u).get('results', [])
    except Exception as e:
        return []

import urllib.parse
results = []
for e in data:
    num = e['ref']
    doi = e.get('doi_in_text')
    if not doi and e.get('crossref_candidates'):
        doi = e['crossref_candidates'][0]['doi']
    if num in OVERRIDES:
        ov = OVERRIDES[num]
        if ov and ov.startswith(('REPORT:', 'BOOK:')):
            results.append({'ref': num, 'slug': e['slug'], 'doi': None, 'kind': ov.split(':',1)[0].lower(),
                            'url': ov.split(':',1)[1], 'title': e['citation'][:100], 'status': 'manual-url'})
            continue
        doi = ov
    if not doi:
        # search OpenAlex by citation text keywords
        r = {'ref': num, 'slug': e['slug'], 'doi': None, 'status': 'needs-search', 'citation': e['citation'][:160]}
        results.append(r)
        continue
    w = openalex_by_doi(doi)
    if 'error' in w:
        results.append({'ref': num, 'slug': e['slug'], 'doi': doi, 'status': 'doi-not-found', 'citation': e['citation'][:160]})
        continue
    auth1 = (w.get('authorships') or [{}])[0].get('author',{}).get('display_name','')
    loc = w.get('best_oa_location') or {}
    results.append({'ref': num, 'slug': e['slug'], 'doi': doi,
        'title': w.get('display_name'), 'year': w.get('publication_year'),
        'venue': ((w.get('primary_location') or {}).get('source') or {}).get('display_name'),
        'author1': auth1, 'is_oa': (w.get('open_access') or {}).get('is_oa'),
        'oa_pdf': loc.get('pdf_url'), 'oa_page': loc.get('landing_page_url'),
        'status': 'ok', 'citation_snippet': e['citation'][:110]})
    time.sleep(0.25)

json.dump(results, open('ref-verification.json','w'), indent=1)
# print compact review table
for r in results:
    if r['status'] == 'ok':
        oa = 'PDF' if r.get('oa_pdf') else ('oa-page' if r.get('is_oa') else 'CLOSED')
        print(f"{r['ref']:>4} {r['slug'][:34]:<34} {str(r.get('year')):<5} {oa:<7} {r.get('author1','')[:18]:<18} {str(r.get('title'))[:75]}")
    else:
        print(f"{r['ref']:>4} {r['slug'][:34]:<34} {r['status'].upper()}  {r.get('citation','')[:80]}")
