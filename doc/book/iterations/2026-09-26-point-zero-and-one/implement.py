from pathlib import Path
import copy, hashlib, json, re, sys
r = Path.cwd(); o = Path(__file__).resolve().parent
base = json.loads((o/'baseline.json').read_text())
changed = []
def read(path): return json.loads((r/path).read_text(encoding='utf-8-sig'))
def text(path): return (r/path).read_text(encoding='utf-8')
def write(path, value):
    p = r/path
    if path in base:
        assert hashlib.sha256(p.read_bytes()).hexdigest() == base[path], 'Concurrent edit: '+path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(value.encode('utf-8')); changed.append(path)
def js(path, value): write(path, json.dumps(value, ensure_ascii=False, indent=2)+'\n')

# Independent scene variants keep the authored corridor legible in the registry.
regpath = 'commons/artifacts/registry/commons_artifacts.json'; reg = read(regpath)
variants = ['absent', 'visible', 'solid', 'held', 'pedestal']
for kind in variants:
    name = 'point_'+kind
    path = 'commons/primitives/point/'+name+'.tscn'
    write(path, '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/primitives/point/point_condition.gd" id="1"]\n\n[node name="'+name+'" type="Node3D"]\nscript = ExtResource("1")\ncondition = "'+kind+'"\n')
    reg['artifacts'][name] = dict(lookup_name=name, name='Point one — '+kind,
        category='primitives', complexity='beginner', scene='res://'+path,
        description='The same labelled position, '+kind+'.', map_ready=True,
        include_in_map_data=True, map_sequences=['primitives'],
        footprint=[1.5, 2.1, 1.5] if kind=='pedestal' else [0.7, 1.5, 0.7],
        tags=['point', 'visibility', 'collision', 'embodiment'])
path = 'commons/primitives/point/arrival_shaft.tscn'
write(path, '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/primitives/point/arrival_shaft.gd" id="1"]\n\n[node name="ArrivalShaft" type="Node3D"]\nscript = ExtResource("1")\n')
reg['artifacts']['arrival_shaft'] = dict(lookup_name='arrival_shaft', name='Late arrival',
    category='primitives', scene='res://'+path, description='An open shaft over the museum arrival floor.',
    map_ready=True, include_in_map_data=True, map_sequences=['primitives'], footprint=[2.6,6.7,2.6], tags=['arrival','time'])
js(regpath, reg)

oldone = read('commons/maps/Point_One/map_data.json')
lobby = copy.deepcopy(oldone['map_info']['museum']['lobby'])
lobby.update(drop_x=7, drop_z=1, intro_text=0, window_x0=6, window_x1=8)
zero = read('commons/maps/Point_Zero/map_data.json')
w, h = 19, 9
zero['map_info'].update(name='Point Zero — You arrive late', description='A fall into a running room; folding frames and a chosen origin.', dimensions=dict(width=w, depth=h, max_height=4))
zero['map_info']['museum'] = dict(lobby=lobby, gate=False, piers=False, plinths=False,
    props_deny=['wall_clock','electrical_panel','floor_grate','bench'])
zero['layers'] = {key:[[' ']*w for _ in range(h)] for key in ['structure','utilities','interactables']}
for z in range(h):
    zero['layers']['structure'][z] = ['w'] + ['1']*(w-2) + ['w']
zero['layers']['structure'][-1] = ['w']*w
for x in range(7,10): zero['layers']['structure'][-1][x] = '1'
zero['layers']['utilities'][1][7] = 's'
zero['layers']['utilities'][8][8] = 't:Point_One'
zero['layers']['interactables'][1][7] = 'arrival_shaft#plinth:0#pin:1'
zero['layers']['interactables'][4][7] = 'frame_counter_display:180:1.65:2#plinth:0#pin:1'
zero['layers']['interactables'][5][3] = 'origin:180:1.0#plinth:0#pin:1#beam_height:0.8#beam_label:Point zero'
zero['layers']['interactables'][6][5] = 'you_are_here:180:-0.5#offset:0,0.20,0#peel:loose'
zero['spawn_points'] = {'default':{'position':[7.5,4,1.5],'rotation':[0,180,0]}}
zero['settings'] = dict(cube_size=1, gutter=0, show_grid=True, enable_physics=True,
    background={'type':'sky','color':[0.08,0.1,0.18]}, grid_animation={'enabled':False})
zero['documentation'] = dict(summary='The first chapter: arriving inside inherited work.',
    layout='19 × 9. Fall through the open shaft at (7,1), facing the counter at (7,4). The lobby window retains Folding Past. The origin and its Point zero label stand at (3,5). South exit continues to Point_One.',
    objective='Separate the running process, historical inheritance and a chosen spatial reference.')
js('commons/maps/Point_Zero/map_data.json', zero)

# Keep the later room, enlarge its approach and relocate its opening ecology.
one = copy.deepcopy(oldone)
one['map_info']['museum']['lobby'] = {'enabled':False}
one['map_info']['museum'].update(piers=False, plinths=False)
one['map_info']['museum'].pop('annex',None)
one['map_info']['museum'].pop('basin',None)
one['map_info']['dimensions'].update(depth=28)
one['map_info']['name'] = 'Point One — A body for a position'
for key, layer in one['layers'].items():
    one['layers'][key] = [[' ']*19 for _ in range(8)] + layer
for z in range(12):
    one['layers']['structure'][z] = ['0']*19
    for x in range(6,10): one['layers']['structure'][z][x] = '1'
    for x in [5,10]: one['layers']['structure'][z][x] = 'w'
# Clear the old entry tokens, then restore their useful secondary comparisons.
moved = {}
for z, row in enumerate(one['layers']['interactables']):
    for x, token in enumerate(row):
        key = token.split(':')[0].split('#')[0]
        if z < 16 or key in ['origin','frame_counter_display','you_are_here']:
            if token.strip(): moved[key] = token
            row[x] = ' '
for z in range(16): one['layers']['utilities'][z] = [' ']*19
one['layers']['utilities'][0][8] = 's'
for z, kind in [(1,'absent'),(4,'visible'),(7,'solid'),(10,'held')]:
    one['layers']['interactables'][z][7] = 'point_'+kind+':180#plinth:0#pin:1'
# Open the room at the corridor's end without blocking its onward approach.
for z in range(12,16):
    for x in range(2,17): one['layers']['structure'][z][x] = '1'
for key, x, z in [('the_invisible_point',13,13),('code_evolution_screen',15,15),
                  ('SoundscapeRadioRack',3,14),('street_talker',2,12),('comment_box',15,12)]:
    one['layers']['interactables'][z][x] = moved[key]
one['layers']['interactables'][14][13] = moved['interactive_point_origin_force'].replace('point_one_main','point_one_force_return')
# End sculpture stands inside the room, leaving the south crossing clear.
one['layers']['interactables'][26][8] = 'point_pedestal:180#plinth:0#pin:1'
for z in [25,26]:
    for x in range(6,11): one['layers']['structure'][z][x] = '1'
for x in range(7,10): one['layers']['structure'][27][x] = '1'
one['spawn_points'] = {'default':{'position':[8.5,0.1,0.5],'rotation':[0,180,0]}}
one['documentation'] = dict(summary='One position acquires a visible body, collision and pickup.',
    layout='19 × 28. Corridor stages at (7,1), (7,4), (7,7), (7,10). Continue with the same held point into the coordinate room. End at the 1.3 m diameter sphere on its pedestal at (8,26).',
    objective='Distinguish the mathematical point, mesh, collision body and hand interaction without changing the point label.',
    secondary='The invisible-point case, example screen, force point, radio, Fontana, floating field and snap sphere remain available in the wider room.')
one['map_info']['metadata']['n_artifacts'] = sum(bool(t.strip()) for row in one['layers']['interactables'] for t in row)
js('commons/maps/Point_One/map_data.json', one)

# Book and museum declarations both begin at zero.
seqpath='commons/maps/sequences/primitives.json'; seq=read(seqpath); s=seq['sequences']['primitives']
s['maps'].insert(0,'Point_Zero'); s['content'].insert(0,'Point_Zero')
s['artifact_groups'].insert(0,dict(map='Point_Zero',position='arrival',artifacts=['frame_counter_display','folding_past','origin','you_are_here'],size_budget='environment',grammar='florence',rationale='An arrival into an already-running room precedes the construction of a point.'))
s['artifact_groups'][1].update(artifacts=['point_absent','point_visible','point_solid','point_held','coordinate_readout','CoordinateSystem3M','drag_point_target','point_pedestal'], rationale='A corridor separates absence, visible surface, collision and pickup before coordinates and a large sphere return to the same name.')
js(seqpath,seq)
declpath='commons/data/map_authored.json'; decl=read(declpath);decl['primitives'].insert(0,'Point_Zero');js(declpath,decl)
scene='commons/scenes/endless_museum.tscn';write(scene,text(scene).replace('start_map = "Point_One"','start_map = "Point_Zero"'))

bookpath='commons/data/book/primitives.json'; book=read(bookpath); pearl=next(p for p in book['pearls'] if p['map']=='Point_One')
zero_tokens=['folding_past','frame_counter_display','origin','you_are_here']
zero_lines=[l for l in pearl['lines'] if l.get('token','') in zero_tokens]
for l in zero_lines:
    if l.get('token','')=='origin': l['text']='Point zero.\nA chosen place to count from.';l['lock']=[3,5]
    if l.get('token','')=='frame_counter_display': l['lock']=[7,4]
    if l.get('token','')=='you_are_here': l['lock']=[5,6]
zero_pearl=dict(pearl='point zero',map='Point_Zero',lines=zero_lines,ordered=True,hero='frame_counter_display')
book['pearls'].insert(book['pearls'].index(pearl),zero_pearl)
pearl['lines']=[l for l in pearl['lines'] if l.get('token','') not in zero_tokens]
for l in pearl['lines']:
    if l.get('token','')=='interactive_point_origin': l['text']='Point one.'
    # Grid maps own placement; retire stale explicit overlay locks after the split.
    for k in ['lock','claimed']: l.pop(k,None)
pearl['lines']=[dict(token='point_'+kind,text='Point one.',by='hand',placed_by='grid') for kind in variants]+pearl['lines']
for k in ['cells','hang','adopt','label']: pearl.pop(k,None)
js(bookpath,book)

rolespath='commons/data/artifact_roles.json'; roles=read(rolespath)
roles['roles']['Point_Zero']={t:('secondary' if t=='you_are_here' else 'primary') for t in zero_tokens}
roles['roles']['Point_Zero']['arrival_shaft']='primary'
roles['order']['Point_Zero']={'primary':['arrival_shaft','frame_counter_display','folding_past','origin'],'secondary':['you_are_here']}
for t in zero_tokens: roles['roles']['Point_One'].pop(t,None)
for t in ['interactive_point_origin_force','the_invisible_point','code_evolution_screen']: roles['roles']['Point_One'][t]='secondary'
for kind in variants: roles['roles']['Point_One']['point_'+kind]='primary'
roles['order']['Point_One']['primary']=['point_absent','point_visible','point_solid','point_held','@the-3d-coordinate-system','drag_point_target','point_pedestal']
roles['order']['Point_One']['secondary']=[t for t in roles['order']['Point_One']['secondary'] if t not in zero_tokens]+['interactive_point_origin_force','the_invisible_point','code_evolution_screen']
roles['positions'].pop('Point_One',None)
js(rolespath,roles)

# Derive only the changed hall rows. All other map placements stay untouched.
sys.path.insert(0,str(r/'tools')); from em_map_halls import derive_row, normalize_row
planpath='ada_run/em_plan.json'; plan=read(planpath)
old=next(p for p in plan['plans'] if p.get('map')=='Point_One')
total=len(decl['primitives'])
rows=[]
for index,(name,pearl_name) in enumerate([('Point_Zero','point zero'),('Point_One',old['pearl'])]):
    row=derive_row(pearl_name,name,old['museum'],index,total,'primitives')
    normalize_row(row,False,True)
    rows.append(row)
at=plan['plans'].index(old);plan['plans'][at:at+1]=rows
for row in plan['plans']:
    if row.get('sequence')=='primitives':
        row['pearl_index']=decl['primitives'].index(row['map']); row['pearls_total']=total
js(planpath,plan)
(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Updated',len(changed),'opening files; other hall placements retained.')
