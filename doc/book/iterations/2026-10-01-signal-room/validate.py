"""Verify publication and portable source chain without mutating the project."""
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urljoin, urlparse, unquote
from zipfile import ZipFile
from bs4 import BeautifulSoup
from PIL import Image
import hashlib
import json
import re

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
KIT=ROOT/'doc/book/studies/signal-room'
URL='http://localhost:3003/book-review/doc/book/iterations/2026-10-01-signal-room/index.html'
checks=[]
def check(name,passed):
    checks.append(dict(name=name,passed=bool(passed)))
    if not passed:
        print('FAIL',name)
def sha(data):
    return hashlib.sha256(data).hexdigest()

page=(HERE/'index.html').read_bytes()
soup=BeautifulSoup(page,'html.parser')
check('Review uses no scripts or external stylesheets',not soup.find_all('script') and not soup.find_all('link',rel='stylesheet'))
ids={node['id'] for node in soup.select('[id]')}
for link in soup.select('a[href],img[src]'):
    value=link.get('href') or link.get('src')
    if value.startswith('#'):
        check('Anchor '+value,value[1:] in ids)
    elif not value.startswith(('http','/')):
        check('Local target '+value,(HERE/unquote(urlparse(value).path)).is_file())
for label in soup.select('label[for]'):
    check('Radio label '+label['for'],label['for'] in ids)
for mode in ['repeat','rows','cells']:
    choice=soup.find(id=mode)
    check('Accessible radio '+mode,choice and choice.get('type')=='radio' and choice.get('name')=='rule')
for image in soup.select('img'):
    check('Image alt '+image['src'],bool(image.get('alt')))
    if image['src']!='reference.png':
        check('Native image dimensions '+image['src'],Image.open(HERE/image['src']).size==(1600,1000))

report=json.loads((HERE/'verification.json').read_text())
check('Native report complete and passing',len(report['checks'])==39 and report['failures']==0 and all(c['passed'] for c in report['checks']))
log=(HERE/'native.log').read_text()
check('Native log contains no errors',not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error|FAIL ',log))
for row in json.loads((HERE/'source-hashes.json').read_text()):
    check('Canonical hash '+row['source'],sha((ROOT/row['source']).read_bytes())==row['source_sha256'])
    check('Portable hash '+row['portable'],sha((KIT/row['portable']).read_bytes())==row['portable_sha256'])
    original=(ROOT/row['source']).read_text()
    for other in json.loads((HERE/'source-hashes.json').read_text()):
        original=original.replace('res://'+other['source'],'res://'+other['portable'])
    check('Only resource paths differ '+row['portable'],original==(KIT/row['portable']).read_text())

with ZipFile(HERE/'different-neighbours.zip') as archive:
    archive_hashes=json.loads((HERE/'archive-hashes.json').read_text())
    check('ZIP contains only manifested files',len(archive.namelist())==len(archive_hashes))
    for name,digest in archive_hashes.items():
        data=archive.read('different-neighbours/'+name)
        check('ZIP hash '+name,sha(data)==digest and data==(KIT/name).read_bytes())
        if name.endswith(('.gd','.tscn','.godot')):
            for resource in re.findall(r'res://([A-Za-z_./0-9-]+)',data.decode()):
                if resource == 'captures' or resource.startswith('captures/'):
                    continue
                check('Portable dependency '+resource,'different-neighbours/'+resource in archive.namelist())
registry=json.loads((ROOT/'commons/artifacts/registry/signal_room.json').read_text())['artifacts']['signal_room']
check('Registry names existing canonical scene',(ROOT/registry['scene'].removeprefix('res://')).is_file())
check('Registry does not imply museum placement',registry['map_ready'] is False and registry['include_in_map_data'] is False)
keys=[]
for path in (ROOT/'commons/artifacts/registry').glob('*.json'):
    data=json.loads(path.read_text(encoding='utf-8-sig'))
    if 'signal_room' in data.get('artifacts',{}):
        keys.append(path)
check('One canonical registry key',len(keys)==1)

with urlopen(URL,timeout=10) as response:
    check('HTTP serves exact review bytes',response.read()==page)
    check('Script-free page suits server CSP',"default-src 'none'" in response.headers.get('Content-Security-Policy',''))
for name in ['repeat.png','rows.png','cells.png','sample.png','different-neighbours.zip','verification.json']:
    with urlopen(urljoin(URL,name),timeout=10) as response:
        check('HTTP serves exact '+name,response.read()==(HERE/name).read_bytes())
failures=sum(not check['passed'] for check in checks)
(HERE/'publication-checks.json').write_text(json.dumps(dict(checks=checks,failures=failures),indent=2)+'\n')
print(f'{len(checks)} publication checks, {failures} failures')
raise SystemExit(1 if failures else 0)
