#!/usr/bin/env python3
"""Download OA PDFs for verified references into litrature/papers/."""
import json, os, time, urllib.request, urllib.parse

OUT = 'papers'
UA = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36'}
refs = json.load(open('ref-verification.json'))

def fetch(url, dest):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
    if data[:5] == b'%PDF-':
        open(dest,'wb').write(data)
        return len(data)
    return None

def all_pdf_urls(doi):
    """Every pdf_url OpenAlex knows for this work."""
    try:
        req = urllib.request.Request(f'https://api.openalex.org/works/doi:{doi}', headers={'User-Agent':'erw-ref-audit/1.0'})
        with urllib.request.urlopen(req, timeout=30) as r:
            w = json.load(r)
        urls = []
        best = w.get('best_oa_location') or {}
        if best.get('pdf_url'): urls.append(best['pdf_url'])
        for loc in w.get('locations', []):
            u = loc.get('pdf_url')
            if u and u not in urls: urls.append(u)
        return urls
    except Exception:
        return []

results = {'ok': [], 'closed': [], 'failed': []}
for e in refs:
    if e.get('status') != 'ok':
        continue
    dest = f"{OUT}/{e['ref']:03d}_{e['slug']}.pdf"
    if os.path.exists(dest):
        results['ok'].append((e['ref'], e['slug'], 'cached')); continue
    urls = []
    if e.get('oa_pdf'): urls.append(e['oa_pdf'])
    urls += [u for u in all_pdf_urls(e['doi']) if u not in urls]
    got = False
    for u in urls:
        try:
            n = fetch(u, dest)
            if n:
                results['ok'].append((e['ref'], e['slug'], f'{n//1024} KB'))
                got = True
                break
        except Exception:
            continue
        time.sleep(0.3)
    if not got:
        (results['closed'] if not e.get('is_oa') else results['failed']).append((e['ref'], e['slug']))
    time.sleep(0.4)

print(f"downloaded: {len(results['ok'])}")
for r in results['ok']: print('  OK', *r)
print(f"\nOA but download failed: {len(results['failed'])}")
for r in results['failed']: print('  FAIL', *r)
print(f"\nclosed access (no legal OA copy): {len(results['closed'])}")
for r in results['closed']: print('  CLOSED', *r)
