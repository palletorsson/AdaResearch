"""Check published files and provenance without claiming browser rendering."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from urllib.request import urlopen
import hashlib, json, zipfile
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BASE = 'http://localhost:3003/book-review/' + HERE.relative_to(ROOT).as_posix() + '/'
checks = []
def check(ok, text):
    checks.append({'pass':bool(ok),'check':text})
    if not ok: print('FAIL',text)
class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids, self.scripts = [], set(), 0
    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        if tag == 'script': self.scripts += 1
        if 'id' in attr: self.ids.add(attr['id'])
        for key in ['src','href']:
            if key in attr: self.links.append(attr[key])
page = Page()
page.feed((HERE/'index.html').read_text(encoding='utf-8'))
check(page.scripts == 0,'script-free review')
for link in set(page.links):
    part = urlsplit(link)
    if part.scheme or part.netloc or link.startswith('/'): continue
    file = (HERE/unquote(part.path)).resolve() if part.path else HERE/'index.html'
    check(file.is_file(),'local link '+link)
    if part.fragment and file == HERE/'index.html': check(part.fragment in page.ids,'anchor '+part.fragment)
for name in ['intervals','crossings','line','colour']:
    check(name+'-second' in page.ids,'comparison choice '+name)
proof = json.loads((HERE/'figures/provenance.json').read_text(encoding='utf-8'))
with zipfile.ZipFile(HERE/'wall-relations-study.zip') as archive:
    for rel, digest in proof['source_files'].items():
        data = (ROOT/rel).read_bytes()
        check(hashlib.sha256(data).hexdigest() == digest,'captured source '+rel)
        if rel.startswith('commons/'): check(archive.read(rel) == data,'ZIP source '+rel)
    check('colour_wall_studies/study.tscn' in archive.read('project.godot').decode(),'download main scene')
native = json.loads((HERE/'figures/verification.json').read_text(encoding='utf-8'))
check(len(native['checks']) == 31 and all(c['pass'] for c in native['checks']),'19 behaviours and 12 saves pass')
images = sorted((HERE/'figures').glob('*.png'))
check(len(images) == 12,'twelve captures')
for file in images:
    with Image.open(file) as im: check(im.size == (1800,1200),'image '+file.name)
reg = json.loads((ROOT/'commons/artifacts/registry/reference_studies.json').read_text(encoding='utf-8'))['artifacts']['colour_wall_studies']
check(reg['sequence'] == 'color' and reg['proposed_maps'] == ['Color_Walls'],'proposed Colour home')
check(not reg['map_ready'] and not reg['include_in_map_data'],'companion registration')
for file in images+[HERE/f for f in ['index.html','wall-relations-study.zip','README.md','READING.md','MAKING.md','figures/provenance.json','figures/verification.json']]:
    with urlopen(BASE+file.relative_to(HERE).as_posix(),timeout=15) as response:
        check(response.status == 200 and response.read() == file.read_bytes(),'HTTP exact '+file.name)
(HERE/'publication-verification.json').write_text(json.dumps({'checks':checks,'scope':'Static publication, HTTP bytes, source provenance and ZIP. No rendered browser claim.'},indent=2)+'\n',encoding='utf-8')
print(f'{sum(c["pass"] for c in checks)}/{len(checks)} publication checks passed')
raise SystemExit(0 if all(c['pass'] for c in checks) else 1)
