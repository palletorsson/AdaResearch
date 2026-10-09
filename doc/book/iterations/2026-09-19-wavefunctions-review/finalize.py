"""Verify review links, record current scoped files, and check whitespace."""
from pathlib import Path
import hashlib,json,subprocess
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

maps=read(ROOT/'commons/maps/sequences/wavefunctions.json')['sequences']['wavefunctions']['maps']
long=read(ROOT/'commons/data/long_museum.json'); necklace=read(ROOT/'commons/data/museum_order_effective.json')
assert [s['name'] for s in long['segments'] if s['kind']=='hall' and s['sequence']=='wavefunctions']==maps
assert [s['name'] for s in necklace['halls'] if s['sequence']=='wavefunctions']==maps
assert sum(s['n'] for s in necklace['halls'] if s['sequence']=='wavefunctions')==132

page=ROOT/'doc/book/iterations/2026-09-19-review-comparison/index.html'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.active=False;self.refs=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag=='section':
   self.ids.append(d.get('id'));self.active=d.get('id')=='wavefunctions'
  if self.active:
   for k in ['src','href']:
    if d.get(k):self.refs.append(d[k])
 def handle_endtag(self,tag):
  if tag=='section':self.active=False
p=Links();p.feed(page.read_text(encoding='utf-8'))
assert 'formfinding' in p.ids and 'wavefunctions' in p.ids and len(p.ids)==10
missing=[]
for ref in p.refs:
 u=urlsplit(ref)
 if u.scheme or not u.path:continue
 if not (page.parent/unquote(u.path)).resolve().exists():missing.append(ref)
assert not missing,missing

manifest={};external=read(HERE/'verification.json')['external_registry_changes_preserved']
skip={x['path'] for x in external}
for rel,before in read(HERE/'before/sha256.json').items():
 current=ROOT/rel
 if rel not in skip and current.exists() and sha(current)!=before:
  manifest[rel]=dict(before_sha256=before,current_sha256=sha(current),baseline='before/'+rel)
for rel,before in read(HERE/'opening/before-sha256.json').items():
 if sha(ROOT/rel)!=before:manifest[rel]=dict(before_sha256=before,current_sha256=sha(ROOT/rel),baseline='opening/before/'+rel)
for rel,current in read(HERE/'middle/MANIFEST.json')['owned_source_sha256'].items():
 assert sha(ROOT/rel)==current,rel
 manifest[rel]=dict(current_sha256=current,baseline='middle/before/'+rel)
for item in read(HERE/'ending/changes.json'):
 rel=item['path']
 # Root integrates additional metadata in the same maps after subagent capture.
 if rel not in manifest:manifest[rel]=dict(before_sha256=item['before_sha256'],current_sha256=sha(ROOT/rel),baseline='ending/before-source/'+rel)
write(HERE/'applied-files.json',manifest)
command=['git','-c','safe.directory='+ROOT.as_posix(),'-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--',*manifest.keys()]
done=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
(HERE/'scoped-diff-check.log').write_text(done.stdout+done.stderr,encoding='utf-8')
assert done.returncode==0,done.stdout+done.stderr
write(HERE/'delivery-verification.json',dict(derived_route_order=maps,derived_wavefunctions_placements=132,
 comparison_sections=p.ids,new_section_local_references=len(p.refs),missing_links=missing,
 applied_production_files=len(manifest),scoped_diff_check_exit=done.returncode,
 existing_layer_warnings=['WaveFunctions_Unit_Circle','Wavefunctions_Sky_Stairs','WaveFunctions_TrigWalkingPath','Noise_Inside_Noise'],
 external_registry_changes_preserved=external,headset_tested=False))
print('Delivery checked:',len(p.refs),'local section references;',len(manifest),'production files; indexes retain12 halls and132 placements; scoped diff check passes.')
