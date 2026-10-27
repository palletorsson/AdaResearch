"""Serial native tabletop check, screenshots and actual editor model publication."""
import hashlib,json,os,shutil,struct,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import model_directory

def main():
    sys.stdout.reconfigure(encoding='utf8')
    root=Path(__file__).resolve().parents[1];out=root/'ada_run/sun-feather-2026-10-27';out.mkdir(exist_ok=True)
    models=model_directory(out/'native-models');models.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot('Sun feather / tabletop real input',timeout=60);stage=stage_runtime()
    receipt=out/'checks.json'
    if receipt.exists():
        old=out/'previous';old.mkdir(exist_ok=True);shutil.copy2(receipt,old/'checks.json')
        if (out/'native.log').exists():shutil.copy2(out/'native.log',old/'native.log')
        receipt.unlink()
    args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--position','100,80','--fixed-fps','60','--script','res://tools/probes/sun_feather_probe.gd','--','--no-bridges','--out='+str(models),'--pictures='+str(out)]
    with (out/'native.log').open('w',encoding='utf8') as log:result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=160,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(out/'native.log').read_text(encoding='utf8',errors='replace');errors=[s for s in log.splitlines() if s.startswith(('ERROR:','SCRIPT ERROR:'))];print(log[-14000:])
    r=json.loads(receipt.read_text()) if receipt.exists() else {'passed':False,'missing_receipt':True}
    r.update(exit_code=result.returncode,engine_errors=errors);r['passed']=r['passed'] and result.returncode==0 and not errors
    (out/'run-result.json').write_text(json.dumps(r,indent=2),encoding='utf8')
    if not r['passed']:return 1
    exported=json.loads((models/'assembly.json').read_text());assert not exported['failures']
    public=root.parent/'ada_encyclopedia/public/void-models';file=public/'manifest.json';manifest=json.loads(file.read_text(encoding='utf8'))
    count=0
    for model in models.glob('15-sun-feather-*.glb'):
        b=model.read_bytes();assert struct.unpack_from('<I',b)[0]==0x46546c67 and struct.unpack_from('<I',b,8)[0]==len(b)
        gltf=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]].decode().strip());assert gltf.get('meshes');shutil.copy2(model,public/model.name);count+=1
    manifest['floors']['15']['artifacts']['sun-feather']=exported['artifact'];manifest['revision']=hashlib.sha256(json.dumps(manifest).encode()).hexdigest()[:12]
    tmp=file.with_suffix('.sun.tmp');tmp.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8');os.replace(tmp,file)
    file=root/'commons/void/line_parts.json';parts=json.loads(file.read_text(encoding='utf8'));parts['sun_feather']={k:v['default'] for k,v in exported['artifact']['parts'].items()}
    tmp=file.with_suffix('.sun.tmp');tmp.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf8');os.replace(tmp,file)
    (out/'export-checks.json').write_text(json.dumps({'passed':True,'models':count,'parts':len(exported['artifact']['parts'])},indent=2),encoding='utf8')
    print('Published',count,'native models and twelve editable parts.');return 0
if __name__=='__main__':raise SystemExit(main())
