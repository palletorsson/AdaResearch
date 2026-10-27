"""Initial Sound/Bernini/Cage transfer only. Refuses to overwrite arranged floors."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'commons/void/trials/wavefunctions_03'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rooms=read(folder/'rooms.json');inv=read(folder/'source-inventory.json')
assert not any(f['artifacts'] for f in rooms['floors']), 'Existing arrangements must be preserved'
# Every occurrence has its own identity, including duplicate controls and cubes.
positions={
'f1_BigPipeSystem_2_3':(-17,-11),
'f1_pick_up_cube_8_3':(-3,8),'f1_pick_up_cube_9_3':(-2,8),
'f1_pick_up_cube_16_3':(2,8),'f1_pick_up_cube_17_3':(3,8),'f1_pick_up_cube_18_3':(4,8),
'f1_RackSineBasic_4_5':(-17,9),'f1_harmonic_distance_table_18_5':(6,-8),
'f1_chord_tension_spring_21_5':(11,-8),'f1_pick_up_cube_3_8':(-17,1),
'f1_timbre_sculptor_19_8':(16,-8),'f1_pick_up_cube_21_8':(17,1),
'f1_DualBallFMController_12_9':(0,3),
'f1_MarioSoundController_3_12':(-16,-5),'f1_MarioSoundController_6_12':(-11,-7),
'f1_MarioSoundController_9_12':(-6,-8),'f1_wave_interference_3d_19_12':(3,-11),
'f1_AudioContr_3_17':(-17,5),'f1_AudioContr_7_17':(-12,5),
'f1_MelodyChaser3D_11_17':(0,-7),'f1_AudioContr_15_17':(11,5),
'f1_GlassRack_20_17':(16,5),'f1_VRAudioMonitor_20_21':(16,10),
'f1_Rack303Acid_3_22':(-12,9),'f1_RackMoogBass_7_22':(-7,9),
'f1_RackDX7Piano_11_22':(7,9),'f1_AudioContr_15_22':(11,10),
'f1_GlassRack_21_24':(18,-3),'f1_audio_catalog_tablet_3_26':(-3,-3),
'f1_rack_room_7_26':(3,-3),'f1_cable_builder_18_26':(12,-12),
'f1_lab_table_3_28':(-17,-1),'f1_dark_sphere_20_28':(4,12),
'f2_ElphabaDress_17_7':(14,7),'f2_bernini_columns_11_16':(0,-6),
'f2_dark_sphere_4_24':(-3,10),'f2_vowel_sound_board_17_26':(10,8),
'f3_dual_display_test_6_3':(-14,8),'f3_dark_sphere_5_10':(-3,11),
'f3_john_cage_tech_noir_16_18':(4,-1),'f3_ruth_asawa_sculpture_5_19':(-17,-7)
}
heights={'BigPipeSystem':0,'harmonic_distance_table':.65,'chord_tension_spring':1,'timbre_sculptor':1.3,'MarioSoundController':.8,'VRAudioMonitor':1.25,'ruth_asawa_sculpture':5.25,'wave_interference_3d':.3}
for p in inv['placements']:
 token,*config=p['token'].split('#');v=token.split(':');x,z=positions[p['id']]
 settings={k:val or 'true' for k,_,val in [s.partition(':') for s in config]}
 item=dict(id=p['id'],artifact=p['artifact'],position=[x,z],station=('N' if z<0 else 'S')+('W' if x<0 else 'E'),facing=(float(v[1] or 0)+180)%360 if len(v)>1 else 0,height=heights.get(p['artifact'],float(v[2] or 0) if len(v)>2 else 0),scale=float(v[3] or 1) if len(v)>3 else 1,config=settings)
 if p['artifact'] in ['john_cage_tech_noir','bernini_columns','dual_display_test']:item['facing']=0
 rooms['floors'][p['floor']]['artifacts'].append(item)
(folder/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
print('Placed',len(inv['placements']),'original occurrences')
