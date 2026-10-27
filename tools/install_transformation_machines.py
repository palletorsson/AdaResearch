"""Add the tested machine parts to the shared catalogue and free central bay.

Revisioned saves preserve the entire existing mezzanine/crossing and other floors.
This does not unlock inventory items or edit manuscript chapters.
"""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/transformation-machines'
assert json.loads((OUT/'native.json').read_text())['passed'],'Complete the physical probe before installation.'
URL='http://localhost:3003/api/void-layout'
def post(data):
    req=urllib.request.Request(URL,json.dumps(data).encode(),{'Content-Type':'application/json'},method='POST')
    try:return json.load(urllib.request.urlopen(req))
    except urllib.error.HTTPError as error:raise RuntimeError(error.read().decode())
current=json.load(urllib.request.urlopen(URL));before=current['rooms'];rooms=copy.deepcopy(before)
f=rooms['floors'][15];assert f['map']=='Trans_Translation'
specs=[
 ('crank','Wood crank / metal rod / piston',[-3.5,-4.5],['timber_plank_2m','construction_cube','trace_point_ball'],'Rotation constrains a metal connecting rod; the rod translates a wooden piston. Contact can deliver a ball. Unpin the rod: turning alone no longer guarantees delivery.'),
 ('lever','Working lever / two effort arms',[0,2.2],['timber_plank_4m','wp','construction_cube'],'Pull the same loaded beam at two distances from its pivot. A real hinge and attached rigid load determine what lifts.'),
 ('suspended','Rope / suspended construction cube',[0,-.5],['construction_cube','timber_plank_2m'],'Pull and release the cube with a bounded force grip. Four pinned links keep it attached; gravity, contact and the slot determine its passage.'),
 ('sorter','Gravity / sort by physical size',[3.5,-4.5],['timber_plank_2m','trace_point_ball'],'Release three differently sized white spheres of equal mass onto identical diverging rails. Gravity and contact decide where each exits; the readout observes those exits.')]
catalog_path=ROOT/'commons/void/catalog.json';catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
prefab_path=ROOT/'commons/void/primitive-prefabs.json';prefabs=json.loads(prefab_path.read_text(encoding='utf-8'))
graph_path=ROOT/'commons/void/capacity-artifacts.json';graph=json.loads(graph_path.read_text(encoding='utf-8'))
assert not any(a['id'].startswith('machine-') for a in f['artifacts']),'Machines already installed; preserve edits.'
for name,value in [('rooms',before),('catalog',catalog),('prefabs',prefabs),('graph',graph)]:
    target=OUT/('before-'+name+'.json');assert not target.exists(),'Review previous installation before rerunning.'
    target.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
registry={'artifacts':{}}
for kind,title,at,recipe,learn in specs:
    key='trans_machine_'+kind;scene='res://commons/artifacts/transformation_machines/'+kind+'.tscn';id='machine-'+kind
    assert key not in catalog['artifacts'] and not any(p['id']==key for p in prefabs['prefabs'])
    config={'editor_label':title}
    catalog['artifacts'][key]={'name':title,'scene':scene,'museum_import':True,'footprint':[6,5.64,5],'color':'#ba9270'}
    registry['artifacts'][key]={'lookup_name':key,'name':title,'scene':scene,'description':learn,'category':'transforms','dev_category':'transforms','dev_themes':['transformation','mechanism','physical consequence'],'map_ready':True,'include_in_map_data':True,'auto_ground':False,'map_sequences':['transformation'],'complexity':'intermediate','qfep_connection':'A constraint is a rule with material consequences. Visible motion does not guarantee an outcome; coupling, contact and clearance make success conditional.'}
    f['artifacts'].append(dict(id=id,artifact=key,position=at,station='NW',facing=0,height=0,scale=1,config=config))
    prefabs['prefabs'].append(dict(id=key,title=title,map='Trans_Translation',family='Transformation / physical mechanism',scene=scene,dimensions=None,anchor='Floor-local origin; ceiling brackets at 5.64 m. Keep physical assemblies at unit scale.',behaviour='Pull the existing rose force grips. The joints stay attached. RESET begins a matched trial; a result is observed from physical bodies.',learn=learn,icon='body',recipe=recipe,placement=dict(artifact=key,source_floor=15,source_id=id,height=0,scale=1,config=config),transform_study=dict(operation='compose',travel=[3,0,0],angle=180,min_scale=.5,max_scale=1.5)))
    graph['nodes'].append(dict(id=key,title=title,sequence='transformation',learn=learn,use='Place this original physical assembly; inspect its result in the game.',icon='body',insertion=dict(map='Trans_Translation',basis='physical constraints',reason='Motion becomes a cause: rotating, lifting, suspending, sorting.')))
    for ingredient in recipe:graph['edges'].append(dict(source=ingredient,target=key,kind='combine',label='Reuse the familiar part in a physical mechanism.'))
f['title']='Translation / mirrored crossings and suspended machines'
assert f['construction']==before['floors'][15]['construction']
assert f.get('route')==before['floors'][15].get('route')
assert all(rooms['floors'][i]==before['floors'][i] for i in range(len(rooms['floors'])) if i!=15)
# The normal validator resolves the explicit Void catalogue; publish only these
# definitions before validation, restoring them on an unsuccessful layout save.
catalog_path.write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
try:
    result=post(dict(rooms=rooms,validateOnly=True));assert result['valid'],result
    receipt=post(dict(rooms=rooms,revision=current['revision']))
except BaseException:
    catalog_path.write_text((OUT/'before-catalog.json').read_text(encoding='utf-8'),encoding='utf-8');raise
prefab_path.write_text(json.dumps(prefabs,indent=2)+'\n',encoding='utf-8')
graph_path.write_text(json.dumps(graph,indent=2)+'\n',encoding='utf-8')
(ROOT/'commons/artifacts/registry/transformation_machines.json').write_text(json.dumps(registry,indent=2)+'\n',encoding='utf-8')
(OUT/'save-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
assert json.load(urllib.request.urlopen(URL))['rooms']==rooms
print('Four physical machines added to floor15. Existing crossing, all348 cells and all other floors preserved.')
