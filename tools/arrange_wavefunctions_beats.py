from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-beats-a-difference-in-time'

def main():
    d=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    old=d['layers']['interactables'];w,depth=34,48
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)];utility=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [15,16,17]:structure[0][x]=structure[-1][x]='w'
    for z in range(15,45):
        for x in range(2,12):structure[z][x]='0'
    art[7][7]='beat_frequency_demo:180:0.05:2'
    art[28][7]='TrigWalkingPath:0:2.7'
    art[19][24]='sine_oscillation:180:1.5'
    art[19][28]='lissajous_curves:0:1.6'
    art[33][25]='wave_interference:180:1.4:0.45'
    art[42][28]='dark_sphere';structure[42][28]='2'
    utility[2][16]='s';utility[3][16]='sub:map';utility[46][16]='t'
    ids=lambda rows:Counter(t.split(':')[0].split('#')[0] for r in rows for t in r if t.strip())
    assert ids(old)==ids(art)
    d['layers']={'structure':structure,'utilities':utility,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':8}
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[1,1,32,46]],
        'basin':{'depth':3.2,'glass':False,'fire':False,'rects':[[2,15,10,30]],'ramps':[
            {'rect':[4.5,15,6,1.5],'heights':[0,0]},
            {'rect':[4.5,40.5,6,4.5],'heights':[-1.2,0]},
            {'rect':[2,15,1.5,10],'heights':[0,-3.2]}]}}
    d['utility_definitions'].pop('s',None)
    d['documentation']={'summary':'Beats: changing relation between two signals; finite walking paths remain secondary.',
        'layout':'34x48m. Beat controls face arrival; learner bay hall-local (23,0,12), yaw180. Full 24m circulating paths occupy an open catch basin, with a near bridge, far ramp and side descent. Separate later visual studies.',
        'preserved_artifact_placements':6,'limits':'Floor-level access and basin ramps tested; full moving-path traversal and headset comfort require playtesting.'}
    (ROOT/'commons/maps/WaveFunctions_TrigWalkingPath/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Six exhibits preserved; two comparison bays, full-length path basin, clear central route.')

if __name__=='__main__':main()
