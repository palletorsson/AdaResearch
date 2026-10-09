from pathlib import Path
import json,hashlib,shutil,re
root=Path.cwd();base=Path('doc/book/iterations/2026-09-19-wavefunctions-review/ending')
halls=['WaveFunctions_AirMusic','Wavefunctions_Sky_Stairs','WaveFunctions_TrigWalkingPath','WaveFunctions_Synthesis_Lab']
paths=[]
for hall in halls:paths += list((Path('commons/maps')/hall).glob('*.md'))+[Path('commons/maps')/hall/'map_data.json']
paths += [Path(x) for x in ['algorithms/wavefunctions/resonance/ResonatingMetallophone.gd','algorithms/wavefunctions/resonance/ResonatingBar.gd','algorithms/wavefunctions/resonance/CombinedWaveVisualizer.gd','algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd','algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd','algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.tscn','algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.gd','algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.tscn','commons/artifacts/additive_wave_demo/additive_wave_demo.gd','commons/artifacts/additive_wave_demo/additive_wave_demo.tscn','commons/data/artifact_roles.json','commons/data/em_layout.json','commons/data/museum/em_plan.json','commons/scenes/endless_museum.gd']]
paths+=list(Path('commons/artifacts/registry').glob('*.json'))
hashes={}
for p in paths:
 if not p.exists():continue
 dest=base/'before-source'/p;dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():shutil.copy2(p,dest)
 hashes[p.as_posix()]=hashlib.sha256(dest.read_bytes()).hexdigest()
(base/'before-source-sha256.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
registry={}
for p in Path('commons/artifacts/registry').glob('*.json'):
 try:rs=json.loads(p.read_text(encoding='utf-8'))['artifacts']
 except (KeyError,ValueError):continue
 for key,r in rs.items():registry.setdefault(key,[]).append({'file':p.as_posix(),**r})
inv={}
for hall in halls:
 m=json.loads((Path('commons/maps')/hall/'map_data.json').read_text(encoding='utf-8'));items=[]
 layers=m['layers'];grid=layers['interactables']
 for z,row in enumerate(grid):
  for x,tok in enumerate(row):
   if not isinstance(tok,str) or not tok.strip():continue
   key=re.split('[:#]',tok)[0];rs=registry.get(key,[])
   entries=[]
   for r in rs:
    p=Path(r.get('scene','').removeprefix('res://'));exists=p.is_file();scripts=[]
    if exists:
     scripts=re.findall(r'path="(res://[^\"]+\.gd)"',p.read_text(encoding='utf-8'))
    entries.append({'registry':r['file'],'scene':str(p),'exists':exists,'map_ready':r.get('map_ready',False),'include_in_map_data':r.get('include_in_map_data',False),'scripts':scripts})
   items.append({'cell':[x,z],'token':tok,'entries':entries})
 inv[hall]=items
(base/'source-chain.json').write_text(json.dumps(inv,indent=2),encoding='utf-8')
print({h:len(v) for h,v in inv.items()})
for h,v in inv.items():
 for i in v:
  if not i['entries'] or not any(e['exists'] and e['map_ready'] for e in i['entries']):print('ineligible',h,i)
keys=['resonating_metallophone','sine_cylinder_staircase','beat_frequency_demo','TrigWalkingPath','additive_wave_demo']
(base/'registry-baseline.json').write_text(json.dumps({k:registry.get(k,[]) for k in keys},indent=2),encoding='utf-8')
