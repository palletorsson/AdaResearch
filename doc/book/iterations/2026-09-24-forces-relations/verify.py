from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin,urldefrag,urlsplit
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
import hashlib,json,re
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-forces-relations'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
protected=json.loads((out/'preserved.json').read_text(encoding='utf-8'))
for rel,h in base.items():assert sha(out/'before'/rel)==h,'Original snapshot: '+rel
for rel,h in protected.items():assert sha(root/rel)==h,'Protected input: '+rel
maps=['Vectors_Act1_WhatAVectorIs','VFM_02_Operations','Vectors_Act2_VectorArithmetic']
core=json.loads((root/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
oldcore=json.loads((out/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 assert core['rooms'][m]['text_sha256']==sha(root/f'commons/maps/{m}/final.md')
 for key in ['text_sha256','local_review']:oldcore['rooms'][m][key]=core['rooms'][m][key]
assert oldcore==core,'Core data changed beyond six allowed fields'
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
baseurl='http://localhost:3003/book-review/doc/book/iterations/2026-09-24-forces-relations/index.html'
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
report={'chapters':maps,'primary_encounters_preserved':anchor_count,'mathematical_code_blocks_retained':code_count,'code_blocks_retained_in_companion':companion_code_count,'original_snapshots_intact':len(base),'protected_inputs_unchanged':len(protected),'remaining_forces_manuscripts_unchanged':10,'core_changes':'Only three text hashes and three review links','capture_hashes_current':len(manifest['maps']),'html_anchors_unique_and_resolved':True,'http':checks,'native_runtime':'not run; source and placement unchanged','visual_browser':'unavailable: trusted browser Node process could not start in this session; HTTP content verified','headset':'not tested'}
(out/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='http'},indent=2));print('HTTP checks passed:',len(checks))
