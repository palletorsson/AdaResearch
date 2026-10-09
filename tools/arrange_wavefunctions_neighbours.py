"""Separate the existing five exhibits and restore a supported museum route."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT/'commons/maps/WaveFunctions_3D_Wave_Propagation/map_data.json'

def main():
    d=json.loads(MAP.read_text(encoding='utf8'))
    if d['map_info'].get('museum',{}).get('basin',{}).get('ramps'):
        print('This earlier layout is superseded by the authored walk-down pool in map_data.json.')
        return
    w,h=24,36
    structure=[['w']+['1']*(w-2)+['w'] for _ in range(h)]
    for z in [0,h-1]:structure[z]=['w']*10+['1']*3+['w']*11
    utilities=[['']*w for _ in range(h)]
    artifacts=[['']*w for _ in range(h)]
    utilities[2][11]='sp';utilities[33][11]='t'
    artifacts[4][5]='film_wave_neighbours:180:0#plinth:0#pin:true'
    artifacts[10][6]='coupled_oscillator_lattice#comparison:true#fabric:bonds'
    artifacts[11][18]='kusama_sine:0:2'
    artifacts[25][12]='wave_propagation_3d:0:0.9#museum:true'
    artifacts[32][18]='dark_sphere'
    d['layers']={'structure':structure,'utilities':utilities,'interactables':artifacts}
    d['map_info']['dimensions']={'width':w,'depth':h,'max_height':5}
    d['map_info']['museum'].update(artifact_placement='map',sculpture_clear_rects=[[1,1,22,34]])
    d['utility_definitions'].pop('s',None)
    d['documentation']={
        'summary':'Wave propagation: a neighbour responds',
        'layout':'24x36 m level museum gallery. Near field: film and coupled lattice, with its real comparison controls on the east edge. Kusama sculpture has a separate right-hand bay. Tiled radial field occupies the rear with an open perimeter route.',
        'objective':'Compare local neighbour coupling with a prescribed radial display. Reconstruct the relationship with a small row of the carried PointBody spheres.',
        'key_elements':['Five earlier authored artifacts retained. No curriculum reordering.',
            'Lattice at (6,10); panel reached from the east. Bonds reveal adjacent relations; independent mode hides them.',
            'Kusama at (18,11), raised 2m. Radial tiles at (12,25), raised 0.9m to keep troughs above the floor.',
            'Spawn (11,2), exit (11,33); level perimeter route avoids moving tiles.',
            'Student bay hall-local (12,0,11), yaw180, scale1. The lesson creates its own row, rods and readout.']}
    MAP.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')

if __name__=='__main__':main()
