"""Register source ports in their own standard-size trial, never replacing sketches."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
def read(p): return json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d): (R/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
trial='matter_logic_reference'; target=R/'commons/void/trials'/trial
if target.exists(): raise SystemExit('Already registered; refusing to replace arrangements')
target.mkdir()
definition={'lookup_name':'matter_reference','name':'Matter Gates / original mechanisms','scene':'res://commons/artifacts/matter_reference/matter_reference.tscn','configure_before_ready':True,'map_ready':True,'category':'primitives','description':'Original source geometry and masses: falling crates, tyre, sandbag balance and counterweight. Inputs release bodies; Jolt contacts determine the result.','default_params':{'kind':'and'}}
kinds=['and','or','xor','not','nor','nand']
definitions={'matter_reference':definition}
for k in kinds: definitions['matter_reference_'+k]=dict(definition,lookup_name='matter_reference_'+k,name='Matter Gates / original '+k.upper(),default_params={'kind':k})
write('commons/artifacts/registry/matter_reference.json',{'artifacts':definitions})
catalog=read('commons/void/catalog.json');catalog['artifacts'].update(definitions);write('commons/void/catalog.json',catalog)
layout=copy.deepcopy(read('commons/void/trials/matter_gates/layout.json'))
layout.update(status='Original Matter Gates / full size comparison',levels=[-6*i for i in range(8)],floor_roles=['Roof',*[k.upper() for k in kinds],'Catch floor'],floor_styles={str(i):'abstract' for i in range(8)},route_note='Original source mechanisms at original scale. Central exhibits avoid both shaft footprints. Source ground is supplied by the actual standard slab.')
layout['descent']['pad_shafts']={str(i):'A' for i in range(1,8)}
write('commons/void/trials/'+trial+'/layout.json',layout)
floors=[]
for i,k in enumerate(['roof',*kinds,'catch']):
 f={'map':'Point_Animatedcube','title':'Matter Gates / '+k.upper(),'origin':False,'walls':[],'artifacts':[],'props':[],'impact_cells':[],'route':[],'supply_leads':False}
 if k in kinds:f['artifacts']=[{'id':k,'artifact':'matter_reference_'+k,'station':'NW','position':[0,0],'height':0,'facing':0,'scale':1,'config':{'kind':k,'editor_label':'Original '+k.upper()+' / physical mechanism'}}]
 floors.append(f)
write('commons/void/trials/'+trial+'/rooms.json',{'version':1,'floors':floors})
(target/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n[node name="MatterReferenceTrial" instance=ExtResource("1")]\ntrial_id = "'+trial+'"\n',encoding='utf-8')
playable=read('commons/void/trials/playable.json');playable['trials'][trial]={'title':'Matter and Logic / original gate mechanisms','label':'MATTER / ORIGINAL GATES','map':'Point_Animatedcube','start_floor':1,'notice':'Choose X and Y, then RELEASE. Inputs only release the selected objects. Observe the physical result; RESET for a fresh take. Full-size source comparison.','rooms':f'res://commons/void/trials/{trial}/rooms.json','layout':f'res://commons/void/trials/{trial}/layout.json','scene':f'res://commons/void/trials/{trial}/trial.tscn','models':f'/void-trials/{trial}/manifest.json','retry_floors':{str(i):max(1,min(i,6)) for i in range(8)},'spawn_points':{str(i):[0,.06,4.5] for i in range(1,7)}}
write('commons/void/trials/playable.json',playable)
print('Registered',trial)
