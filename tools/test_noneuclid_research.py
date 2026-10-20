"""Run bounded Godot maths, GPU-mask and visual feasibility probes."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, shutil, subprocess

ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'doc/book/studies/noneuclid-research'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    out=PROJECT/'runs'/stamp
    out.mkdir(parents=True)
    hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in PROJECT.iterdir() if p.suffix in ['.gd','.tscn','.godot']}
    results=[]
    tasks=[('kernel',['--headless','--script','res://test_kernel.gd'],'kernel-results.json')]
    tasks += [('stencil-'+r,['--rendering-method',r,'--','--capture'],'stencil-'+r+'.json') for r in ['gl_compatibility','mobile','forward_plus']]
    tasks += [('geometry-'+m,['res://curved.tscn','--','--capture','--mode='+m],None) for m in ['disk','sphere','ball','product','inside']]
    for name,args,result in tasks:
        command=[ENGINE,'--path',str(PROJECT),'--audio-driver','Dummy']+args
        run=subprocess.run(command,capture_output=True,text=True,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=run.stdout+run.stderr
        (out/(name+'.log')).write_text(log,encoding='utf-8')
        healthy=run.returncode==0 and not any(s in log for s in ['SCRIPT ERROR','SHADER ERROR','ERROR:'])
        if result:
            record=json.loads((PROJECT/result).read_text())
            healthy=healthy and record['passed'] and all(c['passed'] for c in record['checks'])
            if name.startswith('stencil-'): healthy=healthy and record['renderer']==name.removeprefix('stencil-')
            shutil.copy2(PROJECT/result,out/result)
        else:
            healthy=healthy and ('CURVED RENDER '+name.removeprefix('geometry-')+' complete' in log)
        if name!='kernel':
            image=PROJECT/(name+'.png')
            healthy=healthy and image.exists() and image.stat().st_size>10000
            shutil.copy2(image,out/image.name)
        results.append({'name':name,'passed':healthy,'exit_code':run.returncode,'command':command})
        print(name,'PASS' if healthy else 'FAIL')
    data={'created_utc':stamp,'scope':'author feasibility; not ghost-student, headset or finished museum encounter verification', 'passed':all(r['passed'] for r in results), 'source_sha256':hashes,'runs':results}
    (out/'run.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    (PROJECT/'latest-run.json').write_text(json.dumps({'directory':str(out.relative_to(ROOT)).replace('\\','/'),**data},indent=2),encoding='utf-8')
    assert data['passed']

if __name__=='__main__': main()
