"""Check the saved illustration route, source snapshots and local links."""
from pathlib import Path
from hashlib import sha256
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids, self.links, self.targets, self.images = set(), [], [], []
        self.feed(path.read_text(encoding='utf-8'))

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a:
            assert a['id'] not in self.ids, 'Duplicate HTML id: ' + a['id']
            self.ids.add(a['id'])
        if tag == 'a' and 'href' in a:
            self.links.append(a['href'])
        if tag == 'img':
            self.images.append(a['src'])
            self.links.append(a['src'])
        if 'data-map' in a:
            self.targets.append(a['data-map'])

spec = json.loads((HERE / 'plates.json').read_text(encoding='utf-8'))['plates']
facts = json.loads((HERE / 'provenance.json').read_text(encoding='utf-8'))['plates']
selected = json.loads((HERE / 'selected-images.json').read_text(encoding='utf-8'))['plates']
assert len(spec) == len(facts) == len(selected)
assert len({p['slug'] for p in spec}) == len(spec)
assert [p['map'] for p in spec] == [p['map'] for p in facts] == [p['map'] for p in selected]
for p, f in zip(spec, facts):
    source = (ROOT / p['source']).read_bytes()
    assert sha256(source).hexdigest() == p.get('reviewed_current_source_sha256', p['source_sha256']) == f['current_source_sha256'], p['map']
    assert sha256((HERE / f['source_snapshot']).read_bytes()).hexdigest() == p['source_sha256'] == f['source_sha256'], p['map']
    assert sha256((HERE / f['image']).read_bytes()).hexdigest() == f['image_sha256'], p['map']

page = Page(HERE / 'index.html')
assert len(page.images) == len(spec)
assert set(page.targets) <= page.ids
assert set(page.ids) == {p['map'] for p in spec}
for link in page.links:
    u = urlsplit(link)
    if u.scheme or u.netloc:
        continue
    target = (HERE / unquote(u.path)).resolve() if u.path else HERE / 'index.html'
    assert target.is_file(), 'Missing local link: ' + link
    if u.fragment and target.suffix == '.html':
        assert unquote(u.fragment) in Page(target).ids, 'Missing anchor: ' + link

for sequence in dict.fromkeys(p.get('sequence', 'primitives') for p in spec):
    canonical = json.loads((ROOT / ('commons/maps/sequences/' + sequence + '.json')).read_text(encoding='utf-8'))['sequences'][sequence]['maps']
    if sequence == 'primitives':
        canonical = [m for m in canonical if m != 'Point_Zero']
    assert [p['map'] for p in spec if p.get('sequence', 'primitives') == sequence] == canonical, sequence
print(f'{len(spec)} images; draft snapshots and reviewed current-source hashes match; local links and hall navigation valid; illustrated sequence orders canonical.')
