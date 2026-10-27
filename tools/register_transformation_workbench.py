"""Extend the one shared catalogue with existing Transformation examples."""
import copy,json
from pathlib import Path
from validate_void_rooms import available_artifacts
ROOT=Path(__file__).resolve().parents[1];base=ROOT/'commons/void';out=ROOT/'ada_run/transformation-workbench'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
kit=read(base/'primitive-prefabs.json');graph=read(base/'capacity-artifacts.json');rooms=read(base/'rooms.json');models=read(ROOT.parent/'ada_encyclopedia/public/void-models/manifest.json');registry=available_artifacts()
for name in ['primitive-prefabs.json','capacity-artifacts.json']:
    if not (out/('before-'+name)).exists():(out/('before-'+name)).write_bytes((base/name).read_bytes())
ids={p['id'] for p in kit['prefabs']};nodeids={n['id'] for n in graph['nodes']}
def add(p,parents):
    if p['id'] in ids:return
    kit['prefabs'].append(p);ids.add(p['id'])
    if p['id'] not in nodeids:
        graph['nodes'].append(dict(id=p['id'],title=p['title'],sequence='transformation',learn=p['learn'],use=p['behaviour'],icon='body',insertion=dict(map=p['map'],basis='authored',reason='Existing Transformation source, exposed in the shared workbench.')));nodeids.add(p['id'])
    for source in parents:graph['edges'].append(dict(source=source,target=p['id'],kind='develop',label=p['learn']))
def entry(id,title,map,family,scene,learn,recipe,**more):
    p=dict(id=id,title=title,map=map,family=family,scene=scene,dimensions=None,anchor='Floor-local source origin; coloured axes stay fixed while the preview transforms.',behaviour='Place the existing source in the live editor. Its own animation, collider and controls run in the game.',icon='body',learn=learn,recipe=recipe,**more)
    add(p,recipe)

for floor in [13,14,16,17,18,19]:
    f=rooms['floors'][floor]
    for a in f['artifacts']:
        id=f'trans_{floor}_'+a['id'].replace('-','_')
        operation='rotate' if any(t in a['artifact'] for t in ['rotat','carousel','axial','hinge','rc']) else 'scale' if any(t in a['artifact'] for t in ['scale','grower']) else 'translate'
        recipe=['construction_cube'] if operation!='rotate' else ['construction_cube','timber_plank_2m']
        study=dict(operation=operation,travel=[3,0,0],angle=180,min_scale=.5,max_scale=1.5)
        if a['artifact']=='void_trial_introduction_mezzanine':
            source=models['floors'][str(floor)]['artifacts'][a['id']]
            for name in ['GrowingCube','TurningPlank']:
                d=source['parts'][name]['default'];config=copy.deepcopy(a['config']);config.update(only_parts=[name],parts={name:dict(position=[0,d['position'][1],0],rotation=d['rotation'])})
                entry('trans_intro_'+name.lower(),'Growing cube / scale' if name=='GrowingCube' else 'Turning plank / rotation',f['map'],'Operation / scale' if name=='GrowingCube' else 'Operation / rotation',registry[a['artifact']]['scene'],'The known cube changes size.' if name=='GrowingCube' else 'The known plank turns about its centre.',recipe,placement=dict(artifact=a['artifact'],source_floor=floor,source_id=a['id'],config=config),transform_study=dict(study,operation='scale' if name=='GrowingCube' else 'rotate'))
        entry(id,a.get('config',{}).get('editor_label',registry[a['artifact']].get('label',a['artifact'])),f['map'],'Transformation / '+operation,registry[a['artifact']]['scene'],
              'Keep the familiar body; change its position, direction or occupied size. Compare the source before and after the operation.',recipe,
              placement=dict(artifact=a['artifact'],source_floor=floor,source_id=a['id'],height=a['height'],scale=a['scale'],config=copy.deepcopy(a.get('config',{}))),transform_study=study)

f=rooms['floors'][15]
for kind,title,pos,extra in [('platform','Suspended carrier / translation',[0,3,0],dict(travel=[0,0,-8],speed=1,pause=4)),('rotating_platform','Centre-supported platform / rotation',[0,1,0],dict(angle=-90,turn_speed=9,pause=6,length=4)),('deck','Steel deck / one metre',[0,0,0],{}),('truss','Steel truss / one metre',[0,0,0],{}),('collar','Pillar collar / one metre',[0,0,0],{}),('slab','Concrete slab / one metre',[0,0,0],{})]:
    entry('trans_module_'+kind,title,'Trans_Translation','Construction / '+kind,'res://commons/void/construction_grid.gd','The existing metre grid and kit carry a moving or fixed construction module.',['construction_cube','wp','timber_panel_1x1'],construction=dict(items=[dict(id='module',kind=kind,position=pos,facing=0,**extra)]),transform_study=dict(operation='rotate' if kind=='rotating_platform' else 'translate',travel=[3,0,0],angle=180,min_scale=.5,max_scale=1.5))
entry('trans_translation_mezzanine','Translation / mirrored mezzanine + bridge',f['map'],'Assembly / transformation','res://commons/void/construction_grid.gd','The same construction is reflected across the floor; a shared deck links the two original moving crossings.',['melencolia_court','trans_module_platform','trans_module_deck','trans_module_truss'],construction=dict(items=copy.deepcopy(f['construction'])),transform_study=dict(operation='translate',travel=[3,0,0],angle=180,min_scale=.5,max_scale=1.5))
for name,value in [('primitive-prefabs.json',kit),('capacity-artifacts.json',graph)]: (base/name).write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps(dict(definitions=len(kit['prefabs']),nodes=len(graph['nodes']),edges=len(graph['edges']))))
