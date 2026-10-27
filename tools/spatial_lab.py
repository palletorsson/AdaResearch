"""Small lab loop: bind an existing recipe, save an isolated trial, export and check.

No source edits, main-floor edits or per-variation GDScript. Results keep recipe /
source fingerprints and separate startup/export, native-test and construction times.
"""
import argparse, hashlib, json, math, os, shutil, struct, subprocess, sys, time
from pathlib import Path
from generated_storage import model_directory
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from lab_input_catalog import inputs, fingerprint as input_fingerprint
ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent/'ada_encyclopedia'
RUN = ROOT/'ada_run/spatial-lab-2026-10-27'

def read(path): return json.loads(path.read_text(encoding='utf8'))
def write(path, value):
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp = path.with_suffix(path.suffix+'.lab.tmp')
    tmp.write_text(json.dumps(value,indent=2)+'\n',encoding='utf8');os.replace(tmp,path)
def fingerprint(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def recipe_hash(term): return hashlib.sha256(json.dumps(term,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()

def validate(request):
    spec=read(ROOT/'commons/modular/lab.json');terms=read(ROOT/'commons/modular/terms.json')['terms']
    recipe=request.get('recipe');assert recipe in [v['id'] for v in spec['recipes']], 'Unknown recipe'
    term=terms[recipe];bindings=dict(term['parameters']);provided=request.get('bindings',{})
    assert isinstance(provided,dict) and set(provided)<=set(bindings), 'Unknown recipe argument'
    bindings.update(provided)
    assert bindings['source'] in inputs(), 'Unknown prefab source'
    settings=next(v for v in spec['recipes'] if v['id']==recipe)
    for key,value in bindings.items():
        if key=='source':continue
        if key=='holes':continue
        low,high=settings.get('limits',{}).get(key,spec['limits'].get(key))
        assert type(value) in [int,float] and math.isfinite(value) and low<=value<=high, 'Invalid '+key
        if key in ['count','columns','rows']:assert int(value)==value,'Grid sizes must be integers'
    if 'holes' in bindings:
        holes=bindings['holes'];assert isinstance(holes,list) and len(holes)<=81,'Invalid missing cells'
        assert all(isinstance(c,list) and len(c)==2 and all(type(v)==int for v in c) and 0<=c[0]<bindings['columns'] and 0<=c[1]<bindings['rows'] for c in holes),'Invalid missing-cell coordinate'
        assert len({tuple(c) for c in holes})==len(holes),'Duplicate missing cells'
    if request.get('recipe_hash'):assert request['recipe_hash']==recipe_hash(term),'Recipe changed; reload before saving'
    return recipe,bindings,recipe_hash(term)

def create_trial(request,job):
    recipe,bindings,digest=validate(request);trial='spatial_lab_'+job[:10]
    directory=ROOT/'commons/void/trials'/trial
    assert not directory.exists(), 'Variation already exists'
    directory.mkdir(parents=True)
    rooms=read(ROOT/'commons/void/trials/spatial_lab/rooms.json')
    rooms['floors']=[rooms['floors'][0],rooms['floors'][1],rooms['floors'][3]]
    floor=rooms['floors'][1];floor['title']='Lab variation / '+recipe
    # Keep the same staging centre used in the reference trial, clear of shafts.
    floor['artifacts']=[{'id':'variation','artifact':'spatial_recipe','station':'SE','position':[-17 if recipe=='lab_growing' else 0,0],'facing':0,'height':0,'scale':1,'config':{'recipe':recipe,'bindings':bindings}}]
    layout=read(ROOT/'commons/void/trials/spatial_lab/layout.json');layout['levels']=[0,-6,-12];layout['floor_roles']=['Canopy','Lab variation','Catch floor']
    write(directory/'rooms.json',rooms);write(directory/'layout.json',layout)
    (directory/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n[node name="LabVariation" instance=ExtResource("1")]\ntrial_id = "'+trial+'"\n')
    # Fresh read / atomic replacement; never replace any existing trial or layout.
    path=ROOT/'commons/void/trials/playable.json';registry=read(path)
    item=dict(registry['trials']['spatial_lab']);item.update(title='Lab variation / '+recipe,map='Trans_Translation',rooms='res://'+(directory/'rooms.json').relative_to(ROOT).as_posix(),layout='res://'+(directory/'layout.json').relative_to(ROOT).as_posix(),scene='res://'+(directory/'trial.tscn').relative_to(ROOT).as_posix(),models='/void-trials/'+trial+'/manifest.json',retry_floors={'0':1,'1':1,'2':1},spawn_points={'1':[-14,.06,4] if recipe=='lab_growing' else [0,.06,4]})
    if recipe=='lab_warehouse':
        item['spawn_points']={'1':[0,float(bindings['deck'])+.06,(int(bindings['rows'])-1)*float(bindings['spacing'])/2+.8]}
    registry['trials'][trial]=item;write(path,registry)
    selected=inputs()[bindings['source']]
    write(directory/'recipe.json',{'recipe':recipe,'bindings':bindings,'recipe_hash':digest,'sources':{selected['id']:{'scene':selected['scene'],'fingerprint':input_fingerprint(selected)}},'created_at':time.strftime('%Y-%m-%dT%H:%M:%S%z'),'job':job})
    return trial

def check(trial,folder,state=None):
    folder.mkdir(parents=True,exist_ok=True);timing={};started=time.perf_counter()
    main_hash=fingerprint(ROOT/'commons/void/rooms.json')
    provenance={file:fingerprint(ROOT/file) for file in ['commons/modular/terms.json','commons/modular/builder.gd','commons/modular/recipe_area.gd','commons/modular/lab_input.gd','commons/modular/lab.json','commons/void/primitive-prefabs.json','tools/probes/spatial_lab_probe.gd']}
    definitions=read(ROOT/'commons/void/trials/playable.json')['trials'][trial]
    rooms=read(ROOT/definitions['rooms'][6:]);catalogue=inputs()
    used={v.get('config',{}).get('bindings',{}).get('source','do_not_cross_barrier') for floor in rooms['floors'] for v in floor.get('artifacts',[]) if v['artifact']=='spatial_recipe'}
    input_provenance={key:{'scene':catalogue[key]['scene'],'fingerprint':input_fingerprint(catalogue[key])} for key in used}
    env=dict(os.environ,VOID_EXPORT_SKIP_PALETTE='1')
    t=time.perf_counter()
    result=subprocess.run([sys.executable,str(ROOT/'tools/export_void_trial.py'),trial],cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf8',timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
    (folder/'export.log').write_text(result.stdout+result.stderr,encoding='utf8')
    assert result.returncode==0,'Export failed; see export.log'
    timing['export_process_seconds']=round(time.perf_counter()-t,3)
    models=model_directory(folder/'source-models');models.mkdir(parents=True,exist_ok=True)
    t=time.perf_counter()
    with acquire_native_slot('Spatial lab / '+trial,timeout=60):
        stage=stage_runtime()
        command=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--position','100,80','--fixed-fps','60','--script','res://tools/probes/spatial_lab_probe.gd','--','--no-bridges','--void-trial='+trial,'--out='+str(models),'--pictures='+str(folder)]
        with (folder/'native.log').open('w',encoding='utf8') as stream:run=subprocess.run(command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
    timing['native_process_seconds']=round(time.perf_counter()-t,3)
    receipt=read(folder/'checks.json');log=(folder/'native.log').read_text(encoding='utf8',errors='replace')
    from void_log_diagnostics import split_errors
    errors,cleanup=split_errors(log,'SPATIAL_LAB_DONE',allow_shutdown=run.returncode==0)
    assert run.returncode==0 and receipt['passed'] and not errors,'Native arrangement check failed; see checks.json / native.log'
    public=WEB/'public/void-trials'/trial;manifest=read(public/'manifest.json')
    def model_urls(value):
        if isinstance(value,dict):
            for key,item in value.items():
                if key=='url' and isinstance(item,str) and item.endswith('.glb'):yield item
                else:yield from model_urls(item)
        elif isinstance(value,list):
            for item in value:yield from model_urls(item)
    model_count=0
    for url in set(model_urls(manifest)):
        file=WEB/'public'/url.lstrip('/')
        b=file.read_bytes();assert struct.unpack_from('<I',b)[0]==0x46546c67 and struct.unpack_from('<I',b,8)[0]==len(b)
        gltf=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]].decode().strip());assert gltf.get('meshes'),file
        model_count+=1
    for file in models.glob('source-*.glb'):shutil.copy2(file,public/file.name)
    assert main_hash==fingerprint(ROOT/'commons/void/rooms.json'),'Main tower changed during research; inspect concurrent work'
    timing['check_total_seconds']=round(time.perf_counter()-started,3)
    timing['construction_ms']={p['key']:p['build_ms'] for p in receipt['poses']}
    result={'passed':True,'trial':trial,'editor':'/lab-editor?mode=void&trial='+trial+'&floor=1','models':model_count,'native_checks':len(receipt['checks']),'timing':timing,'findings':receipt['findings'],'source_files':manifest.get('source_files',{}),'provenance':provenance,'inputs':input_provenance,'main_rooms_sha256':main_hash,'scope':receipt['scope'],'shutdown_diagnostics':cleanup}
    write(folder/'result.json',result)
    return result

def export_inputs():
    folder=RUN/'inputs';folder.mkdir(parents=True,exist_ok=True)
    models=model_directory(folder/'models');models.mkdir(parents=True,exist_ok=True)
    with acquire_native_slot('Spatial lab / catalogue inputs',timeout=60):
        stage=stage_runtime()
        command=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/spatial_lab_inputs.gd','--','--no-bridges','--out='+str(models),'--public-base=/spatial-lab-inputs']
        with (folder/'native.log').open('w',encoding='utf8') as log:run=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
    from void_log_diagnostics import split_errors
    errors,cleanup=split_errors((folder/'native.log').read_text(encoding='utf8'),'SPATIAL_INPUTS_DONE',allow_shutdown=run.returncode==0)
    receipt=read(models/'inputs.json') if (models/'inputs.json').exists() else {}
    assert run.returncode==0 and receipt.get('passed') and not errors,'Input export failed; see inputs/native.log'
    public=WEB/'public/spatial-lab-inputs';public.mkdir(parents=True,exist_ok=True)
    for file in models.glob('*.glb'):shutil.copy2(file,public/file.name)
    catalogue=inputs()
    for key,model in receipt['models'].items():
        scene=ROOT/catalogue[key]['scene'][6:]
        import re
        files=[scene,ROOT/'commons/modular/lab_input.gd']+[ROOT/p[6:] for p in re.findall(r'path="(res://[^\"]+\.gd)"',scene.read_text(encoding='utf8'))]
        model['source_files']={p.relative_to(ROOT).as_posix():fingerprint(p) for p in files}
        model['fingerprint']=input_fingerprint(catalogue[key])
    write(public/'manifest.json',receipt);write(folder/'result.json',receipt)
    print(json.dumps({'passed':True,'inputs':len(receipt['models']),'checks':len(receipt['checks'])}))

def main():
    sys.stdout.reconfigure(encoding='utf8');parser=argparse.ArgumentParser();parser.add_argument('action',choices=['check','create','inputs']);parser.add_argument('value',nargs='?',default='all');parser.add_argument('--job');args=parser.parse_args()
    if args.action=='inputs':export_inputs();return
    if args.action=='check':
        result=check(args.value,RUN/args.value);print(json.dumps(result));return
    assert args.job and len(args.job)==32 and all(c in '0123456789abcdef' for c in args.job)
    jobfile=RUN/'jobs'/(args.job+'.json');start=time.perf_counter();trial=''
    try:
        request=read(Path(args.value));trial=create_trial(request,args.job)
        save_seconds=round(time.perf_counter()-start,3)
        write(jobfile,{'status':'testing','pid':os.getpid(),'trial':trial,'save_seconds':save_seconds})
        result=check(trial,RUN/trial);result['timing']['save_seconds']=save_seconds;result['timing']['end_to_end_seconds']=round(time.perf_counter()-start,3)
        write(RUN/trial/'result.json',result);write(jobfile,{'status':'complete',**result})
    except Exception as error:
        write(jobfile,{'status':'failed','trial':trial,'error':str(error),'seconds':round(time.perf_counter()-start,3)});raise

if __name__=='__main__':main()
