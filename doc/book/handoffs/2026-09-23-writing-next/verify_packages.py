from pathlib import Path
import json,hashlib,zipfile,urllib.request,urllib.parse,shutil
from datetime import datetime,timezone
from html.parser import HTMLParser
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
PUB=ROOT/'doc/book/iterations/2026-09-23-writing-next'
def sha(data): return hashlib.sha256(data).hexdigest()
checks=[]
def check(name,ok): checks.append({'check':name,'passed':bool(ok)})
for item in json.loads((OUT/'packages.json').read_text(encoding='utf-8')):
 seq=item['sequence']; folder=OUT/'packages'/seq
 manifest=json.loads((folder/'MANIFEST.json').read_text(encoding='utf-8'))
 archive=OUT/item['zip']
 check(seq+': archive hash',sha(archive.read_bytes())==item['zip_sha256'])
 with zipfile.ZipFile(archive) as z:
  check(seq+': ZIP integrity',z.testzip() is None)
  for rel,expected in manifest['files'].items():
   check(seq+': '+rel,sha((folder/rel).read_bytes())==expected and sha(z.read(rel))==expected)
  check(seq+': manifest',z.read('MANIFEST.json')==(folder/'MANIFEST.json').read_bytes())
 state=json.loads((folder/'state.json').read_text(encoding='utf-8'))
 for hall in state['declared_maps']:
  rel=Path('commons/maps')/hall/'final.md'
  check(seq+': current '+hall,(folder/'sources'/rel).read_bytes()==(ROOT/rel).read_bytes())
 for name in ['WRITING_BRIEF.md','ASSESSMENT.md']:
  check(seq+': shared '+name,(folder/name).read_bytes()==(OUT/name).read_bytes())
 for ref in (folder/'voice-examples').glob('*.md'):
  check(seq+': current voice '+ref.stem,ref.read_text(encoding='utf-8')==(ROOT/'commons/maps'/ref.stem/'final.md').read_text(encoding='utf-8'))
 for name in ['NEIGHBOURS.md','placed-source-snapshot.json','space.json','artifact-index.json','.gdignore']:
  check(seq+': includes '+name,(folder/name).is_file() and (folder/name).stat().st_size>0)
 start=(folder/'START_HERE.md').read_text(encoding='utf-8')
 check(seq+': one-hall writing assignment','one pilot hall' in start and 'Return up to five findings' not in start)
for file in PUB.rglob('*'):
 if file.is_file() and file.name not in ['README.md','verification.json']:
  check('Reading mirror '+file.relative_to(PUB).as_posix(),file.read_bytes()==(OUT/file.relative_to(PUB)).read_bytes())
class Links(HTMLParser):
 def __init__(self): super().__init__(); self.links=[]
 def handle_starttag(self,tag,attrs):
  if tag=='a': self.links.extend(v for k,v in attrs if k=='href')
links=Links(); links.feed((PUB/'index.html').read_text(encoding='utf-8'))
base='http://localhost:3003/book-review/doc/book/iterations/2026-09-23-writing-next/'
for rel in sorted(set(['index.html']+links.links)):
 if rel.startswith(('#','http','file:')) or rel=='verification.json': continue
 try:
  with urllib.request.urlopen(urllib.parse.urljoin(base,rel),timeout=15) as response:
   check('HTTP '+rel,response.status==200 and bool(response.read()))
 except Exception: check('HTTP '+rel,False)
report={'created_at':datetime.now(timezone.utc).isoformat(),'scope':'Frozen package and ZIP hashes, exact canonical source copies, reference chapter text equality with normalized newlines, reading mirror and HTTP availability. No new Godot runtime, browser interaction, headset or learner test.','delivery':'Complete packages and ZIPs remain in doc/book/handoffs/2026-09-23-writing-next. HTTP reading mirror is under doc/book/iterations/2026-09-23-writing-next. Upload the ZIP using its local path.','initial_check_resolutions':['Two reference chapters had only normalized newlines; original source copies remain byte-exact.','The server does not serve handoffs paths; a reading mirror was created under its existing iterations path without changing the server.'],'total_checks':len(checks),'passed':sum(c['passed'] for c in checks),'failed':[c for c in checks if not c['passed']],'checks':checks}
(OUT/'verification.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
shutil.copy2(OUT/'verification.json',PUB/'verification.json')
print(json.dumps({k:v for k,v in report.items() if k!='checks'},indent=2))
if report['failed']: raise SystemExit(1)
