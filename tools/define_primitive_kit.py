"""Author the concrete Primitives kit and its lineage; never change saved rooms."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'commons/artifacts/primitive_encounters'
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,v):(ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def scene(name,script,props):
    (FOLDER/(name+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://'+script+'" id="1"]\n[node name="'+name+'" type="RigidBody3D"]\ncollision_layer = 5\ncollision_mask = 3\nscript = ExtResource("1")\n'+props+'\n',encoding='utf-8')
specs=[]
def spec(id,title,map,family,dimensions,anchor,behaviour,scene_path,icon,learn,recipe=None):
    specs.append(dict(id=id,title=title,map=map,family=family,dimensions=dimensions,anchor=anchor,behaviour=behaviour,scene=scene_path,icon=icon,learn=learn,recipe=recipe or []))
for length in [1,2,4]:
    id=f'timber_plank_{length}m';script='commons/artifacts/line_relations_gallery/line_body.gd'
    scene(id,script,f'skin = "plank"\nspan = {float(length)}')
    spec(id,f'Timber plank / {length} m','Point_Lines','Line / timber',[length,.06,.25],'Centre; ends at ±length/2 on local X','Carry and place; frozen when released. Fixed copies support a path.',f'res://commons/artifacts/primitive_encounters/{id}.tscn','plank','A measured segment gains width, thickness, grain and a matching box collider.',['line'])
for x,z in [(1,1),(2,1),(2,2)]:
    id=f'timber_panel_{x}x{z}'
    scene(id,'commons/artifacts/primitive_encounters/timber_panel.gd',f'panel_size = Vector2({x}, {z})')
    spec(id,f'Timber panel / {x} × {z} m','Point_Triangle_Context','Face / timber',[x,.045,z],'Bottom-face centre; horizontal X/Z footprint','Place flat as deck, tilt as ramp, or turn upright as a wall infill.',f'res://commons/artifacts/primitive_encounters/{id}.tscn','panel','Two triangles share a diagonal; a thin sheet makes the face useful as construction.',['construction_wood_quad'])
scene('trace_point_ball','commons/artifacts/primitive_encounters/gravity_ball.gd','collision_layer = 6')
# Avoid duplicate properties in the generated root.
p=FOLDER/'trace_point_ball.tscn';p.write_text(p.read_text().replace('collision_layer = 5','collision_layer = 6').replace('script = ExtResource("1")\ncollision_layer = 6','script = ExtResource("1")'),encoding='utf-8')
spec('trace_point_ball','Trace ball / 28 cm','Point_Trace','Point / moving body',[.28,.28,.28],'Sphere centre','Black hand-sized ball, mass 0.3 kg. Drops to gravity; the Trace ramp records its actual path.','res://commons/artifacts/primitive_encounters/trace_point_ball.tscn','point','Distinguish the moving body from the stored trace of its motion.',['point_held'])
for id,form,title,dim,learn in [
 ('traffic_pyramid_5','pyramid','Traffic pyramid / 5 vertices',[.6,.9,.6],'Four base corners and one apex. A square pyramid can borrow the warning role of a traffic cone.'),
 ('pentagonal_bipyramid_7','bipyramid','Pentagonal bipyramid / 7 vertices',[.84,.9,.84],'Five corners around a waist plus two tips; ten triangular faces. Seven vertices does not determine a unique solid.')]:
    scene(id,'commons/artifacts/primitive_encounters/poly_marker.gd',f'form = "{form}"')
    spec(id,title,'Primitives_Polythedra','Solid / topology',dim,'Bottom tip / base centre; +Y is up','Retained pickable comparison solid; the pyramid marks a boundary, the bipyramid is an optional crystal study.',f'res://commons/artifacts/primitive_encounters/{id}.tscn','pyramid' if form=='pyramid' else 'bipyramid',learn,['pyramid_blocker'] if form=='pyramid' else ['align_tetrahedron','pyramid_blocker'])
spec('melencolia_platform','Melencolia / construction court','Primitives_Melencolia','Assembly / reuse',[5,1.03,5],'Centre of original court volume; nominal bottom is local Y = −0.5','Walkable 5 × 5 m court; 25 original one-metre concrete blocks, 25 timber sheets, fitted rim and warm work lights. The existing two wedges provide access.','res://commons/artifacts/primitive_encounters/melencolia_platform.tscn','assembly','Recompose the known kit into a usable place. The court does not introduce a new primitive.',['construction_cube','timber_panel_1x1','timber_plank_4m','timber_plank_1m','wp'])
spec('surface_ball_test','White balls / surface test','Point_Triangle_Context','Point / surface diagnostic',[.2,.2,.2],'Centre of each emitted sphere; a shared plane above the sampled surface','White equal balls released from above, without a launch impulse. Default diameter 20 cm; individual encounters can configure radius. This is an emitter attached to a surface, not a freestanding pickup.','res://commons/artifacts/surface_ball_test/surface_ball_test.tscn','point','A neutral repeated body tests pockets, slope and continuity; distinguish the body from its trail and from a colour mapping.',['trace_point_ball'])
associations=[
 ('do_not_cross_barrier','Police barrier','Point_Lines','Line / boundary','Existing sawhorse and DO NOT CROSS board; actual blocking differs from painted instruction.','barrier'),
 ('health_cross','Health plus','Point_Lines','Line / consequence','Two crossed strokes become the existing recovery pickup; a drawn plus alone has no healing effect.','plus'),
 ('anamorphic_cross','Danger X','Point_Lines','Line / consequence','Rotate crossed strokes into the existing drain/danger zone. Preserve the original health contract.','cross'),
 ('two_point_ruler','Two-point ruler','Point_Lines','Line / instrument','The existing ruler measures actual endpoint separation.','ruler'),
 ('line_sledgehammer','Hit stick / line hammer','Point_Lines','Line / tool','The existing line tool becomes a carried striking head; striking behaviour stays with its source scene.','hammer'),
 ('unfinished_wall','Stud wall / frame + infill','Point_Triangle_Context','Face / wall association','Associate known rods and sheets with the existing stud-wall prefab; its source remains a separate manufactured assembly.','wall'),
 ('chainlink_panel','Chain-link / a permeable wall','Point_Triangle_Context','Face / wall association','An associated wall with holes and a different material; not a solid quad and not a new prerequisite.','wall'),
 ('barrier','Concrete barrier / a thick wall','Point_Triangle_Context','Face / wall association','An existing thick obstruction. Wall associations are optional uses, not a demand to teach every stack item here.','wall'),
]
catalog=read('commons/void/catalog.json'); registry={}
all_registry={}
for p in sorted((ROOT/'commons/artifacts/registry').glob('*.json')):all_registry.update(json.loads(p.read_text(encoding='utf-8-sig')).get('artifacts',{}))
for id,title,map,family,behaviour,icon in associations:
    entry=all_registry.get(id,{})
    prop=catalog['props'].get(id,{})
    spec(id,title,map,family,prop.get('size'), 'Existing source anchor; see its scene',behaviour,entry.get('scene') or prop['scene'],icon,'The same geometric relation acquires a different use or consequence.',['line'] if map=='Point_Lines' else ['timber_panel_2x2'])
g=read('commons/void/capacity-artifacts.json'); nodes={n['id']:n for n in g['nodes']}
for p in specs:
    node=nodes.get(p['id'])
    if not node:
        node=dict(id=p['id'],sequence='primitives');g['nodes'].append(node);nodes[p['id']]=node
    node.update(title=p['title'],learn=p['learn'],use=p['behaviour'],icon=p['icon'],scene=p['scene'],proposed=False,
        insertion=dict(map=p['map'],basis='authored',reason='Named output of this Primitives encounter; a source definition is separate from a configured or tested placement.'))
    existing=p['id'] in [a[0] for a in associations] or p['id']=='surface_ball_test'
    node['carry']=dict(identity=p['scene'].removeprefix('res://'),keeps='Existing source behaviour; nominal metric dimensions and explicit anchor.',adds=p['behaviour'],check='Existing source kept; this pass authors its taxonomy and does not recertify its interactions.' if existing else 'Native geometry/collider and source reuse checks; real exported GLBs and editor validation in ada_run/primitives-kit/. No physical headset acceptance.')
    if not existing:
        lift=.5 if p['id']=='melencolia_platform' else .14 if p['id']=='trace_point_ball' else .03 if p['id'].startswith('timber_plank_') else 0
        catalog['props'][p['id']]=dict(label=p['title'],size=p['dimensions'],color='#c6a773' if p['family'].find('timber')>=0 else '#7a8990',scene=p['scene'],group='Primitives kit',collision='parts',offset=[0,lift,0])
        registry[p['id']]=dict(lookup_name=p['id'],name=p['title'],scene=p['scene'],description=p['learn']+' '+p['behaviour'],qfep_connection='Keep geometric construction, material choice and behavioural consequence distinguishable; a sign does not automatically perform what it signifies.',category='primitives',complexity='beginner',tags=['construction','prefab',p['family']])
    for parent in p['recipe']:
        kind='associate' if p['id'] in [a[0] for a in associations] or p['id']=='traffic_pyramid_5' else 'combine' if p['id']=='melencolia_platform' else 'develop'
        if not any(e['source']==parent and e['target']==p['id'] and e['kind']==kind for e in g['edges']):
            g['edges'].append(dict(source=parent,target=p['id'],kind=kind,label=p['learn'] if kind!='combine' else 'Use this named piece in the built construction court; the two original wedges remain its access.'))
nodes['void_beam'].update(title='Fixed beam / retained line',note='Fixed architectural line return. Standard carried timber planks enter at Point Lines; the beam here remains the original descent assembly.')
nodes['pyramid_blocker']['insertion']=dict(map='Primitives_Polythedra',basis='authored',reason='Five-vertex square pyramid, distinct from the four-vertex tetrahedron and six-vertex prism wedge.')
nodes['pyramid_blocker']['learn']='Five vertices, eight edges and five faces: a square base and four triangular sides.'
nodes['pyramid_blocker']['icon']='pyramid'
nodes['cone_from_tetrahedron'].update(title='Cone / refine an apex and base',note='An optional analogy. The traffic pyramid has five vertices; a smooth cone is not a five-vertex polyhedron. Increasing a polygonal base resolution is a later mesh operation.')
nodes['surface_ball_test']['note']='White diagnostic shower; keep this distinct from the black 28 cm carried Trace ball. Equal release conditions test a surface; colour variants arrive later.'
nodes['durer_scene']['use']='Compose the learned kit on the built construction court: approach by wedges, arrange solids, frame a view and compare the result with the existing image study.'
if not any(e['source']=='trace_point_ball' and e['target']=='trace_ball_ramp' for e in g['edges']):g['edges'].append(dict(source='trace_point_ball',target='trace_ball_ramp',kind='combine',label='The canonical carried ball is instantiated by the existing ramp; the ramp retains its measured trace.'))
if not any(e['source']=='melencolia_platform' and e['target']=='durer_scene' for e in g['edges']):g['edges'].append(dict(source='melencolia_platform',target='durer_scene',kind='combine',label='The learned construction kit supplies the real court beneath the existing composition; original solids and viewing orientation stay saved separately.'))
write('commons/void/primitive-prefabs.json',dict(version=1,updated='2026-10-22',scope='Primitives construction kit. Dimensions are metres, not tutorial vertex counts. Source presence is not a gameplay test.',prefabs=specs))
write('commons/void/capacity-artifacts.json',g);write('commons/void/catalog.json',catalog)
write('commons/artifacts/registry/primitive_kit.json',dict(artifacts=registry))
print(len(specs),'prefab definitions; saved rooms untouched')
