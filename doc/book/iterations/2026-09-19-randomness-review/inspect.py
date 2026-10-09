"""Freeze the pass baseline and inspect authored placements without assuming runtime admission."""
from pathlib import Path
import hashlib, json, re, shutil, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
sys.stdout.reconfigure(encoding='utf-8')
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
seq=read(ROOT/'commons/maps/sequences/randomness.json')['sequences']['randomness']
if '--freeze' in sys.argv:
    paths=[ROOT/p for p in ['commons/maps/sequences/randomness.json','commons/data/artifact_roles.json','commons/data/museum_core_encounters.json','commons/data/map_authored.json','commons/data/book/randomness.json','commons/data/museum/em_plan.json','commons/data/museum/em_bake.json','commons/data/museum_order_effective.json','ada_run/em_plan.json','commons/data/long_museum.json']]
    paths+=list((ROOT/'commons/artifacts/registry').glob('*.json'))
    for name in seq['maps'] + ['Biome_Cage', 'Biome_Ladder_Randomness']:
        paths += [p for p in (ROOT/'commons/maps'/name).glob('*') if p.is_file() and p.suffix in ['.md','.json']]
    manifest={}
    for path in paths:
        if not path.exists():continue
        rel=path.relative_to(ROOT); target=HERE/'before'/rel
        if not target.exists():
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,target)
        manifest[rel.as_posix()]=sha(target)
    (HERE/'before/sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('Baseline saved:',len(manifest),'files')
roles=read(ROOT/'commons/data/artifact_roles.json')
registry={}
for p in (ROOT/'commons/artifacts/registry').glob('*.json'):
    for key,v in read(p).get('artifacts',{}).items():registry.setdefault(key,[]).append((p,v))
records={}
for name in seq['maps'] + ['Biome_Cage', 'Biome_Ladder_Randomness']:
    d=read(ROOT/f'commons/maps/{name}/map_data.json');items=[]
    for z,row in enumerate(d['layers']['interactables']):
        for x,raw in enumerate(row):
            if str(raw).strip() in ('','0','None'):continue
            key=re.split('[:#]',str(raw))[0]; sources=[]
            for p,v in registry.get(key,[]):
                scene=v.get('scene','');sp=ROOT/scene.removeprefix('res://')
                sources.append(dict(registry=p.relative_to(ROOT).as_posix(),scene=scene,map_ready=v.get('map_ready'),include_in_map_data=v.get('include_in_map_data'),scene_exists=bool(scene) and sp.is_file(),scripts=re.findall(r'path="(res://[^"]+\.gd)"',sp.read_text(encoding='utf-8')) if sp.is_file() else []))
            items.append(dict(key=key,token=raw,cell=[x,z],role=roles['roles'].get(name,{}).get(key),sources=sources))
    records[name]=dict(order=roles['order'].get(name),placements=items)
    bad=[v['key'] for v in items if not any(s['scene_exists'] and s['map_ready'] for s in v['sources'])]
    print(name,len(items),'placements; primary',roles['order'].get(name,{}).get('primary'),'; ineligible:',bad)
(HERE/'source-chain.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('Total:',sum(len(v['placements']) for v in records.values()))
