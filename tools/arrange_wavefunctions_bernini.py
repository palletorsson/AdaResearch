"""Keep the four exhibits; make room to approach and walk between the nine shafts."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-bernini-a-turn-through-height'

def main():
    old=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    d=json.loads(json.dumps(old))
    w,depth=22,30
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)]
    utilities=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [10,11,12]:structure[0][x]=structure[-1][x]='w'
    art[16][11]='bernini_columns:0:0.65'
    art[7][17]='ElphabaDress:0:0.914'
    structure[7][17]='2'
    art[24][4]='dark_sphere'
    structure[24][4]='2'
    art[26][17]='vowel_sound_board:180:1.3#say:right here, right now#repeat:true'
    utilities[2][11]='s';utilities[3][11]='sub:map';utilities[27][11]='t'
    ids=lambda rows:Counter(t.split(':')[0].split('#')[0] for row in rows for t in row if str(t).strip())
    assert ids(art)==ids(old['layers']['interactables'])
    d['layers']={'structure':structure,'utilities':utilities,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':10}
    d['map_info']['title']='A movement kept in a column'
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[2,2,20,28]]}
    d['utility_definitions'].pop('s',None)
    d['documentation']={'summary':'Nine existing columns, a clear forecourt, and a small learner shaft beside the entrance.','layout':'22x30m. Colonnade at (11,16), its bases lifted clear of the floor. Four authored exhibits retained. Dress on a plinth; voice lowered.','student_bay':'Hall-local (5,0,10), yaw180, unit scale. Temporary learner installation in captures; not another authored exhibit.','route':'Walk between the nine columns, then reach the supported exit at (11,27).','preserved_artifact_placements':4}
    (ROOT/'commons/maps/Wavefunctions_Bernini/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Bernini: four exhibits retained, nine full-size columns in 22x30m.')

if __name__=='__main__':main()
