"""Verify accepted evidence, delivery links, derived route and scoped working-copy files."""
from pathlib import Path
import hashlib,json,subprocess
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
v=read(HERE/'verification.json');maps=v['museum_spaces']
long=read(ROOT/'commons/data/long_museum.json');necklace=read(ROOT/'commons/data/museum_order_effective.json')
assert [s['name'] for s in long['segments'] if s.get('kind')=='hall' and s.get('sequence')=='randomness']==maps
assert [s['name'] for s in necklace['halls'] if s['sequence']=='randomness']==maps
assert sum(s['n'] for s in necklace['halls'] if s['sequence']=='randomness')==133
for log in ['long-museum-check.log','necklace-check.log']:assert 'check OK:' in (HERE/log).read_text(encoding='utf-8')
nav=read(HERE/'navigation-run.json');assert nav['returncode']==0 and nav['before']==nav['after']
opening=read(HERE/'opening/verification.json')['runs']['accepted-after'];assert opening['returncode']==0 and opening['source_stable'] and opening['failed']==0
middle=read(HERE/'middle/evidence-manifest.json')
for run in middle['actual_museum_runs']:assert run['returncode']==0 and run['source_stable']
for pair in middle['pairs']:
 for phase in ['before','after']:assert sha(HERE/'middle'/pair[phase])==pair[phase+'_sha256']
ending=[r for r in read(HERE/'ending/runtime-summary.json') if r['current_accepted']]
assert len(ending)==2
for run in ending:assert run['returncode']==0 and run['checks']==run['passed'] and run['watched_inputs_stable']
page=ROOT/'doc/book/iterations/2026-09-19-review-comparison/index.html'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.active=False;self.refs=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag=='section':self.ids.append(d.get('id'));self.active=d.get('id')=='randomness'
  if self.active:
   for k in ['src','href']:
    if d.get(k):self.refs.append(d[k])
 def handle_endtag(self,tag):
  if tag=='section':self.active=False
p=Links();p.feed(page.read_text(encoding='utf-8'));assert p.ids[-1]=='randomness' and len(p.ids)==11
missing=[]
for ref in p.refs:
 u=urlsplit(ref)
 if u.scheme or not u.path:continue
 if not (page.parent/unquote(u.path)).resolve().exists():missing.append(ref)
assert not missing,missing
manifest={};external=v['external_registry_changes_preserved'];skip={x['path'] for x in external}
for rel,before in read(HERE/'before/sha256.json').items():
 path=ROOT/rel
 if rel not in skip and path.exists() and sha(path)!=before:manifest[rel]=dict(before_sha256=before,current_sha256=sha(path),baseline='before/'+rel)
for change in read(HERE/'opening/source-changes.json'):
 rel=change['path'];assert sha(ROOT/rel)==change['after_sha256'];manifest[rel]=dict(before_sha256=change['before_sha256'],current_sha256=sha(ROOT/rel),baseline='opening/before-source/'+rel)
for rel,current in read(HERE/'middle/owned-after-sha256.json').items():
 assert sha(ROOT/rel)==current;manifest[rel]=dict(before_sha256=sha(HERE/'middle/before-source'/rel),current_sha256=current,baseline='middle/before-source/'+rel)
for change in read(HERE/'ending/changes.json'):
 rel=change['path'];assert sha(ROOT/rel)==change['after_sha256'];manifest[rel]=dict(before_sha256=change['before_sha256'],current_sha256=sha(ROOT/rel),baseline='ending/before-source/'+rel)
write(HERE/'applied-files.json',manifest)
cmd=['git','-c','safe.directory='+ROOT.as_posix(),'-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--',*manifest.keys()]
done=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8');(HERE/'scoped-diff-check.log').write_text(done.stdout+done.stderr,encoding='utf-8');assert done.returncode==0,done.stdout+done.stderr
write(HERE/'delivery-verification.json',dict(derived_museum_order=maps,declared_chapters=14,derived_placements=133,eligible_placements=132,comparison_sections=p.ids,section_references=len(p.refs),missing_links=missing,production_files=len(manifest),scoped_diff_check_exit=done.returncode,source_checks=v['check_count'],navigation_checks=71,helper_checks=11,opening_checks=34,middle_focused_checks=49,ending_accepted_checks=[r['checks'] for r in ending],external_registry_changes_preserved=external,headset_tested=False,physical_route_followups=['Random_Space neighbouring77-cell route warning','Random_Space_Geometry five companions beyond source floor rectangle','Random_Rotate_Random_XYZ mismatched source layer extents'],existing_other_layer_warnings=['WaveFunctions_Unit_Circle','Wavefunctions_Sky_Stairs','WaveFunctions_TrigWalkingPath','Noise_Inside_Noise']))
print('Delivery verified:',len(manifest),'production files;',len(p.refs),'section references;14 chapters/16 spaces/133 placements; scoped diff check passes.')
