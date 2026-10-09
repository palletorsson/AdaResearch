from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-synthesis-five-amounts'

def main():
    d=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    old=d['layers']['interactables'];w,depth=24,32
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)];utility=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [10,11,12]:structure[0][x]=structure[-1][x]='w'
    placements=[
        (6,6,'additive_wave_demo:180#stand:bench#waveform:sawtooth#name_after_compare:true'),
        (5,11,'air_music_display_case:180:0.4'),
        (3,15,'dna_specimen:180'),(5,15,'GlassRack:180:0.01#config:spiral_tube'),
        (7,15,'lissajous_curves:0:0.105:0.1'),
        (3,18,'holographicdisplay:180:0.07'),(5,18,'electronicscales:180'),
        (7,18,'biomagneticresonator:180:0.08'),
        (3,21,'seismograph:180:0.08'),(5,21,'spring_demo:180:0.01'),
        (7,21,'UnitCircleTrig:180:0.42:0.1'),
        (6,27,'double_helix_scene:0:0.25:0.5#trail_drop:4.8'),
        (16,15,'hallway_scene:0:0:0.03'),
        (16,20,'ambient_patch:180'),(20,20,'record_room:180'),
        (16,27,'synthesis_stand:0:0:0.04#subject:hallway_scene#mode:hero'),
        (20,14,'samplevialrack:180'),(20,16,'oscilloscope:180'),
        (20,23,'petri_dish_worms:180'),(20,25,'atmosphericmonitoring:180'),
        (20,27,'chemicalapparatus:180'),(20,29,'multimeter:180'),
        (3,24,'chladni_plate:180:0.01'),(9,24,'microscope:180'),
        (16,23,'SoundscapeRadioRack:180:0.325'),(9,28,'dark_sphere')]
    table={(x,z)for x,z,_ in placements if (x in [3,5,7] and z in [15,18,21]) or (x==20 and z!=20) or (x,z)in [(3,24),(9,24),(16,23),(5,11)]}
    for x,z,token in placements:
        art[z][x]=token
        if (x,z)in table:structure[z][x]='2'
    # Broad support for the 2.1 metre glass case; small specimens share long benches.
    for z in [10,11,12]:
        for x in [4,5,6]:structure[z][x]='2'
    for z in [15,18,21]:
        for x in range(3,8):structure[z][x]='2'
    for z in [14,15,16,23,24,25,26,27,28,29]:structure[z][20]='2'
    utility[2][11]='s';utility[3][11]='sub:map';utility[30][11]='t'
    ids=lambda rows:Counter(v.split(':')[0].split('#')[0]for r in rows for v in r if v.strip())
    assert ids(old)==ids(art)
    d['layers']={'structure':structure,'utilities':utility,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':5}
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[1,1,22,30]],'props_deny':['bench']}
    d['documentation']={'summary':'Five amounts: a visual weighted sum and a separate room-memory encounter.',
      'layout':'24x32m. Primary bench faces arrival; learner bay hall-local (16,0,11), yaw180. Specimen benches flank a clear central passage. Slow Circuits and Room Memory approach on the right; scaled spatial models and helix toward the exit.',
      'preserved_artifact_placements':len(placements),'tutorial_scope':'Five nonnegative harmonic amounts, fixed common phase, copying a baseline. Other specimens remain independent.'}
    (ROOT/'commons/maps/WaveFunctions_Synthesis_Lab/map_data.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Retained',len(placements),'authored exhibits; supported laboratory benches and clear route.')
if __name__=='__main__':main()
