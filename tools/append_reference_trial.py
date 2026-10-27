"""Append verified source ports to the comparison trial without replacing layouts."""
from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1]
def read(p):return json.loads((R/p).read_text(encoding='utf-8'))
def write(p,d):(R/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def append(jobs):
 trial='matter_logic_reference';prefix='commons/void/trials/'+trial+'/';rooms=read(prefix+'rooms.json');catalog=read('commons/void/catalog.json');registry=read('commons/artifacts/registry/matter_reference.json');playable=read('commons/void/trials/playable.json');layout=read(prefix+'layout.json')
 ids={a['id'] for f in rooms['floors'] for a in f['artifacts']}
 for key,title,scene,config,height in jobs:
  if key in ids:continue
  d=dict(lookup_name=key,name=title,scene='res://commons/artifacts/matter_reference/'+scene+'.tscn',configure_before_ready=True,map_ready=True,category='reference_studies',default_params=config,description='Source-faithful Matter and Logic port. Original geometry and configurations; native controls and physical evidence are recorded in the port review.')
  registry['artifacts'][key]=d;catalog['artifacts'][key]=d;floor=copy.deepcopy(rooms['floors'][-1]);floor.update(title=title,artifacts=[dict(id=key,artifact=key,station='NW',position=[0,0],height=height,facing=0,scale=1,config=config)]);rooms['floors'].insert(-1,floor)
 n=len(rooms['floors']);layout.update(levels=[-6*i for i in range(n)],floor_roles=[f['title'] for f in rooms['floors']],floor_styles={str(i):'abstract' for i in range(n)});layout['descent']['pad_shafts']={str(i):'A' for i in range(1,n)}
 d=playable['trials'][trial];d['retry_floors']={str(i):max(1,min(i,n-2)) for i in range(n)};d['spawn_points'].update({str(i):[0,.06,4.5] for i in range(1,n-1)})
 for p,obj in [(prefix+'rooms.json',rooms),(prefix+'layout.json',layout),('commons/void/catalog.json',catalog),('commons/artifacts/registry/matter_reference.json',registry),('commons/void/trials/playable.json',playable)]:write(p,obj)
 print('Trial contains',n-2,'study floors')
if __name__=='__main__':
 append([('reference_tyre_chain','Tyre / plank / wedge','tyre_chain',{'kind':'chain'},0),('reference_stack_queue','Stack / queue','stack_queue',{'kind':'stackqueue'},0),*[(name.replace('-','_'),'Source / '+name,'program_flow',{'study':name,'kind':'functions' if name=='call-stack' else 'loops'},2.35) for name in ['call-stack','if-else-loop','list-loop','prefab-loop']]])
