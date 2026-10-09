"""Restore missing authored chapters without discarding the two deliberate biome spaces."""
from pathlib import Path
import copy,hashlib,json,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
sys.path.insert(0,str(ROOT/'tools'))
import em_map_halls
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(b):return hashlib.sha256(b).hexdigest()
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
core=read(ROOT/'commons/maps/sequences/randomness.json')['sequences']['randomness']['maps']
order=[]
for name in core:
 order.append(name)
 if name=='Random_Mushrooms':order.append('Biome_Cage')
order.append('Biome_Ladder_Randomness')
assert len(core)==14 and len(order)==16 and len(set(order))==16
paths=['ada_run/em_plan.json','commons/data/museum/em_plan.json','commons/data/map_authored.json']
raw={p:(ROOT/p).read_bytes() for p in paths}
inputs={p:read(ROOT/p) for p in paths}; outputs={}
plan=inputs[paths[0]]
existing={r['map']:r for r in plan['plans'] if r.get('sequence')=='randomness'}
assert set(existing).issubset(order),'Unexpected authored room; reconcile without deletion'
templates={r['museum'] for r in existing.values()}
assert templates=={'soane-cabinet-vista'},templates
missing=[n for n in core if n not in existing]
added={}
for name in missing:
 r=em_map_halls.derive_row(name.replace('_',' ').lower(),name,'soane-cabinet-vista',order.index(name),len(order),'randomness')
 em_map_halls.normalize_row(r,True,any(k in r for k in ('basin','passage','simulation')),width_exempt=False)
 added[name]=r
for p in paths[:2]:
 source=inputs[p]; source_rows={r['map']:r for r in source['plans'] if r.get('sequence')=='randomness'}
 assert set(source_rows)==set(existing)
 target=copy.deepcopy(source); rows=[]
 for name in order:
  row=copy.deepcopy(source_rows.get(name,added.get(name)))
  assert row is not None,name
  row['pearl_index']=order.index(name);row['pearls_total']=len(order)
  rows.append(row)
 first=next(i for i,r in enumerate(source['plans']) if r.get('sequence')=='randomness')
 other=[r for r in source['plans'] if r.get('sequence')!='randomness']
 target['plans']=copy.deepcopy(other[:first])+rows+copy.deepcopy(other[first:])
 assert [r for r in target['plans'] if r.get('sequence')!='randomness']==other
 assert {k:v for k,v in source.items() if k!='plans'}=={k:v for k,v in target.items() if k!='plans'}
 for row in rows:
  if row['map'] in source_rows:
   old=source_rows[row['map']]
   assert {k:v for k,v in row.items() if k not in ('pearl_index','pearls_total')}=={k:v for k,v in old.items() if k not in ('pearl_index','pearls_total')}
 outputs[p]=target
target=copy.deepcopy(inputs[paths[2]]);target['randomness']=order;outputs[paths[2]]=target
assert {k:v for k,v in inputs[paths[2]].items() if k!='randomness'}=={k:v for k,v in target.items() if k!='randomness'}
report=dict(sequence='randomness',book_chapters=core,museum_order=order,restored=missing,
 retained_interludes={'Biome_Cage':'after Random_Mushrooms: application of an authored repertoire','Biome_Ladder_Randomness':'after Random_Game: cumulative seeded composition'},
 input_sha256={p:sha(b) for p,b in raw.items()},rows_before=len(plan['plans']),rows_after=len(outputs[paths[0]]['plans']),
 preservation='All existing room geometry/artifacts and unrelated plan rows unchanged. Only ordering fields of retained randomness rows change.',headset_tested=False,
 derived=[dict(map=n,room=r.get('room'),artifacts=len(r['artifacts'])) for n,r in added.items()])
report['mode']='apply' if '--apply' in sys.argv else 'inspect'
if '--apply' in sys.argv:
 for p,b in raw.items():assert (ROOT/p).read_bytes()==b,'Concurrent route edit: '+p
 prepared={}
 for p,d in outputs.items():
  if d==inputs[p]:continue
  temp=(ROOT/p).with_suffix('.randomness-refresh.tmp');temp.write_bytes(encode(d));prepared[p]=temp
 for p,t in prepared.items():t.replace(ROOT/p)
 report['changed_paths']=list(prepared)
 report['after_sha256']={p:sha((ROOT/p).read_bytes()) for p in paths}
(HERE/('route-change.json' if '--apply' in sys.argv else 'route-preview.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(report['mode'],len(core),'chapters;',len(order),'museum spaces;',len(missing),'restored:',', '.join(missing))
