from pathlib import Path
import re,json,hashlib,shutil
b=Path('doc/book/iterations/2026-09-19-randomness-review/ending')
halls=['Random_Space_Geometry','Randomness_Examples_of_Randomness','Random_Pheromone','Random_Space','Random_Game']
regs={};paths=set();chain={}
for p in Path('commons/artifacts/registry').glob('*.json'):
 try:entries=json.loads(p.read_text(encoding='utf-8'))['artifacts']
 except(KeyError,ValueError):continue
 for k,e in entries.items():regs.setdefault(k,[]).append({'registry':p.as_posix(),**e})
for h in halls:
 folder=Path('commons/maps')/h;paths.update(folder.glob('*.md'));paths.add(folder/'map_data.json')
 m=json.loads((folder/'map_data.json').read_text(encoding='utf-8'));items=[]
 for z,row in enumerate(m['layers']['interactables']):
  for x,t in enumerate(row):
   if not isinstance(t,str)or not t.strip():continue
   key=re.split('[:#]',t)[0];entries=[]
   for e in regs.get(key,[]):
    p=Path(e['scene'].removeprefix('res://'));scripts=[];paths.add(p);paths.add(Path(e['registry']))
    if p.exists():scripts=re.findall(r'path="(res://[^\"]+\.gd)"',p.read_text(encoding='utf-8'));paths.update(Path(s.removeprefix('res://'))for s in scripts)
    entries.append({'registry':e['registry'],'scene':p.as_posix(),'exists':p.exists(),'map_ready':e.get('map_ready',False),'scripts':scripts})
   items.append({'cell':[x,z],'token':t,'key':key,'entries':entries})
 chain[h]=items
for p in ['commons/primitives/cubes/ProjectileCube.gd','commons/primitives/cubes/projectile_cube.tscn','commons/data/artifact_roles.json','commons/scenes/endless_museum.gd','commons/data/museum/em_plan.json','commons/data/em_layout.json']:
 if Path(p).exists():paths.add(Path(p))
hashes={}
for p in paths:
 if not p.exists():continue
 dest=b/'before-source'/p;dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():shutil.copy2(p,dest)
 hashes[p.as_posix()]=hashlib.sha256(dest.read_bytes()).hexdigest()
(b/'before-source-sha256.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
(b/'source-chain.json').write_text(json.dumps(chain,indent=2),encoding='utf-8')
(b/'registry-baseline.json').write_text(json.dumps({k:regs[k]for k in ['perlin_noise_bridge','pheromone_terrain','noise_mixer','extreme_randomness','monte_carlo_dartboard']},indent=2),encoding='utf-8')
print({h:len(v)for h,v in chain.items()});print('frozen',len(hashes))
