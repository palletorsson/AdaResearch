"""One immutable shared-recipe variant, native source export and placement receipt."""
from pathlib import Path
import argparse,copy,hashlib,json,os,shutil,struct,subprocess,sys,time
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1];WEB=ROOT.parent/'ada_encyclopedia';RUN=ROOT/'ada_run/transformation-lab'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,v):
 p.parent.mkdir(parents=True,exist_ok=True);tmp=p.with_suffix('.transform.tmp');tmp.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf8');os.replace(tmp,p)
def main():
 sys.stdout.reconfigure(encoding='utf8');parser=argparse.ArgumentParser();parser.add_argument('request');parser.add_argument('--job',required=True);a=parser.parse_args();assert len(a.job)==32 and all(c in '0123456789abcdef' for c in a.job)
 state=RUN/'jobs'/(a.job+'.json');created=time.strftime('%Y-%m-%dT%H:%M:%S%z');start=time.perf_counter();trial='transformation_'+a.job[:10];request=read(Path(a.request));folder=RUN/trial;folder.mkdir(parents=True,exist_ok=True)
 def update(status,**v):write(state,{'id':a.job,'status':status,'name':request['name'],'settings':request['settings'],'parent':request.get('parent'),'pid':os.getpid(),'created':created,'trial':trial,**v})
 try:
  update('compiling');r=subprocess.run(['node',str(ROOT/'tools/transformation_lab_compile.cjs'),'compile',a.request],capture_output=True,text=True,encoding='utf8',check=True);document=json.loads(r.stdout)
  directory=ROOT/'commons/void/trials'/trial;assert not directory.exists();directory.mkdir(parents=True);write(directory/'recipe.json',document)
  layout=read(ROOT/'commons/void/trials/s_portal_copies/layout.json');layout.update(levels=[0,-6,-12],floor_sources={},spine=[],floor_roles=['Roof',request['name'],'Catch floor'],spawn_points={'1':[0,.06,5]},cliff_landings={'enabled':False});layout['descent']['pad_disabled_floors']=[1,2];write(directory/'layout.json',layout)
  rooms=read(ROOT/'commons/void/trials/s_portal_copies/rooms.json')
  for f in rooms['floors']:
   for key in ['artifacts','props','copies','construction','walls']:f[key]=[]
  rooms['floors'][1]['title']=request['name'];rooms['floors'][1]['artifacts']=[{'id':'variation','artifact':'spatial_recipe','position':[0,0],'station':'SE','height':0,'facing':0,'scale':1,'config':{'recipe':'transformation_variant','recipe_document':f'res://commons/void/trials/{trial}/recipe.json','editor_label':request['name']}}];write(directory/'rooms.json',rooms)
  (directory/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n[node name="TransformationVariant" instance=ExtResource("1")]\ntrial_id = "'+trial+'"\n',encoding='utf8')
  registry=read(ROOT/'commons/void/trials/playable.json');item=copy.deepcopy(registry['trials']['s_portal_copies']);item.update(title=request['name'],map='Trans_Rotation',rooms=f'res://commons/void/trials/{trial}/rooms.json',layout=f'res://commons/void/trials/{trial}/layout.json',scene=f'res://commons/void/trials/{trial}/trial.tscn',models=f'/void-trials/{trial}/manifest.json',spawn_points={'1':[0,.06,5]});registry['trials'][trial]=item;write(ROOT/'commons/void/trials/playable.json',registry)
  update('exporting')
  with (folder/'export.log').open('w',encoding='utf8') as log:r=subprocess.run([sys.executable,str(ROOT/'tools/export_void_trial.py'),trial],cwd=ROOT,env=dict(os.environ,VOID_EXPORT_SKIP_PALETTE='1'),stdout=log,stderr=subprocess.STDOUT,timeout=600,creationflags=subprocess.CREATE_NO_WINDOW)
  assert r.returncode==0,'Export failed; inspect export.log';update('checking')
  with acquire_native_slot('Transformation variant '+trial):
   stage=stage_runtime()
   with (folder/'native.log').open('w',encoding='utf8') as log:r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--script','res://tools/probes/transformation_lab.gd','--','--no-bridges','--void-trial='+trial,'--pictures='+str(folder)],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
  checks=read(folder/'checks.json');assert r.returncode==0 and checks['passed'],f'Native variant failed (exit {r.returncode}); inspect checks.json and native.log'
  from void_log_diagnostics import split_errors
  errors,_=split_errors((folder/'native.log').read_text(encoding='utf8'),'TRANSFORMATION_LAB_DONE',allow_shutdown=r.returncode==0);assert not errors,errors
  public=WEB/'public/void-trials'/trial;manifest=read(public/'manifest.json')
  files=[directory/'recipe.json',directory/'rooms.json',directory/'layout.json',ROOT/'commons/modular/transformation.json',ROOT/'commons/modular/builder.gd',ROOT/'commons/modular/portal_piece.gd',ROOT/'commons/modular/lab_input.gd',ROOT/'commons/modular/recipe_area.gd']
  if document['settings']['source']!='portal':
   from lab_input_catalog import inputs
   token='timber_plank_2m' if document['settings']['source']=='plank' else 'do_not_cross_barrier';source=inputs()[token];files.append(ROOT/source['scene'][6:]);source_manifest=read(WEB/'public/spatial-lab-inputs/manifest.json')['models'][token];files.extend(ROOT/p for p in source_manifest['source_files'])
  sources={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files};manifest.setdefault('source_files',{}).update(sources);write(public/'manifest.json',manifest)
  for p in manifest['floors']['1']['artifacts']['variation']['parts'].values():
   b=(WEB/'public'/p['url'].lstrip('/')).read_bytes();assert struct.unpack_from('<I',b)[0]==0x46546c67 and struct.unpack_from('<I',b,8)[0]==len(b);assert json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]].decode().strip()).get('meshes')
  for name in ['native.png','checks.json']:shutil.copy2(folder/name,public/name)
  result={'passed':True,'settings':document['settings'],'source_hash':document['source_hash'],'lineage':document['lineage'],'seconds':round(time.perf_counter()-start,2),'native_checks':len(checks['checks']),'findings':checks['findings'],'scope':checks['scope'],'source_files':sources,'editor':f'/lab-editor?mode=void&trial={trial}&floor=1','manifest':f'/void-trials/{trial}/manifest.json','image':f'/void-trials/{trial}/native.png','config':rooms['floors'][1]['artifacts'][0]['config']}
  write(folder/'result.json',result);update('complete',**result);print(json.dumps(result))
 except Exception as e:update('failed',error=str(e));raise
if __name__=='__main__':main()
