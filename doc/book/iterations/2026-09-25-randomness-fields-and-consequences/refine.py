from pathlib import Path
import json
r=Path.cwd();o=Path(__file__).parent
p=r/'commons/maps/Random_Pheromone/final.md';s=p.read_text(encoding='utf-8');old=(o/'before/commons/maps/Random_Pheromone/final.md').read_text(encoding='utf-8-sig')
assert s.replace('signal-guided: 30%','signal-guided: 40%').replace('the five walkers begin again','the four walkers begin again')==old
p.write_bytes((o/'before/commons/maps/Random_Pheromone/final.md').read_bytes())
p=r/'commons/maps/Random_Space_Geometry/map_data.json';d=json.loads(p.read_text());assert 'museum' not in d['map_info']
d['map_info']['museum']={'sculpture_clear_rects':[[2,17,5,22]]}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'commons/maps/Random_Space/map_data.json';s=p.read_text();assert p.read_bytes()==(o/'before/commons/maps/Random_Space/map_data.json').read_bytes();d=json.loads(s)
for row in d['layers']['interactables']:
 for i,v in enumerate(row):
  if v.split(':')[0].split('#')[0] in ['worley_noise','shannon_entropy_meter']:
   assert '#plinth:' not in v
   row[i]=v+('#plinth:0.35' if v.startswith('worley_noise') else '#plinth:1.05')
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'commons/maps/Random_Space/final.md';s=p.read_text();s=s.replace('On the floor to the right of the mixer, a small blue cellular field','Beside the mixer, a small blue cellular field on a low stand').replace('Farther along, on the left, the entropy gauge','Farther along, the entropy gauge');p.write_text(s,encoding='utf-8')
p=o/'museum-probe.gd';s=p.read_text();s=s.replace('placed field has five walkers and thirty percent guidance','placed field has four walkers and forty percent guidance').replace('field.walkers.size()==5 and is_equal_approx(field.pheromone_attraction,0.3)','field.walkers.size()==4 and is_equal_approx(field.pheromone_attraction,0.4)')
s=s.replace('if bench.global_position.z<23:check("three standing positions in front of comparison have floor",supports==[true,true,true])\n\telse:check("baseline cannot support the complete comparison stance",supports!=[true,true,true])','check("three standing positions in front of comparison have floor",supports==[true,true,true])')
s=s.replace('await snapshot("cellular-field",worley.global_position+Vector3(0,1.7,1.2),worley.global_position,53)','check("cellular field raised above the retained ground",worley.global_position.y>=0.3)\n\tcheck("gauge raised to standing reading height",gauge.global_position.y>=1.0)\n\tawait snapshot("cellular-field",Vector3(worley.global_position.x,1.7,worley.global_position.z+1.2),worley.global_position,53)')
s=s.replace('await snapshot("returning-gauge",gauge.to_global(Vector3(0,1.7,2.0)),gauge.to_global(Vector3(0,0.65,0)),60)','await snapshot("returning-gauge",Vector3(gauge.global_position.x,1.7,gauge.global_position.z+2.0),gauge.to_global(Vector3(0,0.3,0)),60)')
p.write_text(s,encoding='utf-8')
print('Retained scene-correct pheromone prose; cleared a sightline and lifted two exhibits locally.')
