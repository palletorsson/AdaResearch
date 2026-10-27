"""A ground-level logic playground below Trans Introduction's raised course."""
import copy,json,sys,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/intro-logic';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def post(d):return json.load(urllib.request.urlopen(urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST'),timeout=90))
def prepare():
 OUT.mkdir(exist_ok=False)
 now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);f=rooms['floors'][14]
 assert f['map']=='Trans_Introduction'
 catp=ROOT/'commons/void/catalog.json';catalog=read(catp)
 pp=ROOT/'commons/void/primitive-prefabs.json';prefabs=read(pp)
 gp=ROOT/'commons/void/capacity-artifacts.json';graph=read(gp);registry={'artifacts':{}}
 specs=[('and',-4.8,{'00':0,'01':0,'10':0,'11':1},'Two missing supports in series; both cubes must fall into place for the launched ball to hit the end target.'),('or',0,{'00':0,'01':1,'10':1,'11':1},'Two parallel lanes and two simultaneously launched test balls. A target hit on either route records one.'),('not',4.8,{'0':1,'1':0},'One continuous run. Input one drops a blocker; actual blocker contact records zero. With the blocker raised, an end-target hit records one.')]
 for op,x,truth,learn in specs:
  key='matter_spring_'+op;id='logic-spring-'+op;title='Matter / '+op.upper()+' / spring — earn the reusable assembly'
  assert key not in catalog['artifacts'] and not any(p['id']==key for p in prefabs['prefabs'])
  entry=dict(lookup_name=key,name=title,label=title,scene=f'res://commons/artifacts/matter_logic_spring/{op}.tscn',description=learn+' Twice the Cube-floor working size; waist-height table. A real Hooke-force piston pushes the white source balls through contact.',qfep_connection='An expected truth table is separate from material evidence. Geometry, gravity, spring compression and actual contact decide whether a ball reaches its target.',category='wavefunctions',dev_category='logic',footprint=[3.9,2.05,1.7],museum_import=True)
  registry['artifacts'][key]=entry;catalog['artifacts'][key]=entry
  prefabs['prefabs'].append(dict(id=key,title=title,map='Trans_Introduction',family='Logic / spring assembly',scene=entry['scene'],dimensions=entry['footprint'],anchor='Floor-local. Table top .84m, rolling surface1.08m; input cubes .24m and white balls .0672m diameter.',behaviour=entry['description'],learn=learn,icon='body',recipe=['matter_and','construction_cube','timber_plank_1m','trace_point_ball'],placement=dict(artifact=key,source_floor=14,source_id=id,height=0,scale=1),completion=dict(objective='trans-introduction-spring-'+op,map='Trans_Introduction',observations=truth)))
  graph['nodes'].append(dict(id=key,title=title,sequence='transformation',learn=learn,use=entry['description'],icon='body',insertion=dict(map='Trans_Introduction',basis='physical evidence',reason='Ground-level material logic below the raised transformations.')))
  graph['edges'].append(dict(source='matter_and',target=key,kind='develop',label='Reuse known parts at double working scale with a spring input and impact output.'))
  f['artifacts'].append(dict(id=id,artifact=key,station='SW' if x<0 else 'SE',position=[x,3.6],height=0,facing=0,scale=1,config={'editor_label':title}))
 for p,d in [(catp,catalog),(pp,prefabs),(gp,graph),(ROOT/'commons/artifacts/registry/matter_spring_logic.json',registry),(OUT/'before-rooms.json',now['rooms']),(OUT/'draft-rooms.json',rooms)]:write(p,d)
 v=post(dict(rooms=rooms,validateOnly=True));write(OUT/'validation.json',v);assert v['valid'],v
 print('Staged AND, OR, NOT on floor14. Raised course, floor7 and floor59 unchanged.')
def publish():
 assert read(OUT/'checks.json')['passed']
 now=json.load(urllib.request.urlopen(URL));before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
 assert now['rooms']['floors'][14]==before['floors'][14],'Visitor changed floor14; merge needed.'
 rooms=copy.deepcopy(now['rooms']);rooms['floors'][14]=draft['floors'][14]
 result=post(dict(rooms=rooms,revision=now['revision']));write(OUT/'save-receipt.json',result);assert result['saved']
 print('Saved three logic lessons on floor14; latest other floors preserved.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
