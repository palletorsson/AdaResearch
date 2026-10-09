"""Preserve four exhibits; provide a supported listening floor and a learner bay."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-cage-a-score-kept'

def main():
    old=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    d=json.loads(json.dumps(old))
    w,depth=22,28
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)]
    utilities=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [10,11,12]:structure[0][x]=structure[-1][x]='w'
    art[3][6]='dual_display_test:0:0.7#museum_panels:true'
    art[19][5]='ruth_asawa_sculpture:0:11.25'
    art[10][5]='dark_sphere'
    structure[10][5]='2'
    art[18][16]='john_cage_tech_noir:0:0.85'
    utilities[2][11]='s';utilities[3][11]='sub:map';utilities[25][11]='t'
    ids=lambda rows:Counter(t.split(':')[0].split('#')[0] for row in rows for t in row if str(t).strip())
    assert ids(art)==ids(old['layers']['interactables'])
    d['layers']={'structure':structure,'utilities':utilities,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':20}
    d['map_info']['title']='The limits of the unexpected'
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[2,2,20,26]]}
    d['utility_definitions'].pop('s',None)
    d['documentation']={'summary':'Four existing exhibits around a supported listening floor.','layout':'22x28m. Complete wire sculpture lifted above the floor; seven sound orbs lifted to listening height. Original sound generator unchanged.','student_bay':'Hall-local (16,0,10), yaw180, unit scale. Learner score temporarily installed for captures.','route':'Clear central passage at x11.5 from entrance to exit. Original empty grid hole closed; there is no moving surface below it.','preserved_artifact_placements':4}
    (ROOT/'commons/maps/WaveFunctions_John_Cage/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Cage: four exhibits retained, supported 22x28m listening floor.')

if __name__=='__main__':main()
