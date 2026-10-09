"""Publication checks; these do not substitute for rendered browser interaction."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from urllib.request import urlopen
import hashlib
import json
import zipfile
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BASE = 'http://localhost:3003/book-review/' + HERE.relative_to(ROOT).as_posix() + '/'
checks = []
def check(ok, message):
    checks.append({'pass': bool(ok), 'check': message})
    if not ok:
        print('FAIL', message)

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids, self.scripts = [], set(), 0
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'script': self.scripts += 1
        if 'id' in attrs: self.ids.add(attrs['id'])
        for key in ['src', 'href']:
            if key in attrs: self.links.append(attrs[key])

page = (HERE / 'index.html').read_text(encoding='utf-8')
parser = Links()
parser.feed(page)
check(parser.scripts == 0, 'review is script-free')
for link in set(parser.links):
    part = urlsplit(link)
    if part.scheme or part.netloc or link.startswith('/'):
        continue
    file = (HERE / unquote(part.path)).resolve() if part.path else HERE / 'index.html'
    check(file.is_file(), 'local link: ' + link)
    if part.fragment and file == HERE / 'index.html':
        check(part.fragment in parser.ids, 'anchor: ' + part.fragment)
for i in range(3):
    for j in range(3):
        check(f'.comparison:has(#layout-{i}:checked):has(#colour-{j}:checked) .state-{i}-{j}' in page,
              f'CSS comparison mapping {i}/{j}')

provenance = json.loads((HERE / 'figures/provenance.json').read_text(encoding='utf-8'))
for rel, digest in provenance['source_files'].items():
    check(hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() == digest, 'captured source current: ' + rel)
with zipfile.ZipFile(HERE / 'colour-assembly-study.zip') as archive:
    for rel in provenance['source_files']:
        if rel.startswith('commons/'):
            check(archive.read(rel) == (ROOT / rel).read_bytes(), 'ZIP source exact: ' + rel)
    check('run/main_scene="res://commons/artifacts/colour_assembly/study.tscn"' in archive.read('project.godot').decode(),
          'download opens the supplied gallery')

images = sorted((HERE / 'figures').glob('*.png'))
check(len(images) == 13, '13 native captures available')
for image in images:
    with Image.open(image) as pixels:
        check(pixels.size == (1800, 1200), 'native image dimensions: ' + image.name)

native = json.loads((HERE / 'figures/verification.json').read_text(encoding='utf-8'))
check(len(native['checks']) == 46 and all(c['pass'] for c in native['checks']), 'native report: 33 behaviours plus 13 image saves pass')
registry = json.loads((ROOT / 'commons/artifacts/registry/reference_studies.json').read_text(encoding='utf-8'))['artifacts']['colour_assembly']
check(not registry['map_ready'] and not registry['include_in_map_data'], 'registry keeps study separate from installed museum')
check(registry['proposed_maps'] == ['Color_Walls'], 'proposed home recorded')
check(registry['sequence'] in json.loads((ROOT / 'commons/maps/sequences/color.json').read_text(encoding='utf-8'))['sequences'], 'registry sequence exists')

served = [HERE / 'index.html', HERE / 'colour-assembly-study.zip'] + images
served += [HERE / f for f in ['READING.md', 'MAKING.md', 'README.md', 'figures/verification.json', 'figures/provenance.json']]
for file in served:
    with urlopen(BASE + file.relative_to(HERE).as_posix(), timeout=15) as response:
        check(response.status == 200 and response.read() == file.read_bytes(), 'HTTP exact: ' + file.name)

result = {'checks': checks, 'browser': 'Automation unavailable: helper ACL failure before initialization. HTTP and static structure only; no rendered-browser claim.'}
(HERE / 'publication-verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(f'{sum(c["pass"] for c in checks)}/{len(checks)} publication checks passed')
raise SystemExit(0 if all(c['pass'] for c in checks) else 1)
