"""Install the agreed three-hall expansion; keep other authored placements intact."""
from pathlib import Path
import copy
import json
import hashlib

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent


def read(relative):
    return json.loads((ROOT / relative).read_text(encoding='utf-8-sig'))


def write(relative, value):
    path = ROOT / relative
    before = OUT / 'before' / relative
    if path.exists() and not before.exists():
        before.parent.mkdir(parents=True, exist_ok=True)
        before.write_bytes(path.read_bytes())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def hall(name, width, depth, title, placements, open_roof=False):
    structure = [['w' if x in (0, width-1) or z in (0, depth-1) else '1'
                  for x in range(width)] for z in range(depth)]
    cx = width // 2
    for x in range(cx-1, cx+2):
        structure[0][x] = '1'
        structure[-1][x] = '0'
    utilities = [[' ' for _ in range(width)] for _ in range(depth)]
    utilities[1][cx] = 's'
    utilities[-1][cx] = 't'
    artifacts = [[' ' for _ in range(width)] for _ in range(depth)]
    for x, z, token in placements:
        artifacts[z][x] = token
    return {
        'map_info': {'name': name, 'lookup_name': name, 'description': title,
            'version': '1.0', 'format': 'json',
            'dimensions': {'width': width, 'depth': depth, 'max_height': 8 if open_roof else 4},
            'metadata': {'category': 'primitives', 'difficulty': 'beginner', 'n_artifacts': len(placements)},
            'museum': {'open_roof': open_roof, 'piers': False, 'plinths': False,
                'floor_cells': [[x, depth-1] for x in range(cx-1,cx+2)],
                'sculpture_clear_rects': [[0,0,width-1,depth-1]],
                'props_deny': ['bench','dream_bodies','sculptures','weapon_cabinet']}},
        'utility_definitions': {'t': {'type':'teleporter','name':'Next','description':'Continue along Primitives',
                                     'properties': {'action':'next_in_sequence'}}},
        'layers': {'structure': structure, 'utilities': utilities, 'interactables': artifacts},
        'settings': {'cube_size':1.0,'gutter':0.0,'enable_physics':True,'show_grid':False,
                     'auto_reveal_on_entry':True,'initial_tile_visibility':'all_visible','disable_biome':True},
        'documentation': {'summary': title, 'layout': f'{width} by {depth}; clear central passage, museum-hosted exhibits.',
                          'key_elements': [token.split(':')[0] for _,_,token in placements]},
    }


def main():
    # Snapshot the actual runtime plans before a narrow refresh, for preservation checks.
    for relative in ['ada_run/em_plan.json','commons/data/museum/em_plan.json','commons/data/map_authored.json']:
        before = OUT/'before'/relative
        if not before.exists():
            before.parent.mkdir(parents=True,exist_ok=True)
            before.write_bytes((ROOT/relative).read_bytes())

    ignorance_path = 'commons/maps/Primitives_Ignorance/map_data.json'
    ignorance = read(ignorance_path)
    moved = {}
    for z,row in enumerate(ignorance['layers']['interactables']):
        for x,value in enumerate(row):
            name = str(value).split(':')[0].split('#')[0]
            if name in ('primitive_mesh_library','seven_words_choir'):
                moved[name] = {'cell':[x,z], 'token':value}
                row[x] = ' '
    assert set(moved)=={'primitive_mesh_library','seven_words_choir'}, 'Run once on the inspected arrangement.'
    ignorance['map_info']['metadata']['n_artifacts'] = sum(
        bool(str(value).strip()) and str(value).strip() != '0'
        for row in ignorance['layers']['interactables'] for value in row)
    write(ignorance_path, ignorance)

    new = [
        ('Primitives_Godot',19,23,'Forms the engine gives us',
         [(9,8,'primitive_mesh_library:0:0#plinth:0'),(5,18,'seven_words_choir:180:0#plinth:0.72')],False),
        ('Primitives_Columns',27,35,'One profile, a family of columns',
         [(13,17,'resolution_colonnade_museum:0:0#plinth:0')],True),
        ('Primitives_Profiles',29,37,'Borrowed outlines become architecture',
         [(14,18,'glyph_profile_gallery:0:0#plinth:0')],True),
    ]
    for name,w,d,title,placements,roof in new:
        write(f'commons/maps/{name}/map_data.json',hall(name,w,d,title,placements,roof))

    path='commons/maps/sequences/primitives.json'
    document=read(path); sequence=document['sequences']['primitives']
    names=[x[0] for x in new]
    assert not any(name in sequence['maps'] for name in names)
    at=sequence['maps'].index('Primitives_Ignorance')+1
    sequence['maps'][at:at]=names
    labels=[f'{x[0]}: {x[3]}' for x in new]
    at=next(i for i,label in enumerate(sequence['content']) if label.startswith('Primitives_Ignorance'))+1
    sequence['content'][at:at]=labels
    # Preserve the already-walked museum-only interlude explicitly. It does not
    # become a new tutorial or book chapter merely because the plan carries it.
    interludes=sequence.setdefault('museum_interludes',[])
    if not any(x.get('map')=='Biome_Ladder_Primitives' for x in interludes):
        interludes.append({'map':'Biome_Ladder_Primitives','after':'Primitives_Portals',
                          'reason':'Retain the existing museum interlude; not an added tutorial chapter.'})
    sequence['description']='Follow positions into relations, records, addresses, faces and enclosures. Separate generated primitives from the forms the engine supplies; explore column profiles and borrowed letter outlines before returning to finite refinement, limits and composition.'
    groups=sequence['artifact_groups']
    prior=next(g for g in groups if g['map']=='Primitives_Ignorance')
    prior['artifacts']=list(dict.fromkeys(str(v).split(':')[0].split('#')[0]
        for row in ignorance['layers']['interactables'] for v in row if str(v).strip() and str(v).strip()!='0'))
    prior['rationale']='Ideal solids, finite sphere constructions and chosen resolution; retain older comparisons in the side alcove. Engine vocabulary and exploratory families continue in their own halls.'
    at=groups.index(prior)+1
    for name,w,d,title,placements,roof in reversed(new):
        groups.insert(at,{'map':name,'position':'exploration' if name!='Primitives_Godot' else 'vocabulary',
            'artifacts':[tok.split(':')[0] for _,_,tok in placements],
            'size_budget':'environment','rationale':title,'grammar':'sainsbury'})
    write(path,document)
    (OUT/'placement-changes.json').write_text(json.dumps({'relocated_from_ignorance':moved,
        'new_maps':names,'preserved_museum_interlude':'Biome_Ladder_Primitives'},indent=2)+'\n',encoding='utf-8')
    print('Expanded Primitives:', ' -> '.join(sequence['maps'][9:]))


if __name__=='__main__':
    main()
