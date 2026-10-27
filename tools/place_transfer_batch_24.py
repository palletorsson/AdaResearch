"""Batch 24 initial transfer. Preserve source tokens; never overwrite curation."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POSITIONS={
 'wavefunctions_05':[
  {'beat_frequency_demo':(-3,7),'sine_oscillation':(4,6),'lissajous_curves':(15,7),
   'TrigWalkingPath':(-17,0),'wave_interference':(6,-9),'dark_sphere':(4,12)},
  {'additive_wave_demo':(0,7),'air_music_display_case':(-16,8),'samplevialrack':(16,-10),
   'dna_specimen':(-18,-10),'GlassRack':(-14,-10),'lissajous_curves':(-10,-10),
   'hallway_scene':(8,-10),'oscilloscope':(12,-10),'holographicdisplay':(-18,-5),
   'electronicscales':(-15,-5),'biomagneticresonator':(-5,-10),'ambient_patch':(2,-10),
   'record_room':(17,-5),'seismograph':(-18,0),'spring_demo':(-15,0),
   'UnitCircleTrig':(-2,-10),'SoundscapeRadioRack':(6,-5),'petri_dish_worms':(16,0),
   'chladni_plate':(-6,5),'microscope':(5,5),'atmosphericmonitoring':(16,5),
   'double_helix_scene':(-8,10),'synthesis_stand':(7,10),'chemicalapparatus':(12,10),
   'dark_sphere':(4,12),'multimeter':(16,10)}],
 'randomness_02':[
  {'shannon_entropy_meter':(-15,5),'entropy_jar_states':(-15,10),'entropy_jar':(-18,2),
   'prefab_disorder':(15,-10),'entropy_sorting_table':(16,0),'entropy_compartments':(16,-5),
   'hardware_entropy_decay':(-17,-2),'entropy_axiom':(14,8.5),'entropy_ruin':(-15,-9),
   'signal_room':(0,-2.5)}]
}
for trial, floors in POSITIONS.items():
 folder=ROOT/'commons/void/trials'/trial
 rooms=json.loads((folder/'rooms.json').read_text(encoding='utf-8-sig'))
 inv=json.loads((folder/'source-inventory.json').read_text(encoding='utf-8-sig'))
 assert not any(f['artifacts'] for f in rooms['floors']), f'{trial}: preserve existing edits'
 for p in inv['placements']:
  token,*cfg=p['token'].split('#'); parts=token.split(':')
  x,z=floors[p['floor']-1][p['artifact']]
  config={k:v or 'true' for k,_,v in [s.partition(':') for s in cfg]}
  item={'id':p['id'],'artifact':p['artifact'],'position':[x,z],
    'station':('N' if z<0 else 'S')+('W' if x<0 else 'E'),
    'facing':(float(parts[1] or 0)+180)%360 if len(parts)>1 else 0,
    'height':float(parts[2] or 0) if len(parts)>2 else 0,
    'scale':float(parts[3] or 1) if len(parts)>3 else 1,'config':config}
  rooms['floors'][p['floor']]['artifacts'].append(item)
 (folder/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
 print(trial,len(inv['placements']),'original occurrences placed')
