"""Read-only content-chain inventory. Does not certify runtime behaviour."""
from pathlib import Path
import hashlib,json,re
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/course/uncertainty-plan';O.mkdir(exist_ok=True)
spine=json.loads((R/'commons/maps/curriculum_spine.json').read_text(encoding='utf-8'))['spine']['sequences']
sequences=[];placements={};registry={}
for row in spine:
 seq=json.loads((R/'commons/maps/sequences'/f"{row['name']}.json").read_text(encoding='utf-8'))['sequences'][row['name']]
 sequences.append({'order':row['order'],'id':row['name'],'maps':seq['maps']})
 for m in seq['maps']:
  data=json.loads((R/'commons/maps'/m/'map_data.json').read_text(encoding='utf-8'))
  for cells in data['layers'].get('interactables',[]):
   for token in cells:
    if not isinstance(token,str) or not token.strip():continue
    key=re.split('[:#]',token)[0]
    placements.setdefault(key,[]).append({'sequence':row['name'],'map':m,'token':token})
for p in (R/'commons/artifacts/registry').glob('*.json'):
 try:d=json.loads(p.read_text(encoding='utf-8-sig'))
 except (ValueError,UnicodeError):continue
 for key,item in d.get('artifacts',{}).items():
  if isinstance(item,dict):registry.setdefault(key,[]).append({'registry':p.relative_to(R).as_posix(),'scene':item.get('scene')})
keys=['euler_drift','numerical_integration','riemann_sum_workbench','gradient_descent_well','ambient_patch','monte_carlo_dartboard','monte_carlo_estimator','glitch_mirror','textureglitch','digital_materiality_glitch','fuzzy_cloud','the_threshold_opinion','shader_10_reactiondiffusion','ca_bridge','resolution_colonnade','geometry_noise','pendulum_noise','navigator_noise']
inventory=[]
for key in keys:
 entries=registry.get(key,[])
 for entry in entries:
  scene=entry.get('scene');p=R/scene.removeprefix('res://') if scene else None
  entry['scene_exists']=bool(p and p.exists())
  entry['scripts']=re.findall(r'type="Script"[^\n]*?path="(res://[^\"]+)"',p.read_text(encoding='utf-8')) if p and p.exists() else []
 inventory.append({'key':key,'registrations':entries,'spine_placements':placements.get(key,[])})
data={'date':'2026-10-09','scope':'Static content-chain audit of selected candidates; runtime receipts for G0, G1, G2 and CA are linked separately. Missing search hits are not proof of absence.','spine_count':len(spine),'sequences':sequences,'inventory':inventory,'spine_sha256':hashlib.sha256((R/'commons/maps/curriculum_spine.json').read_bytes()).hexdigest()}
(O/'inventory.json').write_text(json.dumps(data,indent=2,ensure_ascii=False),encoding='utf-8')
for v in inventory:print(v['key'], 'scene='+str(any(r['scene_exists'] for r in v['registrations'])), 'maps='+','.join(dict.fromkeys(p['map'] for p in v['spine_placements'])))
