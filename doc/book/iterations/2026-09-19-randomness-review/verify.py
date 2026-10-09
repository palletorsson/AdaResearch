"""Verify this pass against its frozen baseline, including intentional interludes."""
from pathlib import Path
import collections, hashlib, json, re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append(dict(name=name,ok=bool(ok)))
 assert ok,name
seq=read(ROOT/'commons/maps/sequences/randomness.json')['sequences']['randomness'];maps=seq['maps']
oldseq=read(HERE/'before/commons/maps/sequences/randomness.json')['sequences']['randomness']
check('Fourteen declared chapters and deferred maps preserved',maps==oldseq['maps'] and len(maps)==14 and seq['deferred_maps']==oldseq['deferred_maps'])
physical=[]
for name in maps:
 physical.append(name);physical.extend(i['map'] for i in seq['museum_interludes'] if i['after']==name)
check('Two authorial biome interludes retained',len(physical)==16 and physical[physical.index('Random_Mushrooms')+1]=='Biome_Cage' and physical[-1]=='Biome_Ladder_Randomness')
live=read(ROOT/'ada_run/em_plan.json');shipped=read(ROOT/'commons/data/museum/em_plan.json')
check('Live and shipped plans agree',live==shipped)
rows=[r for r in live['plans'] if r.get('sequence')=='randomness']
check('All sixteen spaces are in the actual route',[r['map'] for r in rows]==physical)
check('Authored owner agrees',read(ROOT/'commons/data/map_authored.json')['randomness']==physical)
check('Sixteen-space cursor indexes agree',all(r['pearl_index']==i and r['pearls_total']==16 for i,r in enumerate(rows)))
bp=read(HERE/'before/commons/data/museum/em_plan.json')
check('Unrelated plan rows preserved',[r for r in bp['plans'] if r.get('sequence')!='randomness']==[r for r in live['plans'] if r.get('sequence')!='randomness'])
check('Plan settings preserved',{k:v for k,v in bp.items() if k!='plans'}=={k:v for k,v in live.items() if k!='plans'})
ba=read(HERE/'before/commons/data/map_authored.json');ca=read(ROOT/'commons/data/map_authored.json')
check('Unrelated authored routes preserved',{k:v for k,v in ba.items() if k!='randomness'}=={k:v for k,v in ca.items() if k!='randomness'})
refreshed={'Random_Mushrooms','Random_Rotate_Random_XYZ','Random_Pheromone'}
for old in bp['plans']:
 if old.get('sequence')!='randomness' or old['map'] in refreshed:continue
 new=next(r for r in rows if r['map']==old['map'])
 check(old['map']+' existing geometry preserved',{k:v for k,v in old.items() if k not in ['pearl_index','pearls_total']}=={k:v for k,v in new.items() if k not in ['pearl_index','pearls_total']})
roles=read(ROOT/'commons/data/artifact_roles.json');expected=read(HERE/'before/commons/data/artifact_roles.json')
promoted=['mushrooms','silhouette_arrivals','couture_comparison']
for token in promoted:expected['roles']['Random_Mushrooms'][token]='primary'
expected['order']['Random_Mushrooms']['primary']=promoted
expected['order']['Random_Mushrooms']['secondary']=[x for x in expected['order']['Random_Mushrooms']['secondary'] if x not in promoted]
check('Only the two existing Mushroom comparisons promoted',roles==expected)
metadata=read(HERE/'applied-metadata.json');staging=read(HERE/'map-changes.json')
book_rel='commons/data/book/randomness.json';expected_book=read(HERE/'before'/book_rel)
for p in metadata:
 if p['path']!=book_rel:continue
 cursor=expected_book
 for k in p['keys'][:-1]:cursor=cursor[k]
 cursor[p['keys'][-1]]=p['new']
check('Book cards only receive documented additions and corrections',read(ROOT/book_rel)==expected_book)
counts={};changed=[]
def tokens(d):return [str(t) for row in d['layers']['interactables'] for t in row if str(t).strip() not in ('','0','None')]
for name in physical:
 rel=f'commons/maps/{name}/map_data.json';old=read(HERE/'before'/rel);new=read(ROOT/rel);expected=read(HERE/'before'/rel)
 for p in metadata:
  if p['path']!=rel:continue
  cursor=expected
  for k in p['keys'][:-1]:cursor=cursor[k]
  cursor[p['keys'][-1]]=p['new']
 for change in staging:
  if change['map']!=name:continue
  grid=expected['layers'][change.get('layer','interactables')]
  if change['action']=='configure':
   x,z=change['cell'];assert grid[z][x]==change['before'];grid[z][x]=change['after']
  elif change['action']=='move':
   x,z=change['before'];a,b=change['after'];assert grid[z][x]==change['token'] and not grid[b][a].strip()
   grid[z][x]=change.get('empty',' ');grid[b][a]=change['token']
  elif change['action']=='layer-cell':
   x,z=change['cell'];assert grid[z][x]==change['before'];grid[z][x]=change['after']
  elif change['action']=='museum-config':expected['map_info']['museum']=change['after']
  else:raise AssertionError(change)
 check(name+' only documented map edits',new==expected)
 oldkeys=collections.Counter(re.split('[:#]',t)[0] for t in tokens(old));newkeys=collections.Counter(re.split('[:#]',t)[0] for t in tokens(new))
 check(name+' every authored artifact retained',oldkeys==newkeys);counts[name]=len(tokens(new))
 if name in maps and sha(ROOT/f'commons/maps/{name}/final.md')!=sha(HERE/'before'/f'commons/maps/{name}/final.md'):changed.append(name)
check('All133 placements retained',sum(counts.values())==133)
check('Five manuscripts revised',set(changed)=={'Random_Remove','Random_Walk','Random_Mushrooms','Randomness_Examples_of_Randomness','Random_Pheromone'})
for name in changed:check(name+' equals exact proposal',(ROOT/f'commons/maps/{name}/final.md').read_bytes()==(HERE/'proposed'/f'{name}.md').read_bytes())
chain=read(HERE/'source-chain.json')
ineligible=[dict(map=name,token=p['key']) for name,r in chain.items() for p in r['placements'] if not any(s['scene_exists'] and s['map_ready'] for s in p['sources'])]
check('Only explicitly deferred standalone Nature demo ineligible',ineligible==[dict(map='Randomness_10_PRINT_Algorithm',token='nature_system_demo')])
bc=read(HERE/'before/commons/data/museum_core_encounters.json');core=read(ROOT/'commons/data/museum_core_encounters.json')
check('Unrelated encounter records preserved',{k:v for k,v in bc['rooms'].items() if k not in maps}=={k:v for k,v in core['rooms'].items() if k not in maps})
for name in maps:
 r=core['rooms'][name];check(name+' hashes current and learner pending',r['map_sha256']==sha(ROOT/f'commons/maps/{name}/map_data.json') and r['text_sha256']==sha(ROOT/f'commons/maps/{name}/final.md') and r['learner_verified'] is False)
allowed={}
for p in metadata:
 if p['path'].startswith('commons/artifacts/registry/'):allowed.setdefault(p['path'],[]).append(p)
external=[]
for path in (HERE/'before/commons/artifacts/registry').glob('*.json'):
 rel=path.relative_to(HERE/'before').as_posix();expected=read(path)
 for p in allowed.get(rel,[]):
  cursor=expected
  for k in p['keys'][:-1]:cursor=cursor[k]
  cursor[p['keys'][-1]]=p['new']
 if rel in allowed:check('Catalog scope '+path.name,read(ROOT/rel)==expected)
 elif read(ROOT/rel)!=expected:external.append(dict(path=rel,before_sha256=sha(path),current_sha256=sha(ROOT/rel)))
record=dict(checks=checks,check_count=len(checks),chapters=maps,museum_spaces=physical,placements=counts,eligible_placements=132,ineligible=ineligible,changed_chapters=changed,unchanged_chapters=[m for m in maps if m not in changed],external_registry_changes_preserved=external,headset_tested=False,limits='Navigation contract and bounded exhibits only; no complete embodied sixteen-space route or learner validation.')
(HERE/'verification.json').write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(len(checks),'checks passed;133 placements;5 chapters revised;9 byte-preserved.')
