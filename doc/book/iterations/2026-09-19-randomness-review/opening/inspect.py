"""Read opening encounters; freeze their source closure before local repairs."""
from pathlib import Path
import hashlib, json, re, shutil, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
NAMES=['Random_Definition','Random_Entropy','Random_Remove','Randomness_10_PRINT_Algorithm','Random_Cubes']
sys.stdout.reconfigure(encoding='utf-8')
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
roles=read(ROOT/'commons/data/artifact_roles.json')
registry={}
for p in (ROOT/'commons/artifacts/registry').glob('*.json'):
    for k,v in read(p).get('artifacts',{}).items(): registry.setdefault(k,[]).append((p,v))
paths=set(); records={}
def visit(path):
    if path in paths or not path.is_file(): return
    paths.add(path)
    if path.suffix not in ('.gd','.tscn','.tres','.gdshader'): return
    for rel in re.findall(r'res://([^"\s\)]+\.(?:gd|tscn|tres|gdshader))',path.read_text(encoding='utf-8-sig')):
        visit(ROOT/rel)
for name in NAMES:
    d=read(ROOT/f'commons/maps/{name}/map_data.json'); placements=[]
    for z,row in enumerate(d['layers']['interactables']):
        for x,token in enumerate(row):
            if str(token).strip() in ('','0','None'): continue
            key=re.split('[:#]',str(token))[0]; sources=[]
            for p,v in registry.get(key,[]):
                scene=v.get('scene',''); sp=ROOT/scene.removeprefix('res://'); visit(sp)
                sources.append(dict(registry=p.relative_to(ROOT).as_posix(),scene=scene,map_ready=v.get('map_ready'),description=v.get('description'),scripts=re.findall(r'path="(res://[^"]+\.gd)"',sp.read_text(encoding='utf-8-sig')) if sp.is_file() else []))
            placements.append(dict(key=key,token=token,cell=[x,z],role=roles['roles'].get(name,{}).get(key),sources=sources))
    records[name]=dict(order=roles['order'][name],placements=placements)
    print(name,'primary:',roles['order'][name]['primary'])
    for item in placements: print(' ',item['token'],item['role'],[(s['scene'],s['scripts']) for s in item['sources']])
(HERE/'source-chain.json').write_text(json.dumps(records,indent=2,ensure_ascii=False),encoding='utf-8')
manifest={}
for p in sorted(paths):
    rel=p.relative_to(ROOT); dst=HERE/'before-source'/rel
    if not dst.exists(): dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dst)
    manifest[rel.as_posix()]=sha(dst)
(HERE/'before-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Source closure frozen:',len(manifest))
