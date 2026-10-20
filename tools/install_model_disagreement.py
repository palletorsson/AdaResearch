"""Install the existing Godot study in the actual Patterns hall, preserving earlier bays."""
from pathlib import Path
import json, shutil
from em_map_halls import derive_row
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-glitch-inside-the-museum'
MAP='Shader_05_Patterns'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def backup(p):
    target=OUT/'before'/p.relative_to(ROOT)
    if not target.exists():target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
def main():
    p=ROOT/f'commons/maps/{MAP}/map_data.json';backup(p);d=read(p)
    if d['map_info']['dimensions']['depth']==31:
        for key,rows in d['layers'].items():
            for row in rows:row.extend(['']*(37-len(row)))
            for z in range(31,62):
                row=['']*37
                if key=='structure':
                    row=['1']*37;row[0]=row[36]='8'
                    if z==31:
                        for x in range(21,37):row[x]='8'
                    if z==61:
                        row=['8']*37
                        for x in range(17,20):row[x]='1'
                rows.append(row)
        assert d['layers']['utilities'][29][10]=='t'
        d['layers']['utilities'][29][10]=''
        d['layers']['utilities'][60][18]='t'
        d['layers']['interactables'][45][28]='model_disagreement:180:0#plinth:0#pin:1#exhibit_scale:0.35#museum_installation:1'
        d['map_info']['dimensions'].update(width=37,depth=62)
        d['map_info']['metadata']['n_artifacts']=6
        d['map_info']['museum']['sculpture_clear_rects'].append([1,31,35,60])
        d['map_info']['museum']['model_disagreement']={'cell':[28,45],'rotation':180,'gallery':[0,31,36,61],'display_scale':.35,'controls_scale':1,'note':'One Godot model, three interventions. Original data and native dials retained. Enter through the old exit, then continue through the new far doorway.'}
        d['utility_definitions']['t']['name']='Next: Queer Materials'
        d['utility_definitions']['t']['description']='Continue from the model gallery to the next shader hall.'
        write(p,d)
    assert d['layers']['interactables'][45][28].startswith('model_disagreement:')
    # An old corner spawn required the museum's safe fallback. Align the actual
    # entry with the first room's open central aisle now that the route grows.
    d['layers']['utilities'][0][0]=''
    d['layers']['utilities'][0][10]='s'
    for x in range(9,12):d['layers']['structure'][0][x]='1'
    # The automatic check-in cross-wall uses the widest room width, which puts
    # its door outside this narrow front bay. The portal system owns access.
    d['map_info']['museum']['gate']=False
    write(p,d)
    p=ROOT/'commons/artifacts/registry/model_disagreement.json';backup(p);d=read(p);e=d['artifacts']['model_disagreement']
    e.update(map_ready=True,include_in_map_data=True,map_sequences=['shaders'],status='Installed in Shader_05_Patterns, rear model gallery',report='doc/book/iterations/2026-10-09-glitch-inside-the-museum/index.html')
    e['description']='A live Godot model study inside the Endless Museum. Turn native dials to change precision, part timestamps and deformation feedback; compare the original and corrected control. Display mesh scaled to fit the gallery; numerical values remain in source model metres.'
    write(p,d)
    p=ROOT/'commons/data/museum/em_plan.json';backup(p);d=read(p)
    for i,r in enumerate(d['plans']):
        if r.get('map')==MAP and r.get('sequence')=='shaders':d['plans'][i]=derive_row(r['pearl'],MAP,r['museum'],r['pearl_index'],r['pearls_total'],'shaders')
    write(p,d)
    print('Installed in Shaders / Patterns. Existing five artifacts and sequence order retained; far exit moved to new rear gallery.')
if __name__=='__main__':main()
