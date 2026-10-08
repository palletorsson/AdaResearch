"""One-time authored merge; snapshots preserve both inputs before rewriting."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAPS = ROOT / 'commons/maps'
ARCHIVE = ROOT / 'doc/space/translation-merge-2026-09-09/before'

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1)+'\n', encoding='utf-8')

def main():
    for name in ('Trans_Translation', 'Trans_AxisDecomposition'):
        for src in (MAPS/name).glob('*'):
            if src.is_file() and src.suffix in ('.json', '.md'):
                dest = ARCHIVE/name/src.name
                if not dest.exists():
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(src.read_bytes())
    original = json.loads((ARCHIVE/'Trans_Translation/map_data.json').read_text(encoding='utf-8'))
    width, depth = 15, 55
    layers = {k: [['0' if k=='structure' else '' for _ in range(width)] for _ in range(depth)] for k in ('structure','utilities','interactables')}
    s,u,a = (layers[k] for k in ('structure','utilities','interactables'))
    def platform(x0,x1,z0,z1,height=1):
        for z in range(z0,z1+1):
            for x in range(x0,x1+1): s[z][x]=str(height)
    # Broad entrance/exit terraces, narrow intermediate islands and two levels.
    platform(1,13,0,3); platform(2,4,4,4)
    platform(2,4,10,13); platform(10,12,13,16)
    platform(10,12,18,21,4); platform(10,12,28,31,4)
    platform(2,4,31,34,4); platform(2,4,38,39)
    platform(10,12,47,50); platform(1,13,51,54)
    # Edge walls mark the arena, without a continuous floor around the course.
    for z in range(depth): s[z][0]=s[z][-1]='2'
    for x in range(width):
        if x not in (2,3,4):s[0][x]='2'
        if x not in (10,11,12):s[-1][x]='2'
    rides = [
        ('z_first',[3,0,4],[3,0,10],'tc:6:z#deck:0',[[3,1,6],[3,1,8]]),
        ('x_sideways',[3,0,13],[11,0,13],'tc:8:x#deck:0',[[6,1,13],[8,1,13]]),
        ('y_lift',[11,0,17],[11,3,17],'tc:3:y#deck:0',[[11,2.2,17]]),
        ('z_high',[11,3,21],[11,3,28],'tc:7:z#deck:3',[[11,4,23],[11,4,26]]),
        ('x_return',[11,3,31],[3,3,31],'tc:8:-x#deck:3',[[8,4,31],[6,4,31]]),
        ('y_descent',[3,3,35],[3,0,37],'tc:3.6055513:0,-3,2#deck:3',[[3,2.5,36]]),
        ('xz_diagonal',[3,0,39],[11,0,47],'tc:11.3137085:1,0,1#deck:0',[[5,1,41],[7,1,43],[9,1,45]]),
    ]
    course=[]
    for name,start,end,token,pickups in rides:
        x,y,z=start;u[z][x]=token
        course.append(dict(id=name,start=start,end=end,pickups=pickups))
        for px,py,pz in pickups:
            h=int(s[pz][px]);base=h-1 if h else -0.5
            # Shared utility cells are reserved at grid height one by the
            # generator before interactables are placed, even over a shaft.
            if u[pz][px].startswith('tc:'): base=0
            a[pz][px]=f'pick_up_cube:0:{py-base:g}#motion:slide#hold:collect'
    for x,z,title in [(2,2,'01  DEPTH / Z'),(2,11,'02  SIDEWAYS / X'),(10,15,'03  UP / Y'),(10,19,'04  DEPTH AGAIN'),(10,29,'05  X / RETURN'),(2,33,'06  DOWN + FORWARD / Y + Z'),(2,38,'07  X + Z / TOGETHER'),(9,52,'WHAT MOVED WITH YOU?')]:
        u[z][x]='3t:'+title
    a[2][5]='z_translation_cube:180:0.7'
    a[2][8]='x_translation_cube:180:0.7'
    a[2][11]='y_translation_cube:180:0.7'
    u[1][3]='sp';u[53][11]='t'
    original['map_info'].update(name='Trans_Translation',lookup_name='Trans_Translation',description='Seven rides through x, y and z: depth, sideways, lift, high crossing, reverse x, descent and a final x/z diagonal. Thirteen vertically bobbing pickups hang along the journeys. Translation only: the carriers never rotate or scale.',dimensions=dict(width=width,depth=depth,max_height=4))
    original['map_info']['metadata']=dict(category='tutorial',estimated_time='6-9 minutes',merged_from=['Trans_Translation','Trans_AxisDecomposition'],n_artifacts=16,learning_objectives=['Ride translations along positive and negative axes','Compare the same z displacement at different heights','Collect pickups through carried contact','Compose x and z without rotation'])
    original['map_info']['museum']['simulation'].update(grid=True,staged=True,fire=True)
    original['layers']=layers
    original['translation_course']=dict(version=1,coordinate_convention='x, standing deck y above arena ground, z; pickup positions are scene origins (visible cube centre is 0.5 m above)',rides=course)
    original['documentation']=dict(summary='One longer course compiled from Translation and AxisDecomposition.',objective='Learn the axes through transport and collection.',layout='15 x 55 m, ground level and a three-metre upper route, seven ferries and thirteen pickups.')
    write(MAPS/'Trans_Translation/map_data.json',original)

if __name__=='__main__': main()
