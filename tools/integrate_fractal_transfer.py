"""One-time correction of the delivered Argon draft to the actual Void schema."""
from pathlib import Path
import copy, json, shutil
ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / 'commons/void/trials/fractals'
if (folder / 'argon-rooms-draft.json').exists():
    raise SystemExit('Already integrated; preserve subsequent editor changes.')
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
write = lambda p, d: p.write_text(json.dumps(d, indent=2) + '\n', encoding='utf-8')
draft = read(folder / 'rooms.json')
shutil.copy2(folder / 'rooms.json', folder / 'argon-rooms-draft.json')
shutil.copy2(folder / 'layout.json', folder / 'argon-layout-draft.json')
blank = {'map':'', 'title':'Open structure','origin':False,'walls':[],'artifacts':[],'props':[],'impact_cells':[],'route':[],'supply_leads':False}
floors = [copy.deepcopy(blank) for _ in range(4)]
names = ['Fractal_Recursion', 'Fractal_RecursiveTrees']
for level, source in enumerate(draft['floors'], 1):
    floor = floors[level]
    floor.update(map=names[level-1],title=source['title'],artifacts=source['artifacts'])
    for item in floor['artifacts']:
        item['position'] = item.pop('offset')
        if item['artifact'] == 'fractal_scene':
            item['artifact'] = 'void_fractal_scene'
        if item['artifact'] == 'fractal_lsystem_tree':
            item['height'] = 1.35
        if item['artifact'] == 'small_subdivision_cube':
            item['height'] = .12
    floor['route'] = [{'label':r['text'], 'position':[r['position'][0],r['position'][2]]} for r in source['route']]
write(folder / 'rooms.json', {'$schema':'../../rooms.schema.json','version':1,'floors':floors})
layout = read(ROOT / 'commons/void/trials/shaders/layout.json')
layout['status'] = 'Fractals / transferred; coordinator native validation pending'
layout['floor_roles'] = ['Canopy', *names, 'Catch floor']
write(folder / 'layout.json',layout)
catalog_path = ROOT / 'commons/void/catalog.json'
catalog = read(catalog_path)
definition = copy.deepcopy(catalog['artifacts']['fractal_scene'])
definition.update(scene='res://commons/void/trials/fractals/fractal_scene_relocated.tscn',lookup_name='void_fractal_scene',name='Fractal / world-space mesh adapter',museum_import=True)
catalog['artifacts']['void_fractal_scene'] = definition
write(catalog_path,catalog)
print('Normalized four-floor scaffold, 22 placements and one trial-local scene alias.')
