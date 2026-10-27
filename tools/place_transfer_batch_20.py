"""Initial Codex placements. Do not rerun over a curated or measured layout."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'commons/void/trials/forces_03'
positions={
1:{'force_hall_08':(-4,14),'force_play_springs':(-4,9),'force_play_swings':(0,-10.5),'force_play_constraints':(33,4),'pendulum_noise':(-17,0),'SpringSuspension':(15,10),'spring_tower':(0,0)},
2:{'force_hall_09':(-4,14),'phase_rod_array':(-8,-9),'force_trial_conveyor':(7,-9)},
3:{'force_hall_10':(-4,14),'force_play_mutual':(-31,0),'force_play_magnet':(0,2),'force_play_tower':(16,9),'force_play_gravity':(0,-11),'orbit_walk':(-14,10)}
}
rooms=json.loads((folder/'rooms.json').read_text(encoding='utf-8-sig'))
inv=json.loads((folder/'source-inventory.json').read_text(encoding='utf-8-sig'))
for level,coords in positions.items():
 floor=rooms['floors'][level];floor['artifacts']=[]
 for p in inv['placements']:
  if p['floor']!=level:continue
  token,*config=p['token'].split('#');v=token.split(':');x,z=coords[p['artifact']]
  settings={k:val or 'true' for k,_,val in [s.partition(':') for s in config]}
  floor['artifacts'].append(dict(id=p['id'],artifact=p['artifact'],position=[x,z],station=('N' if z<0 else 'S')+('W' if x<0 else 'E'),facing=(float(v[1] or 0)+180)%360 if len(v)>1 else 180,height=float(v[2] or 0) if len(v)>2 else 0,scale=float(v[3] or 1) if len(v)>3 else 1,config=settings))
 (folder/f'floor-{level}.json').write_text(json.dumps(floor,indent=2)+'\n',encoding='utf-8')
(folder/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
