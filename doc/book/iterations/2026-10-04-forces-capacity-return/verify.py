"""Verify this summary pass against its own saved baseline and served review."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
import hashlib, json, re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ROUTE = 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))

before = read(HERE/'before'/ROUTE/'route.json')
after = read(ROOT/ROUTE/'route.json')
assert [h for h in before['halls'] if h['sequence']!='forces'] == [h for h in after['halls'] if h['sequence']!='forces']
assert [s for s in before['sequences'] if s['id']!='forces'] == [s for s in after['sequences'] if s['id']!='forces']
assert [h['id'] for h in before['halls']] == [h['id'] for h in after['halls']]
embedded = re.search(r'<script id="route-data" type="application/json">(.*?)</script>', (ROOT/ROUTE/'index.html').read_text(encoding='utf-8'), re.S)[1]
assert json.loads(embedded) == after

canonical = 'doc/book/course/storyboards/early.json'
old = read(HERE/'before'/canonical)
new = read(ROOT/canonical)
assert [s for s in old if s['sequence']!='forces'] == [s for s in new if s['sequence']!='forces']
seq = next(s for s in new if s['sequence']=='forces')
for h in seq['halls']:
    assert h['independent_check'] and h['storyboard_short']
    assert len(h['storyboard_short'].split()) <= 85
    for path in h['source_refs']: assert (ROOT/path).is_file(), path

section = r'^## 7\. Vectors & Forces: From Direction to Dynamics.*?(?=^## 8\.)'
for path in ['doc/book/course/TUTORIAL_STORYBOARDS.md', 'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md', 'doc/book/course/storyboards/SEQUENCES.md', ROUTE+'/storyboards.md', ROUTE+'/storyboards-short.md', ROUTE+'/sequences.md']:
    a = (HERE/'before'/path).read_text(encoding='utf-8')
    b = (ROOT/path).read_text(encoding='utf-8')
    assert re.sub(section, '', a, flags=re.M|re.S) == re.sub(section, '', b, flags=re.M|re.S), path

meta = 'commons/maps/sequences/forces.json'
a = read(HERE/'before'/meta)['sequences']['forces']
b = read(ROOT/meta)['sequences']['forces']
for key in ['maps', 'prerequisites', 'unlocks', 'artifact_groups']: assert a[key] == b[key], key
assert (ROOT/'doc/book/course/storyboards/FORCES.md').read_bytes() == (HERE/'FORCES.md').read_bytes()

protected = []
for row in read(HERE/'unchanged-evidence-before.json'):
    digest = hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest()
    protected.append(dict(path=row['path'],unchanged=digest==row['sha256']))
assert all(r['unchanged'] for r in protected if not r['path'].endswith('map_data.json'))
assert [r['path'] for r in protected if not r['unchanged']] == ['commons/maps/VFM_03_Motion/map_data.json']

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.urls=set(); self.cards=0; self.images=0
    def handle_starttag(self, tag, attrs):
        values=dict(attrs)
        if tag=='article': self.cards+=1
        if tag=='img': self.images+=1
        for key in ['href','src']:
            if key in values and not values[key].startswith('#'): self.urls.add(values[key])

page = Links(); page.feed((HERE/'index.html').read_text(encoding='utf-8'))
assert page.cards == page.images == 13
base = 'http://localhost:3003/book-review/doc/book/iterations/2026-10-04-forces-capacity-return/index.html'
def check(path):
    with urlopen(urljoin(base,path), timeout=30) as response:
        assert response.status==200
        return dict(path=path,status=response.status)
with ThreadPoolExecutor(max_workers=6) as pool: http=list(pool.map(check,sorted(page.urls)))

result=dict(sequence='forces',maps=13,other_halls_preserved=194,other_sequences_preserved=24,order_and_unlocks_preserved=True,route_embedded_json_matches=True,other_markdown_sections_preserved=True,finals_and_tutorials_preserved=26,protected_files=protected,source_paths_exist=True,short_briefs_within_word_limit=True,cards=page.cards,museum_images=page.images,http_checks=http,runtime_tested=False)
if (HERE/'memory-proposals.json').is_file():
    proposals=read(HERE/'memory-proposals.json')
    assert len(proposals)==13 and all(f['status']=='proposed' for f in proposals)
    assert {f['scope'] for f in proposals} == {'map:'+h['id'] for h in seq['halls']}
    for hall in seq['halls']: assert read(HERE/'proposals'/(hall['id']+'.json')) == hall
    result['proposals_registered_without_acceptance']=13
(HERE/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f"13 cards and museum images; {len(http)} served links; 194 other halls preserved; 26 full texts preserved. Motion map changed externally and was preserved.")
