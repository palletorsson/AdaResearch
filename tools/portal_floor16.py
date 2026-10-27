"""Publish a checked full-size portal variation to the existing Rotation shaft.

Only the named descent is replaced. Every prior version is journalled before
the revision-checked editor save; models are merged without exporting the tower.
"""
from pathlib import Path
import copy,hashlib,json,os,subprocess,urllib.request
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1];WEB=ROOT.parent/'ada_encyclopedia'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,value):
 p.parent.mkdir(parents=True,exist_ok=True);temp=p.with_suffix('.portal.tmp');temp.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf8');os.replace(temp,p)
def api(data=None):
 request=urllib.request.Request('http://localhost:3003/api/void-layout',data=None if data is None else json.dumps(data).encode(),headers={'Content-Type':'application/json'})
 return json.load(urllib.request.urlopen(request,timeout=90))
def deploy(trial,compiled,folder):
 folder=folder.resolve();folder.mkdir(parents=True,exist_ok=True)
 layout_path=ROOT/'commons/void/layout.json';before_layout=layout_path.read_bytes();layout=json.loads(before_layout)
 assert layout['shaft_width']==5 and layout['shaft_depth']==6,'Floor 16 shaft changed; inspect before deployment'
 current=api();rooms=copy.deepcopy(current['rooms']);floor=rooms['floors'][16]
 previous=next(a for a in floor['artifacts'] if a['id']=='twisting-tunnel')
 assert previous['artifact'] in ['void_rotation_boolean_descent','spatial_recipe'],'The named descent was changed by another editor'
 write(folder/'before-floor16.json',current['rooms']);write(folder/'before-layout.json',layout)
 replacement={'id':'twisting-tunnel','artifact':'spatial_recipe','position':[10,0],'station':'NE','facing':0,'height':0,'scale':1,'config':{'recipe':'portal_lab_item','recipe_document':f'res://commons/void/trials/{trial}/recipe.json','connects_next_floor':True,'connects_down_floors':int(compiled['settings']['drop']/6),'editor_label':'Square portals / full-size falling bend'}}
 floor['artifacts']=[replacement if a['id']=='twisting-tunnel' else a for a in floor['artifacts']]
 # The old one-storey tunnel ended on this catch shelf. The new passage passes
 # through it and lands a storey lower; keep its source in the deployment journal.
 old_landings=[a for a in rooms['floors'][17]['artifacts'] if a['id']=='rotation-landing' and a['artifact']=='void_rotation_landing']
 rooms['floors'][17]['artifacts']=[a for a in rooms['floors'][17]['artifacts'] if a not in old_landings]
 # The new entry/exit tongues replace the old catch boards in this same shaft.
 disabled=layout['descent'].setdefault('pad_disabled_floors',[])
 for index in [16,17]:
  if index not in disabled:disabled.append(index)
 assert layout_path.read_bytes()==before_layout,'Tower layout changed during placement'
 result=api({'rooms':rooms,'revision':current['revision']});write(folder/'floor16-save.json',result);write(layout_path,layout)
 try:
  with acquire_native_slot('Full-size square descent / main floor16'):
   stage=stage_runtime()
   with (folder/'floor16-native.log').open('w',encoding='utf8') as log:
    run=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--script','res://tools/probes/portal_floor16.gd','--','--no-bridges','--pictures='+str(folder),'--out='+str(WEB/'public/void-models'),'--public-base=/void-models'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
  checks=read(folder/'floor16-checks.json');assert run.returncode==0 and checks['passed'],'Main floor 16 placement failed; see floor16-native.log'
 except Exception:
  # Roll back only our named placement if no one has subsequently edited it.
  fresh=api();target=next(a for a in fresh['rooms']['floors'][16]['artifacts'] if a['id']=='twisting-tunnel')
  if target==replacement:
   fresh['rooms']['floors'][16]['artifacts']=[previous if a['id']=='twisting-tunnel' else a for a in fresh['rooms']['floors'][16]['artifacts']]
   for landing in old_landings:
    if not any(a['id']==landing['id'] for a in fresh['rooms']['floors'][17]['artifacts']):fresh['rooms']['floors'][17]['artifacts'].append(landing)
   api({'rooms':fresh['rooms'],'revision':fresh['revision']})
  if read(layout_path)==layout:layout_path.write_bytes(before_layout)
  raise
 fragment=read(folder/'floor16-model.json');assert not fragment['failures']
 manifest_path=WEB/'public/void-models/manifest.json';manifest=read(manifest_path)
 manifest['floors']['16']['artifacts']['twisting-tunnel']=fragment['artifact']
 if old_landings:manifest['floors']['17']['artifacts'].pop('rotation-landing',None)
 archive=WEB/'public/void-models/archive-models.json'
 if archive.exists():
  preserved=read(archive);assert not preserved['failures'];manifest['floors']['16']['artifacts'].update(preserved['artifacts'])
 for name in ['commons/void/rooms.json','commons/void/layout.json',f'commons/void/trials/{trial}/recipe.json']:
  manifest.setdefault('source_files',{})[name]=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
 for p in (ROOT/'commons/void/trials/rotation_portal_archive').glob('*/recipe.json'):manifest['source_files'][p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
 manifest['revision']=hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest()[:12];write(manifest_path,manifest)
 parts_path=ROOT/'commons/void/line_parts.json';parts=read(parts_path)
 for model in manifest['floors']['16']['artifacts'].values():
  if model['artifact']=='spatial_recipe':parts.setdefault('spatial_recipe',{}).update({k:v['default'] for k,v in model['parts'].items()})
 write(parts_path,parts)
 public=WEB/'public/void-trials'/trial
 import shutil
 for name in ['03-floor16-entry.png','04-floor16-descent.png','floor16-checks.json']:shutil.copy2(folder/name,public/name)
 write(folder/'deployment.json',{'previous':previous,'old_intermediate_landings':old_landings,'replacement':replacement,'checks':checks,'trial':trial})
 return {'main_editor':'/lab-editor?mode=void&floor=16','main_image':f'/void-trials/{trial}/03-floor16-entry.png','main_checks':f'/void-trials/{trial}/floor16-checks.json'}
