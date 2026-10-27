"""Initial placement of Codex's three batch-19 maps; native bounds refine it."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
POSITIONS={
'tiling_04':{1:{'drag_catwalk':(0,-7),'fabric_shader_studio':(-9,10),'super_drag_mirror':(0,11),'garment_cutting_table':(12,10),'pulsar_visualizer':(17,4),'standalone_disco':(-16,6),'coloredlines':(14,-9),'RotatingLaser':(-17,-10),'minimalglitch':(-6,-12),'textureglitch':(-6,-5),'glitchcolor':(7,-12),'advancedglitch':(6,-5),'colortrails':(-17,-4),'neon_garden':(17,-3),'strobe_lasers':(-17,12),'disco_lights':(6,4),'one_bulb_room':(-6,4),'laser_turret':(17,-14)}},
'forces_02':{1:{'force_hall_04':(-4,12),'euler_drift':(0,5),'launch_arc':(3,10),'bubble_blaster':(-5,4),'force_trial_catapult':(-15,9),'force_trial_pipe':(15,9),'catapult':(-16,-8),'force_play_torque':(0,-9),'human_catapult':(15,-8),'firework_burst':(0,-2)},2:{'force_hall_05':(-2,13),'force_play_mass':(-14,9),'force_play_trolley':(0,9),'force_play_puzzle':(14,9),'force_mower':(.8,12)}}}
for seq,levels in POSITIONS.items():
 folder=ROOT/'commons/void/trials'/seq
 inventory=json.loads((folder/'source-inventory.json').read_text(encoding='utf-8-sig'))
 rooms=json.loads((folder/'rooms.json').read_text(encoding='utf-8-sig'))
 for level,positions in levels.items():
  floor=rooms['floors'][level];floor['artifacts']=[]
  for p in inventory['placements']:
   if p['floor']!=level:continue
   token,*config=p['token'].split('#');v=token.split(':');x,z=positions[p['artifact']]
   settings={k:val or 'true' for k,_,val in [s.partition(':') for s in config]}
   floor['artifacts'].append(dict(id=p['id'],artifact=p['artifact'],position=[x,z],station=('N' if z<0 else 'S')+('W' if x<0 else 'E'),facing=(float(v[1] or 0)+180)%360 if len(v)>1 else 180,height=float(v[2] or 0) if len(v)>2 else 0,scale=float(v[3] or 1) if len(v)>3 else 1,config=settings))
  (folder/f'floor-{level}.json').write_text(json.dumps(floor,indent=2)+'\n',encoding='utf-8')
 (folder/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
