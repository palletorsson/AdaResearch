"""Expose TriangleTable's existing pose as editable panels; add square sibling."""
import copy,json,sys,urllib.request,urllib.error,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/face-assembly';OUT.mkdir(exist_ok=True)
URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,j):p.write_text(json.dumps(j,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(j):
 try:return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(j).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
 except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode()) from e

def register():
 definitions={}
 for key,title,scene,number,floor,source,map_name,angle in [
  ('triangle_assembly_table','TriangleTable / folded edge assembly','res://commons/artifacts/primitive_encounters/triangle_assembly_table.tscn',3,5,'triangle-edge-assembly','Point_Triangle_Context',60),
  ('square_assembly_table','Square faces / folded edge assembly','res://commons/artifacts/face_assembly/square_assembly.tscn',4,7,'square-edge-assembly','Point_Animatedcube',90)]:
  definitions[key]=dict(lookup_name=key,name=title,label=title,scene=scene,map_ready=True,museum_import=True,description=f'Twelve movable {number}-sided panels. Select a fold from flat, bring two parallel free edges together and release. Lift a face to detach; other faces stay in place. Gold marks a candidate edge. Kinematic joins, not force-simulated glue.',category='primitives',dev_category='primitives',complexity='beginner',tags=['panels','edges','fold','assembly','mesh'],qfep_connection='A boundary becomes an insertion frame. The same face can bound different spaces according to the relation at its edge.',parameters={'fold_degrees':'Signed fold from flat, degrees. Default '+str(angle)+'. Applies only to new joins.'},interactions=['Desktop: RMB pick/place; Q/E roll, R/F tilt.','XR: grip, rotate, bring edges together and release.','Angle minus/plus, other side, start over.'],footprint=[3.2,1.47,1.6])
  kitfile=ROOT/'commons/void/primitive-prefabs.json';kit=read(kitfile)
  if not any(p['id']==key for p in kit['prefabs']):
   kit['prefabs'].append(dict(id=key,title=title,map=map_name,family='Primitives / joined faces',scene=scene,dimensions=[3.2,1.47,1.6],anchor='Floor beneath the existing table. Support, controls and all twelve faces are separately editable.',behaviour=definitions[key]['description'],learn='An edge fixes two shared endpoints while allowing a chosen fold into space.',icon='body',recipe=['draw_triangle_faces' if number==3 else 'timber_panel_1x1'],placement=dict(artifact=key,source_floor=floor,source_id=source,height=0,scale=1,config=dict(already_started=True,fold_degrees=angle))))
   write(kitfile,kit)
  graphfile=ROOT/'commons/void/capacity-artifacts.json';graph=read(graphfile)
  if not any(n['id']==key for n in graph['nodes']):
   graph['nodes'].append(dict(id=key,title=title,sequence='primitives',learn='Flat faces meet at a chosen angle and enclose a space.',use=definitions[key]['description'],icon='body',insertion=dict(map=map_name,basis='authored',reason='Hand-built forms retain explicit edge relationships.')))
   graph['edges'].append(dict(source='draw_triangle_faces' if number==3 else 'triangle_assembly_table',target=key,kind='combine',label='Reuse edge attachment with '+('triangular' if number==3 else 'square')+' faces.'))
   write(graphfile,graph)
 catalog=ROOT/'commons/void/catalog.json';data=read(catalog);data['artifacts'].update(definitions);write(catalog,data)
 registry=ROOT/'commons/artifacts/registry/primitive_encounters.json';data=read(registry);data['artifacts'].update(definitions);write(registry,data)

def prepare():
 assert not (OUT/'before-rooms.json').exists(),'Draft already exists; do not overwrite it.'
 register()
 current=json.load(urllib.request.urlopen(URL,timeout=30));rooms=copy.deepcopy(current['rooms'])
 floor=rooms['floors'][5];assert floor['map']=='Point_Triangle_Context'
 item=next(a for a in floor['artifacts'] if a['id']=='assembly')
 assert item['facing']==0 and item['scale']==1,'Compose the saved table transform explicitly if edited.'
 pose=item['config']['parts']['TriangleTable'];assert pose.get('rotation',[0,0,0])==[0,0,0]
 p=pose['position'];table=dict(id='triangle-edge-assembly',artifact='triangle_assembly_table',station='NW',position=[item['position'][0]+p[0],item['position'][1]+p[2]],height=item['height']+p[1],facing=0,scale=1,config=dict(already_started=True,fold_degrees=60))
 item['config']['only_parts']=['SheetOneMetre','SheetTwoByOne','SheetWallInfill','Caption']
 del item['config']['parts']['TriangleTable']
 floor['artifacts'].append(table)
 cube=rooms['floors'][7];assert cube['map']=='Point_Animatedcube'
 cube['artifacts'].append(dict(id='square-edge-assembly',artifact='square_assembly_table',station='SW',position=[-17,5.8],height=0,facing=0,scale=1,config=dict(already_started=True,fold_degrees=90)))
 validation=post(dict(rooms=rooms,validateOnly=True));assert validation['valid'],validation
 write(OUT/'before-rooms.json',current['rooms']);write(OUT/'draft-rooms.json',rooms);write(OUT/'validation.json',validation)
 print('Registered two related artifacts; staged floors5/7 without publishing.')
def publish():
 report=read(OUT/'checks.json');assert report['passed'],report
 assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
 before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json');current=json.load(urllib.request.urlopen(URL,timeout=30))
 rooms=copy.deepcopy(current['rooms'])
 for i in [5,7]:
  assert current['rooms']['floors'][i]==before['floors'][i],f'Floor{i} changed; merge required.'
  rooms['floors'][i]=draft['floors'][i]
 write(OUT/'before-publish-rooms.json',current['rooms']);write(OUT/'save-receipt.json',post(dict(rooms=rooms,revision=current['revision'])))
 assert json.load(urllib.request.urlopen(URL,timeout=30))['rooms']==rooms
 print('Saved floors5/7; other floors and visitor edits retained.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
