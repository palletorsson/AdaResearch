"""Retain all ten authored placements; make the playing floor and views usable."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-air-music-after-contact'

def main():
    old=json.loads((OUT/'before/map_data.json').read_text(encoding='utf8'))
    d=json.loads(json.dumps(old)); w,depth=18,22
    structure=[['1']*w for _ in range(depth)]
    art=[['']*w for _ in range(depth)]; utilities=[['']*w for _ in range(depth)]
    for z in range(depth):structure[z][0]=structure[z][-1]='w'
    for x in range(w):
        if x not in [8,9,10]:structure[0][x]=structure[-1][x]='w'
    art[6][5]='resonating_metallophone:180#stand:table'
    art[6][13]='air_music_display_case:180:1'
    art[12][3]='GlassRack:0:0.7#config:spiral_tube'
    art[12][14]='GlassRack:-90:0.7#config:fractional_distillation'
    art[13][3]='lab_table';art[13][14]='lab_table'
    art[16][5]='SystemsMusicTest:180:0.5:0.9'
    art[18][14]='dark_sphere';structure[18][14]='2'
    art[15][14]='RackAmbientDrone:180:1'
    art[19][3]='BigPipeSystem:90:1#path:straight,straight,up,straight,down,straight,straight'
    utilities[2][9]='s'; utilities[3][9]='sub:map';utilities[20][9]='t'
    ids=lambda rows:Counter(t.split(':')[0].split('#')[0] for row in rows for t in row if str(t).strip())
    assert ids(art)==ids(old['layers']['interactables'])
    d['layers']={'structure':structure,'utilities':utilities,'interactables':art}
    d['map_info']['dimensions']={'width':w,'depth':depth,'max_height':4}
    d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'artifact_placement':'map','sculpture_clear_rects':[[2,2,16,20]]}
    d['utility_definitions'].pop('s',None)
    d['documentation']={'summary':'A supported playing floor; strike, withdraw, listen to what continues. All ten authored placements retained.',
        'layout':'18x22m. Metallophone faces the entrance, left of the central route. Air-music display opposite; ambient experiments behind.',
        'student_bay':'Hall-local (13,0,14), yaw180, unit scale. Complete two-bar lesson temporarily installed for captures.',
        'route':'Central x9.5 passage. The former unsupported grid opening is filled; no moving surface was underneath.',
        'preserved_artifact_placements':10}
    (ROOT/'commons/maps/WaveFunctions_AirMusic/map_data.json').write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Air Music: 10 placements retained; supported 18x22m playing floor.')

if __name__=='__main__':main()
