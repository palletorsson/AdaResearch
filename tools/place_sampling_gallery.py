from pathlib import Path
import copy,json,hashlib
R=Path(__file__).resolve().parents[1]
M='SoftBodies_Playground_of_Joy'
O=R/'doc/book/iterations/2026-10-09-more-shapes-kept'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def dump(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
token='soft_sampled_gallery';cell=[21,41]
folder=R/'commons/artifacts/soft_snapshot_gallery'
(folder/(token+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/artifacts/soft_snapshot_gallery/sampled_gallery.gd" id="1"]\n\n[node name="SampledGallery" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf8')
p=R/'commons/artifacts/registry/soft_snapshot_gallery.json';data=read(p)
data['artifacts'][token]={'lookup_name':token,'name':'From the soft body gallery','scene':'res://commons/artifacts/soft_snapshot_gallery/'+token+'.tscn','category':'soft_bodies','dev_category':'softbodies','map_ready':True,'include_in_map_data':True,'map_sequences':['softbodies'],'description':'Six actual gallery configurations, three at a time. Compare starting and captured geometry with the same framing. Cloth, lattice, branch, CA threads and two mould experiments.','interactions':['NEXT switches the three examples','POSE or held PointBody trigger switches start / captured geometry'],'parameters':{'footprint':[9,3.8,4],'size_group':'environment'},'tags':['sampling','snapshot','gallery','softbody'],'qfep_connection':'Conditions and the sampling moment leave a shape; the saved sculpture does not retain the capacity to resume the process.'}
dump(p,data)
p=R/'commons/maps'/M/'map_data.json';stamp=p.stat().st_mtime_ns;data=read(p);assert data['layers']['interactables'][41][21] in ['',token+':180'];data['layers']['interactables'][41][21]=token+':180';assert stamp==p.stat().st_mtime_ns;dump(p,data)
p=R/'commons/data/museum/em_plan.json';stamp=p.stat().st_mtime_ns;data=read(p);prior=copy.deepcopy(data)
row=next(x for x in data['plans'] if x['map']==M)
if not any(x['token']==token for x in row['artifacts']):row['artifacts'].append({'token':token,'cell':cell,'tile_cell':cell,'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+M,'cell':cell}})
assert [x for x in data['plans'] if x['map']!=M]==[x for x in prior['plans'] if x['map']!=M]
assert stamp==p.stat().st_mtime_ns;p.write_bytes(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode())
dump(O/'gallery-source-hashes.json',{str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in [R/'commons/testing/render_soft_body.gd',R/'commons/soft_body/research_configs.json',R/'commons/soft_body/soft_body_shapes.gd',R/'commons/soft_body/soft_body_sim.gd',folder/'gallery_samples.json']})
print('Installed six source-gallery experiments in one 3-place cabinet, at cell [21,41].')
