"""Check the frozen comparison, canonical pointers and local publication."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse, unquote
from urllib.request import urlopen
import hashlib, json, re

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
BASE='http://localhost:3003/book-review/'+OUT.relative_to(ROOT).as_posix()+'/'
checks=[]
def read(p):return p.read_text(encoding='utf-8')
def check(name,value):checks.append({'name':name,'passed':bool(value)})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
class Links(HTMLParser):
    def __init__(self):super().__init__();self.urls=[];self.ids=[]
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        if 'id' in d:self.ids.append(d['id'])
        for k in ('src','href'):
            if k in d:self.urls.append(d[k])

baseline=json.loads(read(OUT/'baseline.json'))
for rel in ('commons/maps/Point_Lines/map_data.json','commons/artifacts/line_relations_gallery/line_relations_gallery.gd','commons/primitives/point/draw_triangle_faces.gd'):
    check('unchanged '+rel,sha(ROOT/rel)==baseline['files'][rel])
room=json.loads(read(ROOT/'commons/maps/Point_Triangle_Context/map_data.json'))
for name,layer in room['layers'].items():check(name+' is 13 x 30',len(layer)==30 and all(len(row)==13 for row in layer))
tokens=[c for row in room['layers']['interactables'] for c in row if str(c).strip() not in ('0','', 'None')]
check('eight retained placements',len(tokens)==8)
check('nine recoverable parked placements',len(json.loads(read(OUT/'parked-placements.json'))['placements'])==9)
text=read(ROOT/'commons/maps/Point_Triangle_Context/final.md')
for anchor in re.findall(r'<!--\s*@([^>\s]+)\s*-->',text):
    check('chapter anchor placed: '+anchor,any(str(t).split(':')[0].split('#')[0]==anchor for t in tokens))
old=json.loads(read(OUT/'before/commons/data/museum_core_encounters.json'))
new=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
for key in list(old['rooms']):
    if key!='Point_Triangle_Context':assert old['rooms'][key]==new['rooms'][key],key
check('other encounter entries preserved',set(old['rooms'])==set(new['rooms']))
entry=new['rooms']['Point_Triangle_Context']
check('chapter and map hashes current',entry['text_sha256']==sha(ROOT/'commons/maps/Point_Triangle_Context/final.md') and entry['map_sha256']==sha(ROOT/'commons/maps/Point_Triangle_Context/map_data.json'))
for folder,expected in [('lines-final',12),('triangle-after',25)]:
    report=json.loads(read(OUT/folder/'report.json'))
    check(folder+' native result',report['passed'] and len(report['checks'])==expected and all(c['passed'] for c in report['checks']))
check('fresh process replay passed',json.loads(read(OUT/'replay-verification.json'))['passed'])
local_urls=set()
for name in ('index.html','reading.html','making.html','changes.html'):
    page=OUT/name
    parser=Links();parser.feed(read(page))
    check(name+' unique anchors',len(parser.ids)==len(set(parser.ids)))
    check(name+' UTF-8 intact','\ufffd' not in read(page))
    with urlopen(BASE+name,timeout=20) as response:
        check(name+' HTTP content equals saved page',response.status==200 and response.read()==page.read_bytes())
    for u in parser.urls:
        target=urlparse(urljoin(BASE+name,u))
        if target.netloc!='localhost:3003':continue
        if target.path.startswith('/book-review/'):
            p=ROOT/unquote(target.path[len('/book-review/'):])
            check(name+' target exists: '+u,p.is_file())
            if p.is_file() and target.fragment and p.suffix=='.html':
                target_parser=Links();target_parser.feed(read(p))
                check(name+' fragment: '+u,unquote(target.fragment) in target_parser.ids)
            if p.is_file() and p.suffix in ('.png','.css','.json'):
                local_urls.add(target._replace(fragment='').geturl())
for url in sorted(local_urls):
    try:
        with urlopen(url,timeout=20) as response:check('HTTP asset '+url.rsplit('/',1)[-1],response.status==200 and len(response.read())>0)
    except Exception as error:check('HTTP asset '+url+' '+str(error),False)
result={'passed':all(c['passed'] for c in checks),'checks':checks,'scope':'Publication integrity and saved evidence only; no additional runtime trial'}
(OUT/'publication-checks.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':result['passed'],'checks':len(checks),'failures':[c for c in checks if not c['passed']]},indent=2))
raise SystemExit(0 if result['passed'] else 1)
