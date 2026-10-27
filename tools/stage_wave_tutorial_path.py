"""Stage the three-machine path; preserve occurrence IDs and unrelated floors."""
import copy,hashlib,json,sys,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/wave-tutorial-path';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=True);assert not (OUT/'before-rooms.json').exists(),'Keep existing staging'
 entry=dict(lookup_name='single_cube_turntable',name='Hand wheel / one cube turntable',label='Hand wheel / one cube turntable',scene='res://commons/artifacts/single_cube_turntable/single_cube_turntable.tscn',description='Turn a platform carrying one fixed off-white cube. Hand input, speed and direction control the same rotating parent, so the cube travels and turns with the plate. Black steel, pink grips and the shared machine finish.',qfep_connection='A rotating support carries a body through space. Its position and orientation share one transformation; the cube has no hidden independent animation.',category='wavefunctions',dev_category='wavefunctions',complexity='beginner',tags=['rotation','platform','one cube','manual'],interactions=['Drag the pink wheel or grip it in XR.','RPM sets 0..30; ANGLE pauses and places a phase.','RUN and REVERSE control automatic rotation.'],parameters={'motor_rpm':'0..30 revolutions per minute.','auto_run':'The motor yields to a held wheel and resumes after release.'},footprint=[2.65,2.5,3.15],museum_import=True)
 write(ROOT/'commons/artifacts/registry/single_cube_turntable.json',{'artifacts':{'single_cube_turntable':entry}})
 p=ROOT/'commons/void/catalog.json';d=read(p);d['artifacts']['single_cube_turntable']=entry;write(p,d)
 p=ROOT/'commons/void/primitive-prefabs.json';d=read(p);assert not any(n['id']=='single_cube_turntable' for n in d['prefabs'])
 d['prefabs'].append(dict(id='single_cube_turntable',title=entry['name'],map='WaveFunctions_Intro',family='Wavefunctions / physical animation',scene=entry['scene'],dimensions=entry['footprint'],anchor='Floor-local plate axis. Plate top 1.05 m; controls face +Z and remain at hand height.',behaviour=entry['description'],learn='One cube stays fixed to a moving platform: one parent transform changes position and orientation together.',icon='body',recipe=['construction_cube','sine_yoke'],placement=dict(artifact='single_cube_turntable',source_floor=59,source_id='hand-single-turntable',height=0,scale=1,config={'motor_rpm':10.0,'auto_run':True})))
 write(p,d)
 p=ROOT/'commons/void/capacity-artifacts.json';d=read(p)
 d['nodes'].append(dict(id='single_cube_turntable',title=entry['name'],sequence='wavefunctions',learn='A single rigid attachment carries position and orientation through one turn.',use=entry['description'],icon='body',insertion=dict(map='WaveFunctions_Intro',basis='authored',reason='The physical step between a crank-driven projection and a sequence of carried cubes.')))
 d['edges'].extend([dict(source='sine_yoke',target='single_cube_turntable',kind='develop',label='Carry the hand-driven angle into a rotating support.'),dict(source='construction_cube',target='single_cube_turntable',kind='combine',label='One known body fixed to the plate.'),dict(source='single_cube_turntable',target='scale_zoetrope',kind='develop',label='One carried body becomes a sequence of fixed frames.')]);write(p,d)
 now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);f=rooms['floors'][59]
 assert f['map']=='WaveFunctions_Intro'
 moves={'clock':[-18,-6.4],'turn':[-15.5,-6.4],'monitor':[-4.6,1.0],'pendulum':[-4.6,-1.8],'driven':[-4.6,-4.7],'dark':[-18.5,-2.7]}
 for a in f['artifacts']:
  if a['id'] not in moves:continue
  old=a['position'];new=moves[a['id']]
  for c in f.get('construction',[]):
   tags={'clock':'wave-block-clock-','turn':'wave-block-turn-','driven':'wave-block-driven-'}
   if a['id'] in tags and c['id'].startswith(tags[a['id']]):c['position'][0]+=new[0]-old[0];c['position'][2]+=new[1]-old[1]
  a['position']=new
 for p in f['props']:
  if p['id']=='return-bay-stock':p['position']=[-6.3,6.2];p['facing']=90
  if p['id']=='return-bay-lamp':p['position']=[-2.8,7.9];p['facing']=180
  if p['id']=='return-bay-backdrop':p['position']=[-6.4,-1.8];p['facing']=90
  if p['id']=='return-bay-side':p['position']=[-6.6,-5.6];p['facing']=90
  if p['id']=='return-bay-low-edge':p['position']=[-6.1,-3.6];p['facing']=0
 f['artifacts'].append(dict(id='hand-single-turntable',artifact='single_cube_turntable',station='NE',position=[4.2,3.1],height=0,facing=90,scale=1,config={'motor_rpm':10.0,'auto_run':True}))
 new_cells=[]
 def cell(id,kind,x,z,y=0,facing=0):new_cells.append(dict(id='wave-path-'+id,kind=kind,position=[x,y,z],facing=facing))
 for i,x in enumerate([-3.8,-2.8,-1.8,-.8,.2]):cell('yoke-back-'+str(i),'cube',x,4.6)
 for i,x in enumerate([-3.8,.2]):cell('yoke-cap-'+str(i),'cube',x,4.6,1)
 cell('yoke-left','cube',-3.8,5.6);cell('yoke-ramp','wedge',-3.8,7.1,facing=180)
 for i,z in enumerate([1.6,2.6,3.6]):cell('turn-left-'+str(i),'cube',1.5,z)
 cell('turn-cap','cube',1.5,1.6,1);cell('turn-ramp','wedge',1.5,5.1,facing=180)
 for xi,x in enumerate([4.5,5.5]):
  for zi,z in enumerate([-1.5,-2.5,-3.5,-4.5]):cell('view-'+str(xi)+'-'+str(zi),'cube',x,z)
  cell('view-up-'+str(xi),'wedge',x,0,facing=180)
  cell('view-down-'+str(xi),'wedge',x,-6,facing=0)
 for i,z in enumerate([-2.5,-3.5]):
  for y in [0,1]:cell('view-edge-'+str(i)+'-'+str(y),'cube',6.5,z,y)
 cell('view-entry-edge','cube',6.5,-1.5)
 f.setdefault('construction',[]).extend(new_cells)
 f['route']=[dict(label='01 / HAND TO HEIGHT',position=[-1.6,7.2]),dict(label='02 / ONE CUBE. ONE TURN.',position=[6.8,2.1]),dict(label='03 / FIXED CUBES. MOVING SEQUENCE.',position=[5,-3.5],height=1)]
 write(OUT/'before-rooms.json',now['rooms']);write(OUT/'draft-rooms.json',rooms)
 write(OUT/'plan.json',dict(moves=moves,new_cells=len(new_cells),original_artifacts=len(now['rooms']['floors'][59]['artifacts']),artifacts=len(f['artifacts']),route_feet=[[-1.6,0,7.2],[1,0,7.2],[3.5,0,6.5],[5.7,0,4.7],[6.8,0,3.3],[6.8,0,2.1],[6.8,0,1.25],[5.1,0,1.25],[5.1,1,-1.5],[5.1,1,-3.5],[5.8,1,-4.5],[5.8,0,-7.7]]))
 valid=post(dict(rooms=rooms,validateOnly=True));write(OUT/'validation.json',valid);assert valid['valid'],valid
 print('Staged',len(new_cells),'independent cube/wedge modules and one turntable; live floor unchanged.')
def publish():
 report=read(OUT/'checks.json');assert report['passed'],report
 assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][59]==before['floors'][59],'Floor59 changed; merge required'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][59]=draft['floors'][59]
 result=post(dict(rooms=rooms,revision=now['revision']));write(OUT/'save-receipt.json',result);assert result['saved'];print('Saved floor59 path, preserving current other floors.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
