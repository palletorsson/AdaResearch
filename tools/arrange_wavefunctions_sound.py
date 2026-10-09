"""Hand-authored arrangement of the existing sound collection; no synthesis changes."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-effect-sound-a-phase-you-can-hear'

def main():
    old=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    d=json.loads(json.dumps(old))
    w,depth=24,32
    structure=[['1']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [10,11,12]:structure[0][x]=structure[-1][x]='w'
    art=[['']*w for _ in range(depth)]
    utilities=[['']*w for _ in range(depth)]
    # source x,z -> destination x,z, replacement token (or retain), low plinth
    placements=[
        (1,1,2,3,None,False),(2,2,8,3,None,False),
        (3,2,3,17,'AudioContr:180:1#preset:basic_mono',False),
        (5,2,9,3,None,False),(10,2,16,3,None,False),
        (11,2,20,17,'GlassRack:180#config:simple_tube',True),
        (2,3,3,8,None,False),
        (3,3,7,17,'AudioContr:180:1#config:mario_rack',False),
        (5,3,4,5,'RackSineBasic:180:1',False),
        (10,3,18,26,'cable_builder:180',False),
        (11,3,20,21,'VRAudioMonitor:180',True),
        (8,4,17,3,None,False),(9,4,18,3,None,False),
        (10,4,20,28,'dark_sphere',True),
        (5,5,3,22,'Rack303Acid:180:1',False),
        (6,5,7,26,'rack_room:180',False),
        (7,5,7,22,'RackMoogBass:180:1',False),
        (8,5,11,22,'RackDX7Piano:180:1',False),
        (9,5,15,17,'AudioContr:180:1#config:heartbeat_rack',False),
        (10,5,3,26,'audio_catalog_tablet:180:1',False),
        (11,5,15,22,'AudioContr:180:1#config:slider_rack',False),
        (6,6,19,12,'wave_interference_3d:0:-0.5',True),
        (11,7,21,8,None,False),
        (3,8,18,5,'harmonic_distance_table:180',True),
        (5,8,21,5,'chord_tension_spring:180',True),
        (9,8,19,8,'timbre_sculptor:180#waveform:square#sound:near',True),
        (3,9,21,24,'GlassRack:180:0.7#config:distillation_rack',False),
        (2,10,3,12,'MarioSoundController:180#mode:techno_kick',True),
        (2,11,6,12,'MarioSoundController:180#mode:laser_zap',True),
        (5,11,11,17,'MelodyChaser3D:180:0.4#scale:fifths_circle#tempo:60',True),
        (8,11,12,9,None,False),
        (2,12,9,12,'MarioSoundController:180#mode:sine_bell',True),
        (4,12,3,28,'lab_table',False),
    ]
    for ox,oz,x,z,token,plinth in placements:
        assert not art[z][x]
        art[z][x]=token or old['layers']['interactables'][oz][ox]
        assert art[z][x]
        if plinth:structure[z][x]='2'
    ids=lambda a:Counter(t.split(':')[0].split('#')[0] for row in a for t in row if str(t).strip())
    assert ids(art)==ids(old['layers']['interactables'])
    utilities[2][11]='s';utilities[3][11]='sub:map';utilities[29][11]='t'
    d['layers']={'structure':structure,'utilities':utilities,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':4}
    d['map_info']['title']='One wave inside another'
    d['map_info']['museum']={'wall_height':3,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[2,2,22,30]]}
    d['documentation']={'summary':'One phase operation among a larger sound collection.','layout':'24x32m: two-desk instrument at (12,9); clear working bay at hall-local (7,0,10). Sound racks in rear bays, level entrance and exit.','preserved_artifact_placements':sum(ids(art).values()),'student_subject':'Height selects phase depth; a trigger compares a retained note with a captured changed note.','runtime_note':'Instrument synthesis and controls unchanged. Existing unused grid ramp removed from the level floor.'}
    (ROOT/'commons/maps/WaveFunctions_Effect_Sound/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Arranged',sum(ids(art).values()),'preserved placements in',w,'x',depth)

if __name__=='__main__':main()
