"""Two new motion studies. Preserve the user's current floor59 arrangement."""
import copy,json,sys,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/spinning-studies';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=False)
 now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);floor=rooms['floors'][59]
 specs=[('torus_piston','Wheel / cylinder / torus',[6.7,3.25,2.65],['sine_yoke','single_cube_turntable'],'An exposed finite connecting rod converts wheel rotation into a 1.60 m horizontal stroke. A white cylinder with red bands enters a stationary pink torus. Ideal kinematics, not simulated force or pumping.'),('pillar_barber_roll','Pillar / pink red white barber roll',[1.6,5.41,1.6],['single_cube_turntable'],'A pink/red/white helical sleeve physically rotates around a stationary structural pillar. No band moves vertically: a fixed witness makes the apparent climb and real rotation visible.')]
 catp=ROOT/'commons/void/catalog.json';catalog=read(catp)
 pp=ROOT/'commons/void/primitive-prefabs.json';prefabs=read(pp)
 gp=ROOT/'commons/void/capacity-artifacts.json';graph=read(gp)
 registry={'artifacts':{}}
 for key,title,dimensions,recipe,learn in specs:
  assert key not in catalog['artifacts'] and not any(p['id']==key for p in prefabs['prefabs'])
  entry=dict(lookup_name=key,name=title,label=title,scene=f'res://commons/artifacts/{key}/{key}.tscn',description=learn,qfep_connection='An observable constraint distinguishes actual movement from apparent movement. A shared input does not imply an independent animation.',category='wavefunctions',dev_category='wavefunctions',footprint=dimensions,museum_import=True)
  registry['artifacts'][key]=entry;catalog['artifacts'][key]=entry
  source='torus-crank-study' if key=='torus_piston' else 'barber-pillar-south'
  prefabs['prefabs'].append(dict(id=key,title=title,map='WaveFunctions_Intro',family='Wavefunctions / motion converter',scene=entry['scene'],dimensions=dimensions,anchor='Floor-local; place a barber sleeve centered on a 0.9 m square structural pillar.',behaviour=learn,learn=learn,icon='body',recipe=recipe,placement=dict(artifact=key,source_floor=59,source_id=source,height=0,scale=1)))
  graph['nodes'].append(dict(id=key,title=title,sequence='wavefunctions',learn=learn,use=learn,icon='body',insertion=dict(map='WaveFunctions_Intro',basis='authored',reason='Compare a physical straight stroke with apparent vertical motion from a closed rotation.')))
  for ingredient in recipe:graph['edges'].append(dict(source=ingredient,target=key,kind='develop',label='Reuse the visible rotational input.'))
 floor['artifacts'].extend([
  dict(id='torus-crank-study',artifact='torus_piston',position=[16.8,-2.5],height=0,facing=0,scale=1,station='NE',config={'motor_rpm':8.0,'auto_run':True}),
  dict(id='barber-pillar-south',artifact='pillar_barber_roll',position=[14,7],height=0,facing=0,scale=1,station='SE'),
  dict(id='barber-pillar-north',artifact='pillar_barber_roll',position=[14,-7],height=0,facing=0,scale=1,station='NE',config={'spin_speed':-.075})])
 for p,d in [(catp,catalog),(pp,prefabs),(gp,graph),(ROOT/'commons/artifacts/registry/spinning_studies.json',registry),(OUT/'before-rooms.json',now['rooms']),(OUT/'draft-rooms.json',rooms)]:write(p,d)
 valid=post(dict(rooms=rooms,validateOnly=True));write(OUT/'validation.json',valid);assert valid['valid'],valid
 print('Drafted piston and two pillar sleeves; existing floor unchanged.')
def publish():
 assert read(OUT/'checks.json')['passed']
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][59]==before['floors'][59],'User floor changed; merge required.'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 result=post(dict(rooms=rooms,revision=now['revision']));write(OUT/'save-receipt.json',result);assert result['saved'];print('Saved only three new occurrences; all earlier layout preserved.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
