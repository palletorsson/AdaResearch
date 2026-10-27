"""Add playback defaults without moving or replacing any floor object."""
import copy,hashlib,json,sys,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/scale-zoetrope-playback';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=True);assert not (OUT/'before-rooms.json').exists(),'Preserve existing draft'
 defaults=dict(auto_run=True,motor_rpm=60.0,sample_hz=0.0,shutter_enabled=False)
 description='The disk runs automatically until you take the crank by hand. Set RPM, compare display or local sampling clocks, match one cube per sample, reverse, and toggle the physical shutter. Open the service panel to inspect the fixed-size cubes.'
 p=ROOT/'commons/artifacts/registry/scale_zoetrope.json';d=read(p);entry=d['artifacts']['scale_zoetrope'];entry['description']=description
 entry['parameters'].update(auto_run='Resume automatic motion .65s after releasing the hand wheel.',motor_rpm='0..3600 revolutions per minute; match high display rates.',sample_hz='0: display frames. Local clock presets:6,12,24,30,60,90,120Hz. This does not change game FPS.',shutter_enabled='Optional physical shutter; initially off.')
 entry['interactions']=['Drag the crank to override the motor; release to resume.','RPM and CLOCK faders set rotation and local sampling.','RUN, SHUTTER, MATCH and REVERSE buttons.','MATCH advances one cube per selected clock sample; display matching uses measured FPS.','Press the side latch to inspect the construction.'];write(p,d)
 p=ROOT/'commons/void/catalog.json';d=read(p);d['artifacts']['scale_zoetrope']=entry;write(p,d)
 p=ROOT/'commons/void/primitive-prefabs.json';d=read(p);prefab=next(x for x in d['prefabs'] if x['id']=='scale_zoetrope');prefab['placement']['config'].update(defaults);prefab['behaviour']=description;prefab['learn']='A discrete display samples moving fixed-size objects. One cube advance per sample holds its position while size changes; detuning reveals drift.';write(p,d)
 p=ROOT/'commons/void/capacity-artifacts.json';d=read(p);node=next(x for x in d['nodes'] if x['id']=='scale_zoetrope');node['use']=description;node['learn']=prefab['learn'];write(p,d)
 now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);piece=next(x for x in rooms['floors'][59]['artifacts'] if x['id']=='hand-scale-zoetrope');piece.setdefault('config',{}).update(defaults)
 valid=post(dict(rooms=rooms,validateOnly=True));assert valid['valid'],valid
 write(OUT/'before-rooms.json',now['rooms']);write(OUT/'draft-rooms.json',rooms);write(OUT/'validation.json',valid)
 print('Staged playback settings only; no layout changes published.')
def publish():
 report=read(OUT/'checks.json');assert report['passed'],report
 assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][59]==before['floors'][59],'Floor changed; review merge'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 write(OUT/'save-receipt.json',post(dict(rooms=rooms,revision=now['revision'])))
 print('Saved playback defaults, preserving every object placement.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
