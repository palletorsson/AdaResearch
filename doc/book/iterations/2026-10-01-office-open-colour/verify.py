"""Check publication assets and the exact scope of the installed map change."""
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urljoin, urlparse
import hashlib
import json
from bs4 import BeautifulSoup

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
URL = 'http://localhost:3003/book-review/'+HERE.relative_to(ROOT).as_posix()+'/index.html'
checks = []
def check(name, condition):
    checks.append({'name':name,'passed':bool(condition)})
    assert condition, name

report = json.loads((HERE/'report.json').read_text(encoding='utf-8'))
check('47 native checks passed',report['passed'] and len(report['checks'])==47)
source_hashes = json.loads((HERE/'source-hashes.json').read_text(encoding='utf-8'))
for name, expected in source_hashes.items():
    check('current source: '+name,hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==expected)
    check('frozen source: '+name,hashlib.sha256((HERE/'after'/name).read_bytes()).hexdigest()==expected)
rel = 'commons/maps/Color_Walls/map_data.json'
before = json.loads((HERE/'before'/rel).read_text(encoding='utf-8'))
after = json.loads((ROOT/rel).read_text(encoding='utf-8'))
expected = json.loads(json.dumps(before).replace('#layout:cubicles#compare:visibility','#layout:planes#compare:visibility'))
expected['map_info']['description'] = after['map_info']['description']
check('only office layout and map description changed',expected==after)
meta = json.loads((ROOT/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8'))['rooms']['Color_Walls']
check('encounter text hash matches',meta['text_sha256']==source_hashes['commons/maps/Color_Walls/final.md'])
check('encounter map hash matches',meta['map_sha256']==source_hashes[rel])

html = (HERE/'index.html').read_text(encoding='utf-8')
soup = BeautifulSoup(html,'html.parser')
check('page uses no scripts under the review CSP',not soup.find_all('script'))
check('two native comparisons available',len(soup.select('.comparison'))==2)
for comparison in soup.select('.comparison'):
    check('comparison has a selected native default',len(comparison.select('input[checked]'))==1)
ids = {n['id'] for n in soup.select('[id]')}
for a in soup.select('a[href^="#"]'):
    check('anchor: '+a['href'],a['href'][1:] in ids)
response = urlopen(URL,timeout=15)
check('served page matches saved bytes',response.read()==(HERE/'index.html').read_bytes())
check('server CSP permits inline CSS',"style-src 'unsafe-inline'" in response.headers.get('Content-Security-Policy',''))
urls = {urljoin(URL,element.get('src') or element.get('href')) for element in soup.select('img[src], a[href]')}
for url in sorted(urls):
    parsed = urlparse(url)
    if parsed.netloc != 'localhost:3003' or parsed.fragment:
        continue
    if not parsed.path.startswith('/book-review/'):
        continue
    local = ROOT/parsed.path.removeprefix('/book-review/')
    check('linked asset: '+local.name,local.is_file())
    check('served bytes: '+local.name,urlopen(url,timeout=15).read()==local.read_bytes())
(HERE/'publication-checks.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2)+'\n',encoding='utf-8')
print(f'{len(checks)} publication and source checks passed')
