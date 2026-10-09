"""Give the existing helix a grounded entry and space around its full extent."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-sky-stairs-a-place-for-a-foot'

def main():
    old=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    d=json.loads(json.dumps(old)); w,depth=24,26
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)]; utilities=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [11,12,13]:structure[0][x]=structure[-1][x]='w'
    art[16][7]='sine_cylinder_staircase:0:0'
    art[6][5]='cube_scene:0:0.5';structure[6][5]='2'
    art[21][6]='dark_sphere';structure[21][6]='2'
    # A continuous one-metre support under the whole 3 x 11 specimen array.
    for z in range(13,22):
        for x in range(18,21):structure[z][x]='2'
    art[17][19]='math_objects:0:0'
    utilities[2][12]='s';utilities[3][12]='sub:map';utilities[24][12]='t'
    ids=lambda rows:Counter(t.split(':')[0].split('#')[0] for row in rows for t in row if str(t).strip())
    assert ids(art)==ids(old['layers']['interactables'])
    d['layers']={'structure':structure,'utilities':utilities,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':12}
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[2,2,22,24]]}
    d['map_info']['description']='One helical stair with sine-modulated radius and uniform rise, approached from a supported viewing floor. Four existing exhibits retained. Compare the full sculpture with a short student-built tread study; full ascent and headset comfort remain unverified.'
    d['utility_definitions'].pop('s',None)
    d['documentation']={'summary':'Sky Stairs: sampled positions need width, orientation and support.',
        'layout':'24x26m. Full existing helix free of enclosing grid walls; first tread top meets floor. Cube at hand height; mathematical specimens on a continuous raised support.',
        'student_bay':'Hall-local (16,0,10), yaw0, unit scale. Exact printed quarter-turn study installed temporarily for captures.',
        'route':'Central x12.5 passage from entry to exit, with viewing paths to the base. No upper platform or complete climb is claimed.',
        'preserved_artifact_placements':4}
    (ROOT/'commons/maps/Wavefunctions_Sky_Stairs/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Sky Stairs: four placements retained; supported 24x26m viewing floor.')

if __name__=='__main__':main()
