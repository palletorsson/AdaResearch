"""One floor staging revision: existing boxes and wp ramps replace benches."""
import copy,hashlib,json,sys,urllib.request,urllib.error
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/wavefunctions-block-supports';OUT.mkdir(exist_ok=True)
URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):
 r=urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST')
 try:return json.load(urllib.request.urlopen(r,timeout=90))
 except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode()) from e
def prepare():
 assert not (OUT/'before-rooms.json').exists(),'Preserve existing draft.'
 current=json.load(urllib.request.urlopen(URL,timeout=30));rooms=copy.deepcopy(current['rooms']);f=rooms['floors'][59]
 assert f['map']=='WaveFunctions_Intro'
 removed=[p for p in f['props'] if p['kind']=='workbench'];assert len(removed)==7
 f['props']=[p for p in f['props'] if p['kind']!='workbench']
 f.setdefault('construction',[])
 def cell(id,kind,x,z,facing=0):f['construction'].append(dict(id='wave-block-'+id,kind=kind,position=[x,0,z],facing=facing))
 for id,kind,x,z in [('clock-a','cube',-3.5,3),('clock-b','cube',-2.5,3),('turn-a','cube',-.5,3),('turn-b','cube',.5,3),('driven-a','cube',2.5,-2),('driven-b','cube',3.5,-2),('still','cube',-18,0),('rotation','cube',-16.5,0),('transform','cube',-15,0),('record-a','cube',15.5,-4),('record-b','cube',16.5,-4)]:cell(id,kind,x,z)
 # Five metre-long box run, with two approaches clear of the x=-14 pillar.
 for i in range(5):cell('west-dock-'+str(i),'cube',-18+i,4.5)
 for i,x in enumerate([-18,-16]):cell('west-ramp-'+str(i),'wedge',x,6,180)
 # A shared top keeps all five sizes reachable along the same one-metre level.
 for i in range(7):cell('east-dock-'+str(i),'cube',13.5+i,5)
 for i,x in enumerate([15.5,18.5]):cell('east-ramp-'+str(i),'wedge',x,6.5,180)
 for a in f['artifacts']:
  if a['id']=='clock':a['height']=1.5
  if a['id']=='driven':a['height']=1.45
  if a['id'] in ['pickup-still','pickup-turn','pickup-transform']:a['height']=.75
  if a['id'].startswith('size-'):a['height']=1
 result=post(dict(rooms=rooms,validateOnly=True));assert result['valid'],result
 write(OUT/'before-rooms.json',current['rooms']);write(OUT/'draft-rooms.json',rooms);write(OUT/'validation.json',result)
 write(OUT/'plan.json',dict(removed_benches=[p['id'] for p in removed],added_cells=len(f['construction']),scope='Floor59 block supports and two pickup ramp runs. Scale/rotate room clarification pending. No new room behaviour.'))
 print('Staged removal of seven benches and 27 existing cube/wedge modules. Live layout unchanged.')
def publish():
 report=read(OUT/'checks.json');assert report['passed'],report
 assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
 before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json');now=json.load(urllib.request.urlopen(URL,timeout=30))
 assert now['rooms']['floors'][59]==before['floors'][59],'Floor59 changed; merge with review.'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 write(OUT/'before-publish-rooms.json',now['rooms']);write(OUT/'save-receipt.json',post(dict(rooms=rooms,revision=now['revision'])))
 assert json.load(urllib.request.urlopen(URL,timeout=30))['rooms']==rooms
 print('Saved only floor59 through revisioned editor API.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
