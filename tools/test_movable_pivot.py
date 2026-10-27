"""One serialized native floor-slice review and actual editor geometry export."""
import argparse,hashlib,json,os,shutil,struct,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import model_directory

def main():
    sys.stdout.reconfigure(encoding='utf8')
    parser=argparse.ArgumentParser();parser.add_argument('--export-only',action='store_true');options=parser.parse_args()
    root=Path(__file__).resolve().parents[1];out=root/'ada_run/movable-pivot-2026-10-27';out.mkdir(exist_ok=True)
    models=model_directory(out/'native-models');models.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot('Movable pivot / actual floor slice',timeout=60);stage=stage_runtime()
    probe='export_movable_pivot.gd' if options.export_only else 'movable_pivot_probe.gd'
    args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--position','100,80','--fixed-fps','60','--script','res://tools/probes/'+probe,'--','--no-bridges','--out='+str(models),'--pictures='+str(out)]
    log_file=out/('export.log' if options.export_only else 'native.log')
    with log_file.open('w',encoding='utf8') as log:
        result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
    log=log_file.read_text(encoding='utf8',errors='replace')
    errors=[s for s in log.splitlines() if s.startswith(('ERROR:','SCRIPT ERROR:'))]
    print(log[-12000:])
    receipt={'passed':True,'scope':'Native export only'} if options.export_only else json.loads((out/'checks.json').read_text()) if (out/'checks.json').exists() else {'passed':False,'missing_receipt':True}
    receipt.update(exit_code=result.returncode,engine_errors=errors)
    receipt['passed']=receipt['passed'] and result.returncode==0 and not errors
    (out/('export-result.json' if options.export_only else 'run-result.json')).write_text(json.dumps(receipt,indent=2),encoding='utf8')
    if not receipt['passed']:return 1
    exported=json.loads((models/'assembly.json').read_text());assert not exported['failures']
    public=root.parent/'ada_encyclopedia/public/void-models';file=public/'manifest.json';manifest=json.loads(file.read_text(encoding='utf8'))
    for model in models.glob('15-movable-pivot-*.glb'):
        b=model.read_bytes();assert struct.unpack_from('<I',b)[0]==0x46546c67 and struct.unpack_from('<I',b,8)[0]==len(b)
        gltf=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]].decode().strip());assert gltf.get('meshes');shutil.copy2(model,public/model.name)
    manifest['floors']['15']['artifacts']['movable-pivot']=exported['artifact'];manifest['revision']=hashlib.sha256(json.dumps(manifest).encode()).hexdigest()[:12]
    tmp=file.with_suffix('.pivot.tmp');tmp.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8');os.replace(tmp,file)
    file=root/'commons/void/line_parts.json';parts=json.loads(file.read_text(encoding='utf8'));parts['movable_pivot_walkway']={k:v['default'] for k,v in exported['artifact']['parts'].items()}
    tmp=file.with_suffix('.pivot.tmp');tmp.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf8');os.replace(tmp,file)
    print('Published real native editor models and six editable parts.');return 0
if __name__=='__main__':raise SystemExit(main())
