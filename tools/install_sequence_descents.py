"""Add adjacent-floor routes by map identity, preserving unrelated room edits."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOKEN = 'sequence_descent'

def install():
    rooms_path = ROOT / 'commons/void/rooms.json'
    catalog_path = ROOT / 'commons/void/catalog.json'
    rooms = json.loads(rooms_path.read_text(encoding='utf8'))
    catalog = json.loads(catalog_path.read_text(encoding='utf8'))
    spine = json.loads((ROOT / 'commons/void/spine.json').read_text(encoding='utf8'))
    layout = json.loads((ROOT / 'commons/void/layout.json').read_text(encoding='utf8'))
    index = {f['map']: i for i, f in enumerate(rooms['floors'])}
    catalog['artifacts'][TOKEN] = dict(
        scene='res://commons/void/sequence_descent.tscn', label='Sequence descent / jumps, slides, stairs, subtraction',
        category='architecture', configure_before_ready=True,
        footprint=[11, 13], description='A physical route between adjacent tower floors. Configure kind, drop, destination, and hole_z.')
    installed = []
    kinds = ['wave_s', 'wave_eased', 'wave_tube', 'maximal_stairs', 'wave_ripple', 'wave_s',
             'maximal_stairs', 'wave_tube', 'wave_eased', 'maximal_stairs', 'wave_ripple']
    for sequence in ['forces', 'wavefunctions', 'boolean']:
        members = [f for f in spine['floors'] if f['sequence'] == ('boolean_surfaces' if sequence == 'boolean' else sequence)]
        if not members:
            # Sequence names are curated; fail rather than silently omit a family.
            raise ValueError(f'Missing sequence: {sequence}')
        for ordinal, (source, target) in enumerate(zip(members, members[1:])):
            i, j = index[source['map']], index[target['map']]
            if j != i+1: raise ValueError('Connection must land on the adjacent floor')
            kind = 'jump_terraces' if sequence == 'forces' else ('boolean_drop' if sequence == 'boolean' else kinds[ordinal % len(kinds)])
            item_id = 'sequence-descent-' + source['map'].lower()
            cfg = dict(kind=kind, drop=layout['levels'][i]-layout['levels'][j], destination_floor=j,
                       source_map=source['map'], destination_map=target['map'],
                       destination=f'{j:02d} / {target["map"].replace("_", " ")}',
                       label='JUMP TERRACES / SIDE STAIRS' if sequence=='forces' else kind.replace('_',' ').upper(),
                       connects_next_floor=True, tower_services=False, support=False)
            if sequence == 'boolean':
                position, facing = [10, 0], 0
                cfg['hole_z'] = -1.5 if ordinal % 2 == 0 else 1.5
            else:
                # Keep the existing east-side gravity/playground wings clear.
                east_busy = any(a.get('position',[0,0])[0]>22 and abs(a.get('position',[0,0])[1])<10
                                for floor in [rooms['floors'][i],rooms['floors'][j]] for a in floor['artifacts'])
                position, facing = ([-27,0],180) if east_busy else ([27,0],0)
            record = dict(id=item_id,artifact=TOKEN,station='NE',position=position,height=0,facing=facing,scale=1,config=cfg)
            floor = rooms['floors'][i]
            existing = next((a for a in floor['artifacts'] if a['id']==item_id),None)
            if existing: existing.update(record)
            else: floor['artifacts'].append(record)
            installed.append(dict(floor=i,destination=j,id=item_id,kind=kind,map=source['map'],position=position))
    for path, doc in [(rooms_path,rooms),(catalog_path,catalog)]:
        path.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    out=ROOT/'ada_run/sequence-descents';out.mkdir(parents=True,exist_ok=True)
    (out/'install.json').write_text(json.dumps(installed,indent=2)+'\n',encoding='utf8')
    print(json.dumps(installed,indent=2))

if __name__=='__main__': install()
