from pathlib import Path
import copy,hashlib,json,shutil
R=Path(__file__).resolve().parents[1]
M='SoftBodies_Playground_of_Joy'
O=R/'doc/book/iterations/2026-10-09-more-shapes-kept'
O.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf8'))
def dump(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
entries=[('soft_capture_times','time',[15,18]),('soft_capture_gravity','gravity',[7,27]),('soft_capture_skin','skin',[22,32])]
if not (O/'before').exists():
 (O/'before').mkdir()
 for name in ['map_data.json','tutorial.md','final.md','technical.md']:shutil.copyfile(R/'commons/maps'/M/name,O/'before'/name)
 dump(O/'before/museum-plan.json',next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x['map']==M))
 dump(O/'before/source-hashes.json',{str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in [R/'commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.gd',R/'commons/soft_body/soft_body_sim.gd',R/'commons/artifacts/timing_machines/soft_workshop.gd']})
folder=R/'commons/artifacts/soft_snapshot_gallery'
shutil.copyfile(R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Playground_of_Joy/point_body.gd',folder/'capture_point.gd')
artifacts={}
for token,mode,cell in entries:
 (folder/(token+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/artifacts/soft_snapshot_gallery/soft_snapshot_gallery.gd" id="1"]\n\n[node name="SnapshotGallery" type="Node3D"]\nscript = ExtResource("1")\nstudy = "'+mode+'"\n',encoding='utf8')
 artifacts[token]={'lookup_name':token,'name':{'time':'Four moments, one recipe','gravity':'The same stop, another pull','skin':'One surface, two readings'}[mode],'scene':'res://commons/artifacts/soft_snapshot_gallery/'+token+'.tscn','category':'soft_bodies','dev_category':'softbodies','map_ready':True,'include_in_map_data':True,'map_sequences':['softbodies'],'description':{'time':'Four captures from the existing vessel simulation. Trigger the black point or CHANGE to compare another set of stop times.','gravity':'Three matching step200 vessels with opposite lateral gravity. Drag the black point sideways and release to change pull strength.','skin':'Two copies of one captured surface. Toggle its true triangle edges without changing geometry or the retained contact skin.'}[mode],'interactions':['Nearby CHANGE and RESET push buttons','Grabbable black PointBody; trigger or drag as labelled'],'qfep_connection':'The retained shape depends on the sampling decision; display and force conditions are made separately adjustable.','parameters':{'footprint':[9 if mode=='time' else 7,3.6,4],'size_group':'environment'},'tags':['sampling','snapshot','softbody','comparison']}
dump(R/'commons/artifacts/registry/soft_snapshot_gallery.json',{'artifacts':artifacts})
p=R/'commons/maps'/M/'map_data.json';data=read(p);cells=data['layers']['interactables']
for token,mode,(x,z) in entries:
 assert cells[z][x] in ['',token+':180']
 cells[z][x]=token+':180'
dump(p,data)
p=R/'commons/data/museum/em_plan.json';stamp=p.stat().st_mtime_ns;data=read(p);prior=copy.deepcopy(data)
row=next(x for x in data['plans'] if x['map']==M)
for token,mode,cell in entries:
 if not any(x['token']==token for x in row['artifacts']):row['artifacts'].append({'token':token,'cell':cell,'tile_cell':cell,'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+M,'cell':cell}})
assert [x for x in data['plans'] if x['map']!=M]==[x for x in prior['plans'] if x['map']!=M]
assert stamp==p.stat().st_mtime_ns
p.write_bytes(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode())
dump(O/'placements.json',entries)
print('Installed three comparison stations, nine vessel sculptures; all existing artifacts retained.')
