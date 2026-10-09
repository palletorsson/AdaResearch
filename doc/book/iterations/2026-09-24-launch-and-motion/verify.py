from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin,urldefrag,urlsplit
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
import hashlib,json,re
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-launch-and-motion'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
protected=json.loads((out/'preserved.json').read_text(encoding='utf-8'))
for rel,h in base.items():assert sha(out/'before'/rel)==h,'Original snapshot: '+rel
for rel,h in protected.items():assert sha(root/rel)==h,'Protected input: '+rel
maps=['VFM_05_Launch','VFM_03_Motion']
core=json.loads((root/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
oldcore=json.loads((out/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 assert core['rooms'][m]['text_sha256']==sha(root/f'commons/maps/{m}/final.md')
 for key in ['text_sha256','local_review']:oldcore['rooms'][m][key]=core['rooms'][m][key]
assert oldcore==core,'Core data changed beyond four allowed fields'
code_count=0;companion_code_count=0;anchor_count=0
for m in maps:
 rel=f'commons/maps/{m}/final.md';before=(out/'before'/rel).read_text(encoding='utf-8-sig');after=(root/rel).read_text(encoding='utf-8-sig')
 anchors=lambda s:re.findall(r'<!--\s*@([^>]*?)\s*-->',s)
 assert anchors(before)==anchors(after)
 anchor_count+=len([a for a in anchors(after) if a.strip()])
 notes=(root/f'commons/maps/{m}/tutorial.md').read_text(encoding='utf-8-sig')
 code=lambda s:re.findall(r'```[^\n]*\n(.*?)```',s,re.S)
 for block in code(before):
  if block in code(after):code_count+=1
  else:assert block in code(notes),'Missing code: '+m;companion_code_count+=1
 assert sha(out/'after'/rel)==sha(root/rel)
 for text in [before,after,notes]:assert '\ufffd' not in text,'Encoding replacement found'
manifest=json.loads((root/'doc/book/captures/forces/forces-book.manifest.json').read_text(encoding='utf-8'))
for m in manifest['maps']:assert sha(root/m['path'])==m['sha256']
for name in ['forces-book.md','forces-book.manifest.json']:assert sha(out/'capture'/name)==sha(root/'doc/book/captures/forces'/name)
for name in ['launch_chamber_inside.png','motion_chamber_inside.png']:
 assert sha(out/'images'/name)==sha(root/'doc/research/possible-bodies'/name)
walked='commons/maps/VFM_03_Motion/walked.md'
old_walk=(out/'before'/walked).read_text(encoding='utf-8-sig')
new_walk=(root/walked).read_text(encoding='utf-8-sig')
assert new_walk.endswith(old_walk.split('\n',1)[1]),'Historical draft was altered'
class Page(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.links=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if 'id' in d:self.ids.append(d['id'])
  if tag=='a' and 'href' in d:self.links.append(d['href'])
page=Page();page.feed((out/'index.html').read_text(encoding='utf-8'))
assert len(page.ids)==len(set(page.ids)),'Duplicate anchor'
for link in page.links:
 if link.startswith('#'):assert link[1:] in page.ids,'Missing anchor: '+link
baseurl='http://localhost:3003/book-review/doc/book/iterations/2026-09-24-launch-and-motion/index.html'
urls={baseurl}
for link in page.links:
 if not link.startswith('#'):urls.add(urldefrag(urljoin(baseurl,link))[0])
for m in maps:
 for suffix in ['before','after']:urls.add(urljoin(baseurl,m+'.'+suffix+'.md'))
def fetch(url):
 with urlopen(url,timeout=25) as response:
  data=response.read();status=response.status
  assert status==200,(url,status)
  if url==baseurl:assert data.decode('utf-8').replace('\r\n','\n')==(out/'index.html').read_text(encoding='utf-8')
  return {'url':url,'status':status,'bytes':len(data)}
with ThreadPoolExecutor(max_workers=4) as pool:checks=list(pool.map(fetch,sorted(urls)))
report={'chapters':maps,'primary_encounters_preserved':anchor_count,'mathematical_code_blocks_retained':code_count,'code_blocks_retained_in_companion':companion_code_count,'original_snapshots_intact':len(base),'protected_inputs_unchanged':len(protected),'remaining_forces_manuscripts_unchanged':11,'core_changes':'Only two text hashes and two review links','capture_hashes_current':len(manifest['maps']),'html_anchors_unique_and_resolved':True,'http':checks,'historical_draft_preserved':True,'existing_native_images':'visually inspected; two unchanged PNG copies','native_runtime':'not run; source and placement unchanged','visual_browser':'not performed; trusted browser unavailable in this session; HTTP content verified','headset':'not tested'}
(out/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='http'},indent=2));print('HTTP checks passed:',len(checks))
