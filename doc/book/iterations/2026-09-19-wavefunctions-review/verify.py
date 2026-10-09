"""Verify pass boundaries, authoritative route, and retained collection."""
from pathlib import Path
import hashlib,json,re
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append(dict(name=name,ok=bool(ok)))
 assert ok,name
seq=read(ROOT/'commons/maps/sequences/wavefunctions.json')['sequences']['wavefunctions']
maps=seq['maps']
check('Declared twelve-hall order preserved',maps==read(HERE/'before/commons/maps/sequences/wavefunctions.json')['sequences']['wavefunctions']['maps'] and len(maps)==12)
live=read(ROOT/'ada_run/em_plan.json'); shipped=read(ROOT/'commons/data/museum/em_plan.json')
check('Live and shipped plans agree',live==shipped)
rows=[r for r in live['plans'] if r.get('sequence')=='wavefunctions']
check('All twelve halls are in actual plan order',[r['map'] for r in rows]==maps)
check('All twelve authored route owners agree',read(ROOT/'commons/data/map_authored.json')['wavefunctions']==maps)
check('Twelve-hall cursor indexes agree',all(r['pearl_index']==i and r['pearls_total']==12 for i,r in enumerate(rows)))
before_plan=read(HERE/'before/commons/data/museum/em_plan.json')
check('Unrelated plan rows preserved',[r for r in before_plan['plans'] if r.get('sequence')!='wavefunctions']==[r for r in live['plans'] if r.get('sequence')!='wavefunctions'])
check('Plan top-level settings preserved',{k:v for k,v in before_plan.items() if k!='plans'}=={k:v for k,v in live.items() if k!='plans'})
before_authored=read(HERE/'before/commons/data/map_authored.json'); current_authored=read(ROOT/'commons/data/map_authored.json')
check('Unrelated authored routes preserved',{k:v for k,v in before_authored.items() if k!='wavefunctions'}=={k:v for k,v in current_authored.items() if k!='wavefunctions'})
check('All role assignments and orders preserved',read(ROOT/'commons/data/artifact_roles.json')==read(HERE/'before/commons/data/artifact_roles.json'))
counts={}; changed=[];tokens=[]
for name in maps:
 rel=f'commons/maps/{name}/map_data.json';a=read(HERE/'before'/rel);b=read(ROOT/rel)
 al=a['layers'];bl=b['layers']
 check(name+' non-interactable layers unchanged',{k:v for k,v in al.items() if k!='interactables'}=={k:v for k,v in bl.items() if k!='interactables'})
 def cells(d):return {(x,z):str(t) for z,row in enumerate(d['interactables']) for x,t in enumerate(row) if str(t).strip() not in ('','0','None')}
 ac,bc=cells(al),cells(bl)
 check(name+' placement cells and artifact identities preserved',{c:re.split('[:#]',t)[0] for c,t in ac.items()}=={c:re.split('[:#]',t)[0] for c,t in bc.items()})
 counts[name]=len(bc)
 for c,t in ac.items():
  if bc[c]!=t:tokens.append(dict(map=name,cell=list(c),before=t,after=bc[c]))
 text=f'commons/maps/{name}/final.md'
 if sha(ROOT/text)!=sha(HERE/'before'/text):changed.append(name)
check('All 132 authored placements retained',sum(counts.values())==132)
check('Only two opt-in token changes',tokens==[
 dict(map='WaveFunctions_3D_Wave_Propagation',cell=[8,13],before='coupled_oscillator_lattice',after='coupled_oscillator_lattice#comparison:true'),
 dict(map='WaveFunctions_Synthesis_Lab',cell=[4,2],before='additive_wave_demo:0#stand:bench#waveform:sawtooth',after='additive_wave_demo:0#stand:bench#waveform:sawtooth#name_after_compare:true')])
check('Only four documented manuscripts changed',set(changed)=={'WaveFunctions_Sine_Space','WaveFunctions_3D_Wave_Propagation','WaveFunctions_Effect_Sound','WaveFunctions_AirMusic'})
for name in changed:check(name+' exact proposed manuscript',(ROOT/f'commons/maps/{name}/final.md').read_bytes()==(HERE/'proposed'/f'{name}.md').read_bytes())
chain=read(HERE/'source-chain.json')
check('Every retained placement has an eligible scene',all(any(s['scene_exists'] and s['map_ready'] for s in p['sources']) for r in chain.values() for p in r['placements']))
before_core=read(HERE/'before/commons/data/museum_core_encounters.json');core=read(ROOT/'commons/data/museum_core_encounters.json')
check('Unrelated encounter records retained',{k:v for k,v in before_core['rooms'].items() if k not in maps}=={k:v for k,v in core['rooms'].items() if k not in maps})
for name in maps:
 r=core['rooms'][name]
 check(name+' hashes current and learner pending',r['map_sha256']==sha(ROOT/f'commons/maps/{name}/map_data.json') and r['text_sha256']==sha(ROOT/f'commons/maps/{name}/final.md') and r['learner_verified'] is False)
# Proposed catalog fields are the only differences across every registry file.
allowed={}
for p in read(HERE/'applied-metadata.json'):
 if p['path'].startswith('commons/artifacts/registry/'):allowed.setdefault(p['path'],[]).append(p)
external_registry_changes=[]
for path in (HERE/'before/commons/artifacts/registry').glob('*.json'):
 rel=path.relative_to(HERE/'before').as_posix();expected=read(path)
 for p in allowed.get(rel,[]):
  cursor=expected
  for k in p['keys'][:-1]:cursor=cursor[k]
  cursor[p['keys'][-1]]=p['new']
 if rel in allowed:
  check('Catalog scope: '+path.name,read(ROOT/rel)==expected)
 elif read(ROOT/rel)!=expected:
  external_registry_changes.append(dict(path=rel,before_sha256=sha(path),current_sha256=sha(ROOT/rel)))
record=dict(checks=checks,check_count=len(checks),placements=counts,token_changes=tokens,changed_chapters=changed,
 unchanged_chapters=[m for m in maps if m not in changed],headset_tested=False,external_registry_changes_preserved=external_registry_changes,
 limits='Route contract is not a complete physical walk; per-artifact runtime scopes are documented in opening, middle and ending audits.')
(HERE/'verification.json').write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(len(checks),'checks passed;',sum(counts.values()),'placements;',len(changed),'chapters changed;',len(maps)-len(changed),'byte-preserved.')
