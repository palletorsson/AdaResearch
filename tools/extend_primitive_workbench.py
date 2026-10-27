"""Register source-backed Primitives examples without touching any floor layout."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def read(p): return json.loads(p.read_text(encoding='utf-8'))
base = ROOT / 'commons/void'
kit, graph, rooms, catalog = [read(base / n) for n in ['primitive-prefabs.json', 'capacity-artifacts.json', 'rooms.json', 'catalog.json']]
models = read(ROOT.parent / 'ada_encyclopedia/public/void-models/manifest.json')
defs = {p['id']: p for p in kit['prefabs']}
nodes = {n['id']: n for n in graph['nodes']}
def relation(source, target, kind, label):
    if not any(e['source']==source and e['target']==target and e['kind']==kind for e in graph['edges']):
        graph['edges'].append(dict(source=source,target=target,kind=kind,label=label))
def register(p):
    # Existing definitions and authored relationships stay authoritative on rerun.
    is_new = p['id'] not in defs
    if p['id'] not in defs:
        kit['prefabs'].append(p); defs[p['id']]=p
    if p['id'] not in nodes:
        n=dict(id=p['id'], title=p['title'], sequence='primitives', learn=p['learn'], use=p['behaviour'], icon=p['icon'], insertion=dict(map=p['map'],basis='authored',reason='Reusable instance of an existing Primitives source; no floor arrangement changed.'))
        graph['nodes'].append(n); nodes[p['id']]=n
    for ingredient in p.get('recipe',[]) if is_new else []:
        if ingredient in nodes or ingredient in defs:
            relation(ingredient,p['id'],'combine' if p.get('preview_assembly') else 'develop', 'The existing source keeps this ingredient or operation; inspect the actual geometry and place a separate instance.')
def part(id,title,floor,names,family,learn,recipe=(),source='hall',behaviour=None):
    src=next(a for a in rooms['floors'][floor]['artifacts'] if a['id']==source)
    exported=models['floors'][str(floor)]['artifacts'][source]
    poses={}; dims=None
    for i,name in enumerate(names):
        m=exported['parts'][name]; assert m.get('url'), (id,name)
        bounds=m['default']['bounds']
        poses[name]=dict(position=[(i-(len(names)-1)/2)*2.2,-bounds[1],0],rotation=[0,0,0])
        if len(names)==1: dims=bounds[3:]
    return dict(id=id,title=title,map=rooms['floors'][floor]['map'],family=family,dimensions=[round(v,3) for v in dims] if dims else None,
        anchor='Original part pivot in X/Z; visible base aligned to local Y = 0. Coloured axes mark the insertion point.',
        behaviour=behaviour or 'The existing source part, at its authored size. Place, move and turn it independently in the live editor. Runtime interactions remain in Godot.',
        scene=catalog['artifacts'][src['artifact']]['scene'],icon='body',learn=learn,recipe=list(recipe),
        placement=dict(artifact=src['artifact'],source_floor=floor,source_id=source,config=dict(only_parts=names,parts=poses)))

# Existing Line associations had definitions but lacked resolved Three.js models.
for p in kit['prefabs']:
    if p['id'] not in ['do_not_cross_barrier','health_cross','anamorphic_cross','two_point_ruler','line_sledgehammer']: continue
    if p.get('placement'): continue
    src=next(a for a in rooms['floors'][3]['artifacts'] if a['artifact']==p['id'])
    p['placement']=dict(artifact=src['artifact'],source_floor=3,source_id=src['id'],height=src['height'],scale=src['scale'],config=src['config'])

register(part('platonic_grabbables','Five Platonic solids',8,['Tetrahedron','Cube','Octahedron','Dodecahedron','Icosahedron'],'Solid / regular family','Compare the five original solids and their stands; the same cube returns within a family.',['tetrahedron_blocker','construction_cube']))
for name in ['Tetrahedron','Cube','Octahedron','Dodecahedron','Icosahedron']:
    register(part('platonic_'+name.lower(),name+' / Platonic study',8,[name],'Solid / regular family','Faces, edges and vertices distinguish this original regular solid.',['platonic_grabbables']))
register(part('sphere_resolution_atlas','Sphere resolution atlas',8,['SphereResolutionAtlas'],'Sphere / sampling','Original sphere samples compare resolution and edge display side by side.',['trace_point_ball']))
for name in models['floors']['8']['artifacts']['hall']['parts']:
    if name.startswith('ComparisonStand_') or name=='BudgetOfSmoothness':
        register(part('sphere_'+name.lower(),name.replace('ComparisonStand_','Sphere comparison / ').replace('_',' '),8,[name],'Sphere / comparison','Keep the actual sampled geometry, display material and original comparison stand.',['sphere_resolution_atlas']))

for name,m in models['floors']['9']['artifacts']['hall']['parts'].items():
    if not name.startswith(('Grove_','Sides_')): continue
    register(part('column_'+name.lower(),m['default'].get('label',name)+' / '+name,9,[name],'Column / '+('sides' if name.startswith('Sides_') else name.split('_')[-1]+' divisions'),'The original column compares outline, sampling and composition at its full authored height.',['construction_cube','sphere_resolution_atlas']))

for name,m in models['floors']['10']['artifacts']['hall']['parts'].items():
    if not m.get('url'): continue
    register(part('profile_'+name.lower(),m['default'].get('label',name),10,[name],'Profile / '+('revolve' if name in ['RollingTyre_O','HangingSpool_I','Profile_5_I'] else 'sweep'),'A letter outline travels through space. Its holes, joins and disconnected contours remain visible.',['timber_panel_1x1'],behaviour='Original letter-profile source, including its own access and stand where present. The tyre retains its rolling rigid body; the preview is static.'))
relation('profile_rollingtyre_o','tyre_plank_wedge','combine','The original rolling tyre joins the familiar plank and wedge; no new primitive is needed.')

for id,title,name in [('portal_rings','Twenty pink rings / 3 m spacing','RefinementPassage'),('portal_sweep','Profile into a ring','ProfileToRing'),('portal_arrivals','Strange arrivals','StrangeArrivals')]:
    register(part(id,title,11,[name],'Portal / closed sweep','Reuse the existing portal source at its actual size; the long ring sequence remains long.',['profile_profile_5_i'],source='sky-walk'))

# Mirror the *existing* native construction recipe, using each real kit mesh.
# These poses are a teaching view, not replacement game geometry.
assembly=[]
for x in range(5):
    for z in range(5):
        assembly.append(dict(name=f'Cube_{x}_{z}',prefab='construction_cube',stage='Foundation',position=[x-2,-.5,z-2],rotation=[0,0,0]))
        assembly.append(dict(name=f'Panel_{x}_{z}',prefab='timber_panel_1x1',stage='Deck',position=[x-2,.458,z-2],rotation=[0,0,0]))
for axis in range(2):
    for side in [-1,1]:
        for prefab,pos in [('timber_plank_4m',-.5),('timber_plank_1m',2)]:
            assembly.append(dict(name=f'Rim_{axis}_{side}_{prefab}',prefab=prefab,stage='Rim',position=[pos,.5,side*2.375] if axis==0 else [side*2.375,.5,pos],rotation=[0,90 if axis else 0,0]))
platform=defs['melencolia_platform']; platform.setdefault('preview_assembly',assembly)
court=part('melencolia_court','Melencolia / court + access',12,['CourtDeck','CourtRampLeft','CourtRampRight'],'Assembly / construction','The learned kit builds the existing court: 25 cubes, 25 sheets, eight rim planks and two access wedges.',['melencolia_platform','wp'])
court['placement']['config']['parts']={'CourtDeck':dict(position=[0,.5,0],rotation=[0,0,0]),'CourtRampLeft':dict(position=[-.5,0,3.5],rotation=[0,180,0]),'CourtRampRight':dict(position=[.5,0,3.5],rotation=[0,180,0])}
court['dimensions']=[5,1.03,7];court['preview_assembly']=[dict(a,position=[a['position'][0],a['position'][1]+.5,a['position'][2]]) for a in assembly]
for side in [-1,1]:court['preview_assembly'].append(dict(name='CourtRampLeft' if side<0 else 'CourtRampRight',prefab='wp',stage='Access',position=[side*.5,0,3.5],rotation=[0,180,0]))
register(court)
for id,title,names,recipe in [('melencolia_composition','Composition table + three solids',['CompositionTable','CompositionSolid0','CompositionSolid1','CompositionSolid2'],['platonic_grabbables','melencolia_court']),('melencolia_engraving','Durer / Melencolia study',['MelencoliaEngraving'],['melencolia_court']),('melencolia_box_library','Box library returns',['ReturnToTheBoxLibrary'],['construction_cube','melencolia_court'])]:
    p=part(id,title,12,names,'Assembly / return','Known bodies return as a composition, an instrument or a place to build.',recipe)
    if id=='melencolia_composition':
        p['placement']['config']['parts']={name:dict(position=[models['floors']['12']['artifacts']['hall']['parts'][name]['default']['position'][0]-4,models['floors']['12']['artifacts']['hall']['parts'][name]['default']['position'][1],0],rotation=[0,0,0]) for name in names}
    register(p)
relation('melencolia_court','durer_scene','combine','The existing court and its access wedges supply the place for the Melencolia composition; the engraving and solids stay separately editable.')
for filename,data in [('primitive-prefabs.json',kit),('capacity-artifacts.json',graph)]:
    (base/filename).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(f'{len(kit["prefabs"])} shared definitions; {len(graph["nodes"])} tree nodes. Floor layouts untouched.')
