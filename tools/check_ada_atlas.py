"""Check the published atlas against independent live sources and native image files."""
from pathlib import Path
import hashlib
import json
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/research/ada-relations'
read = lambda p: json.loads(p.read_text(encoding='utf-8'))
data = read(PUBLIC / 'atlas.json')
plan = {h['id']: h for h in read(ROOT / 'doc/book/course/execution-plan/plan.json')['lessons']}
spine = sorted(read(ROOT / 'commons/maps/curriculum_spine.json')['spine']['sequences'], key=lambda x: x['order'])
expected = []
for s in spine:
    expected.extend(read(ROOT / f"commons/maps/sequences/{s['name']}.json")['sequences'][s['name']]['maps'])
checks = []


def check(name, ok):
    checks.append({'name': name, 'passed': bool(ok)})
    assert ok, name


check('Every hall follows the independently read current spine exactly once', expected == [h['id'] for h in data['halls']] and len(expected) == len(set(expected)))
check('No relationship source is stale at publication', not data['imageView']['staleRelationSources'])
check('Every caption preserves the current carry declaration', all(h['carry'] == plan[h['id']]['carry'].strip() for h in data['halls']))
check('Every next-hall link follows the actual spine, including boundaries', all(h['next'] == (expected[i+1] if i+1 < len(expected) else None) for i,h in enumerate(data['halls'])))
check('All captions remain short, at most 40 words', all(len(h['carry'].split()) <= 40 for h in data['halls']))
check('Text links exist, and absent files are explicitly marked', all(bool(h[field]) == (ROOT / f"commons/maps/{h['id']}/{name}.md").exists() for h in data['halls'] for field,name in [('tutorial','tutorial'),('reflection','final')]))
photos = {p['src']: p for h in data['halls'] for p in [h['photo'],h['above']] if p}
for photo in photos.values():
    source = ROOT / photo['source']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == photo['sha256'], source
    assert (ROOT / photo['evidence']).exists(), photo
    with Image.open(PUBLIC / photo['src']) as im:
        assert im.width > 0 and im.height > 0
check('Every delivered image has an existing original, exact hash and capture evidence', True)
check('The only capture gap is exposed rather than replaced by another hall', [h['id'] for h in data['halls'] if not h['photo']] == ['Lab_Path'] and next(h for h in data['halls'] if h['id']=='Lab_Path').get('captureGap'))
check('Original references remain, with the two source-checked cultural-data examples', {r['id'] for r in data['references']} == {'manovich','hahm','donovan','saraceno','lozano-hemmer','shiota','lombardi','ghostcatching','salavon'})
check('Reference applications and limits are explicit', all(r['application'] and r['limit'] and r['url'].startswith('https://') for r in data['references']))
check('Unverified Hahm attribution remains marked', 'unresolved' in next(r for r in data['references'] if r['name']=='Jun Seo Hahm')['status'])
check('Network references are Lombardi, Saraceno and Shiota', {r['id'] for r in data['references'] if r['group']=='networks'} == {'lombardi','saraceno','shiota'})
by_hall = {h['id']: h for h in data['halls']}
check('Every reference links to specific current halls with a reason and source', all(
    r['halls'] and set(r['sequences']) == {by_hall[h['id']]['sequence'] for h in r['halls']} and
    all(h['reason'] and (ROOT / h['basis']).is_file() for h in r['halls']) for r in data['references']))
check('Accumulation, recordings and gait references are connected outside Graph Theory', all('graphtheory' not in r['sequences'] for r in data['references'] if r['group']=='across-spine'))
check('Art readings and questions remain separate from descriptions and applications', all(r['reading'] and r['question'] and r['fact'] != r['reading'] for r in data['references']))
check('The reading method returns to existing halls with inspectable sources', all(r['hall'] in by_hall and (ROOT / r['basis']).is_file() for r in data['readingMethod']['returns']))
html = (PUBLIC / 'index.html').read_text(encoding='utf-8')
embedded = re.search(r'<script id="atlas-data" type="application/json">(.*?)</script>', html, re.S).group(1)
check('Page data and inspectable JSON agree', json.loads(embedded) == data)


def request(path):
    with urllib.request.urlopen('http://localhost:3003/research/ada-relations/' + path, timeout=15) as response:
        assert response.status == 200, path
        return response.headers.get('Content-Type','')


with ThreadPoolExecutor(max_workers=8) as pool:
    types = list(pool.map(request, photos))
check('All image URLs return HTTP 200 as images', all(t.startswith('image/') for t in types))
check('Live page and JSON return HTTP 200', 'text/html' in request('index.html') and 'json' in request('atlas.json'))
result = {'passed': True, 'checks': checks, 'halls': len(expected), 'photographed_halls': sum(h['photo'] is not None for h in data['halls']), 'image_files_checked': len(photos), 'scope': 'Data, source provenance, files and HTTP delivery; browser interaction separately recorded. No runtime tutorial or headset claim.'}
(ROOT / 'doc/book/course/atlas/checks.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k != 'checks'}))
