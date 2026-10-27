"""Add one coupled belt-drive study without changing existing visitor objects."""
import copy,json,sys,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/belt-drive';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=False)
 now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);f=rooms['floors'][59]
 key='belt_drive';title='Two wheels / one belt / 2:1'
 entry=dict(lookup_name=key,name=title,label=title,scene='res://commons/artifacts/belt_drive/belt_drive.tscn',description='Turn either of two unequal wheels linked by a visible open belt. One large-wheel turn produces two small-wheel turns in the same direction. Pink spokes and travelling belt witnesses expose the ratio. Ideal no-slip kinematics, not a force or tension simulation.',qfep_connection='A shared belt displacement constrains unequal circles to different angular speeds. One cause produces two visibly different rotations; appearance is tied to a declared geometric assumption.',category='wavefunctions',dev_category='wavefunctions',footprint=[5.12,3.05,2.53],museum_import=True)
 catp=ROOT/'commons/void/catalog.json';cat=read(catp);assert key not in cat['artifacts'];cat['artifacts'][key]=entry
 pp=ROOT/'commons/void/primitive-prefabs.json';prefabs=read(pp);assert not any(p['id']==key for p in prefabs['prefabs'])
 config={'motor_rpm':8.0,'auto_run':False}
 prefabs['prefabs'].append(dict(id=key,title=title,map='WaveFunctions_Intro',family='Wavefunctions / motion converter',scene=entry['scene'],dimensions=entry['footprint'],anchor='Floor-local fixed pulley bearings; front interaction faces +Z. Large pitch diameter 2.20m; small 1.10m.',behaviour=entry['description'],learn='Equal belt travel means twice the turns at half the radius. Either wheel can supply the input.',icon='body',recipe=['single_cube_turntable','torus_piston'],placement=dict(artifact=key,source_floor=59,source_id='two-wheel-belt-drive',height=0,scale=1,config=config)))
 gp=ROOT/'commons/void/capacity-artifacts.json';graph=read(gp)
 graph['nodes'].append(dict(id=key,title=title,sequence='wavefunctions',learn='One large-wheel turn produces two small-wheel turns through a shared belt.',use=entry['description'],icon='body',insertion=dict(map='WaveFunctions_Intro',basis='authored',reason='Carry the existing manual rotation into a second circular body through an exposed transmission.')))
 for source in ['single_cube_turntable','torus_piston']:graph['edges'].append(dict(source=source,target=key,kind='develop',label='One angular input becomes two linked angular speeds.'))
 f['artifacts'].append(dict(id='two-wheel-belt-drive',artifact=key,position=[.65,-.8],height=0,facing=0,scale=1,station='NW',config=config))
 for p,d in [(catp,cat),(pp,prefabs),(gp,graph),(ROOT/'commons/artifacts/registry/belt_drive.json',{'artifacts':{key:entry}}),(OUT/'before-rooms.json',now['rooms']),(OUT/'draft-rooms.json',rooms)]:write(p,d)
 validation=post(dict(rooms=rooms,validateOnly=True));write(OUT/'validation.json',validation);assert validation['valid'],validation
 print('Drafted one 2:1 belt drive; saved floor unchanged.')
def publish():
 assert read(OUT/'checks.json')['passed']
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][59]==before['floors'][59],'Visitor changed floor59; merge needed.'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 receipt=post(dict(rooms=rooms,revision=now['revision']));write(OUT/'save-receipt.json',receipt);assert receipt['saved']
 print('Saved one new mechanism, preserving the latest other floors and visitor arrangements.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
