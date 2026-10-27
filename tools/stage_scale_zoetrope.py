"""Register the hand-driven study and stage one additive floor59 edit."""
import copy, hashlib, json, sys, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/scale-zoetrope'
URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=True);assert not (OUT/'before-rooms.json').exists(),'Preserve prior draft'
 title='Hand wheel / scale zoetrope'
 entry=dict(lookup_name='scale_zoetrope',name=title,label=title,scene='res://commons/artifacts/scale_zoetrope/scale_zoetrope.tscn',description='Turn the crank and look through the centre-facing slit. Twelve permanently sized timber cubes pass behind a geared physical shutter. Open the side panel to inspect the disk.',qfep_connection='A continuous-looking change is made from discrete fixed objects and selected views. The enclosure controls what can be seen; opening it reveals that construction.',category='wavefunctions',dev_category='wavefunctions',complexity='beginner',tags=['zoetrope','scale','sequence','manual','shutter'],interactions=['Desktop: drag the wheel rim.','XR: grip the wooden crank and turn.','Click or point-press the brass side latch to open the service panel.'],parameters={'initial_angle':'Hand-wheel phase in degrees; no motor.','service_open':'Open the side panel on loading.'},footprint=[6.3,4.1,4.6],museum_import=True)
 write(ROOT/'commons/artifacts/registry/scale_zoetrope.json',{'artifacts':{'scale_zoetrope':entry}})
 p=ROOT/'commons/void/catalog.json';d=read(p);assert 'scale_zoetrope' not in d['artifacts'];d['artifacts']['scale_zoetrope']=entry;write(p,d)
 recipe=['construction_cube','timber_panel_1x1']
 p=ROOT/'commons/void/primitive-prefabs.json';d=read(p);assert not any(x['id']=='scale_zoetrope' for x in d['prefabs'])
 d['prefabs'].append(dict(id='scale_zoetrope',title=title,map='WaveFunctions_Intro',family='Wavefunctions / physical animation',scene=entry['scene'],dimensions=[4.18,4,4.6],anchor='Floor-local origin at the disk axis. Front slit faces +Z. Reserve right-hand service-door sweep to x=4.2m.',behaviour=entry['description'],learn='Separate fixed sizes become a sequence through motion and brief views. Ideal gearing, not force-based transmission.',icon='body',recipe=recipe,placement=dict(artifact='scale_zoetrope',source_floor=59,source_id='hand-scale-zoetrope',height=0,scale=1,config={'initial_angle':0,'service_open':False})));write(p,d)
 p=ROOT/'commons/void/capacity-artifacts.json';d=read(p)
 d['nodes'].append(dict(id='scale_zoetrope',title=title,sequence='wavefunctions',learn='Discrete fixed cubes become a visible size sequence.',use=entry['description'],icon='body',insertion=dict(map='WaveFunctions_Intro',basis='authored',reason='Rotation, sampling and apparent scale change.')))
 for parent in recipe:d['edges'].append(dict(source=parent,target='scale_zoetrope',kind='combine',label='Known timber parts become physical animation.'))
 d['edges'].append(dict(source='sine_yoke',target='scale_zoetrope',kind='develop',label='Carry hand-driven rotation into discrete frames and viewing intervals.'));write(p,d)
 now=json.load(urllib.request.urlopen(URL,timeout=30));rooms=copy.deepcopy(now['rooms']);f=rooms['floors'][59]
 assert f['map']=='WaveFunctions_Intro' and len(f['artifacts'])==22
 f['artifacts'].append(dict(id='hand-scale-zoetrope',artifact='scale_zoetrope',station='NE',position=[1,-5.4],height=0,facing=0,scale=1,config={'initial_angle':0,'service_open':False}))
 valid=post({'rooms':rooms,'validateOnly':True});assert valid['valid'],valid
 write(OUT/'before-rooms.json',now['rooms']);write(OUT/'draft-rooms.json',rooms);write(OUT/'validation.json',valid)
 print('Registered catalogue; staged one additive floor59 artifact, live rooms unchanged.')
def publish():
 report=read(OUT/'checks.json');assert report['passed'],report
 assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][59]==before['floors'][59],'Floor changed; review merge'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 write(OUT/'save-receipt.json',post({'rooms':rooms,'revision':now['revision']}))
 assert json.load(urllib.request.urlopen(URL))['rooms']==rooms
 print('Saved floor59 only, preserving current other floors.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
