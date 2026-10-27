"""Persist a square-portal item, export actual native pieces, and check the model."""
from pathlib import Path
import argparse,copy,hashlib,json,os,struct,subprocess,sys,time
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1];WEB=ROOT.parent/'ada_encyclopedia';RUN=ROOT/'ada_run/portal-lab'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,value):
 p.parent.mkdir(parents=True,exist_ok=True);temp=p.with_suffix('.portal.tmp');temp.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf8');os.replace(temp,p)
def main():
 sys.stdout.reconfigure(encoding='utf8');parser=argparse.ArgumentParser();parser.add_argument('request');parser.add_argument('--job',required=True);args=parser.parse_args()
 assert len(args.job)==32 and all(c in '0123456789abcdef' for c in args.job)
 state=RUN/'jobs'/(args.job+'.json');started=time.perf_counter();created=time.strftime('%Y-%m-%dT%H:%M:%S%z');trial='portal_item_'+args.job[:10]
 def update(status,**values):write(state,{'status':status,'pid':os.getpid(),'created':created,'trial':trial,**values})
 try:
  update('compiling');result=subprocess.run(['node',str(ROOT/'tools/portal_lab_compile.cjs'),'compile',args.request],cwd=ROOT,capture_output=True,text=True,encoding='utf8',check=True)
  compiled=json.loads(result.stdout);full=compiled.get('full_size',False)
  if full:assert compiled['envelope']['size'][0]<=4.7 and compiled['envelope']['size'][2]<=5.7,'Use Fit bend to floor 16 before saving full size'
  directory=ROOT/'commons/void/trials'/trial;assert not directory.exists(),'Variation already exists'
  directory.mkdir(parents=True);document=directory/'recipe.json';write(document,compiled)
  layout=read(ROOT/'commons/void/trials/s_portal_copies/layout.json')
  if full:
   layout.update(levels=[0,-6,-12,-18],floor_roles=['Roof','Square portal / full size','Passing floor','Exit floor'],floor_sources={},spine=[],spawn_points={'1':[6.4,.06,0]},cliff_landings={'enabled':False})
   layout['descent']['pad_disabled_floors']=[1,2,3]
  write(directory/'layout.json',layout)
  rooms=read(ROOT/'commons/void/trials/s_portal_copies/rooms.json');floor=rooms['floors'][1]
  if full:rooms['floors'].append(copy.deepcopy(rooms['floors'][2]))
  for record in rooms['floors']:
   for key in ['artifacts','props','walls','construction','copies']:record[key]=[]
  floor['title']='Square portal / saved item';floor['artifacts']=[{'id':'portal-item','artifact':'spatial_recipe','position':[10 if full else 0,0],'station':'SE','facing':0,'height':0,'scale':1,'config':{'recipe':'portal_lab_item','recipe_document':'res://'+document.relative_to(ROOT).as_posix()}}]
  if full:floor['artifacts'][0]['config'].update(connects_next_floor=True,connects_down_floors=int(compiled['settings']['drop']/6))
  write(directory/'rooms.json',rooms)
  (directory/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n[node name="PortalItem" instance=ExtResource("1")]\ntrial_id = "'+trial+'"\n',encoding='utf8')
  registry=read(ROOT/'commons/void/trials/playable.json');item=copy.deepcopy(registry['trials']['s_portal_copies']);item.update(title='Square portal / saved item',map='Trans_Rotation',rooms='res://'+(directory/'rooms.json').relative_to(ROOT).as_posix(),layout='res://'+(directory/'layout.json').relative_to(ROOT).as_posix(),scene='res://'+(directory/'trial.tscn').relative_to(ROOT).as_posix(),models='/void-trials/'+trial+'/manifest.json');registry['trials'][trial]=item;write(ROOT/'commons/void/trials/playable.json',registry)
  update('exporting',settings=compiled['settings']);folder=RUN/trial;folder.mkdir(exist_ok=True)
  env=dict(os.environ,VOID_EXPORT_SKIP_PALETTE='1',VOID_EXPORT_TIMEOUT='600')
  with (folder/'export.log').open('w',encoding='utf8') as stream:
   exported=subprocess.run([sys.executable,str(ROOT/'tools/export_void_trial.py'),trial],cwd=ROOT,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=900,creationflags=subprocess.CREATE_NO_WINDOW)
  assert exported.returncode==0,'Native export failed; see '+str(folder/'export.log')
  update('checking',settings=compiled['settings'])
  with acquire_native_slot('Square portal item / '+trial):
   stage=stage_runtime()
   with (folder/'native.log').open('w',encoding='utf8') as stream:
    native=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--script','res://tools/probes/portal_item.gd','--','--no-bridges','--void-trial='+trial,'--pictures='+str(folder),'--count='+str(compiled['settings']['count'])]+(['--full-size'] if full else []),cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
  receipt=read(folder/'checks.json');assert native.returncode==0 and receipt['passed'],'Native model failed; see '+str(folder/'native.log')
  public=WEB/'public/void-trials'/trial;manifest=read(public/'manifest.json');manifest['source_files'][document.relative_to(ROOT).as_posix()]=hashlib.sha256(document.read_bytes()).hexdigest();write(public/'manifest.json',manifest)
  urls=set()
  def collect(value):
   if isinstance(value,dict):
    for k,v in value.items():
     if k=='url' and isinstance(v,str) and v.endswith('.glb'):urls.add(v)
     else:collect(v)
   elif isinstance(value,list):
    for v in value:collect(v)
  collect(manifest)
  for url in urls:
   b=(WEB/'public'/url.lstrip('/')).read_bytes();assert struct.unpack_from('<I',b)[0]==0x46546c67 and struct.unpack_from('<I',b,8)[0]==len(b)
  shutil_copy=__import__('shutil').copy2
  for name in ['01-square-item.png','02-square-unit.png','checks.json']:shutil_copy(folder/name,public/name)
  result={'full_size':full,'passed':True,'settings':compiled['settings'],'source_hash':compiled['source_hash'],'editor':'/lab-editor?mode=void&trial='+trial+'&floor=1','manifest':'/void-trials/'+trial+'/manifest.json','image':'/void-trials/'+trial+'/01-square-item.png','checks':'/void-trials/'+trial+'/checks.json','native_checks':len(receipt['checks']),'findings':receipt['findings'],'seconds':round(time.perf_counter()-started,2),'models':len(urls),'scope':receipt['scope']}
  if full:
   update('placing_floor16',settings=compiled['settings'])
   from portal_floor16 import deploy
   result.update(deploy(trial,compiled,folder))
   result['seconds']=round(time.perf_counter()-started,2)
  write(folder/'result.json',result);update('complete',**result);print(json.dumps(result))
 except Exception as error:
  update('failed',error=str(error),seconds=round(time.perf_counter()-started,2));raise
if __name__=='__main__':main()
