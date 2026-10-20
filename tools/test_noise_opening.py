"""Reconstruct only marked code printed in the first Noise tutorial and test it."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-noise-revision/Random_Noise_Types'
ENGINE=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')

def res(p): return 'res://'+p.relative_to(ROOT).as_posix()
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def run(kind,changed=False):
    folder=OUT/'learner'/kind
    receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True)
    log=receipt.with_suffix('.log')
    if receipt.exists():
        history=OUT/'attempts';history.mkdir(exist_ok=True)
        suffix=str(len(list(history.glob(kind+'-*.json')))+1)
        shutil.copy2(receipt,history/(kind+'-'+suffix+'.json'))
        if log.exists():shutil.copy2(log,history/(kind+'-'+suffix+'.log'))
        receipt.unlink()
    cmd=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/noise_opening_student.gd','--','--lesson='+res(folder/'01_spaced_points.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(x in log.read_text(encoding='utf8',errors='replace') for x in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'exit':p.returncode,'checks':len(data.get('checks',[])),'passed':p.returncode==0 and data.get('passed',False) and not errors,'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row))
    return row

def main():
    src=ROOT/'commons/maps/Random_Noise_Types/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'01_spaced_points.gd','point_body.gd'}
    for kind in ['printed','deeper']:
        d=OUT/'learner'/kind;d.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if kind=='deeper' and name=='01_spaced_points.gd':
                assert code.count('Vector3(1.2, 0.7, 0.06)')==1
                code=code.replace('Vector3(1.2, 0.7, 0.06)','Vector3(1.2, 0.7, 0.30)')
            (d/name).write_text(code+'\n',encoding='utf8')
    assert (OUT/'learner/printed/point_body.gd').read_text().rstrip()==(ROOT/'doc/book/studies/randomness-lineage/point_body.gd').read_text().rstrip()
    prediction={'source_sha256':sha(src),'prediction':'Changing half_size.z from .06 to .30 preserves the first centre X/Y and multiplies its Z by five. Subsequent admissions may change; spacing stays .34 metres in 3D, with at most 100 attempts per requested place. Restore reads homes without consuming a draw or replacing the point bodies.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}}
    (OUT/'prediction.json').write_text(json.dumps(prediction,indent=2)+'\n')
    results=[run('printed'),run('deeper',True)]
    if not all(r['passed'] for r in results):
        (OUT/'tests.json').write_text(json.dumps({'all_passed':False,'results':results},indent=2)+'\n')
        raise SystemExit(1)
    mutations={
        'no-reseed':('    rng.seed = seed_value','    pass # wrong: keep spending the old stream'),
        'no-break':('                break','                pass # wrong: continue filling this place'),
        'no-distance-rule':('        if candidate.distance_to(existing) < separation:','        if false:'),
        'lost-refusals':('            refused += 1','            refused += 0'),
        'restore-resamples':('    for i in range(points.size()):\n        points[i].position = CENTRE + homes[i]','    redraw()'),
    }
    faults=[]
    for kind,(old,new) in mutations.items():
        d=OUT/'learner'/kind;d.mkdir(exist_ok=True)
        for name,code in blocks.items():
            if name=='01_spaced_points.gd':
                assert code.count(old)==1,(kind,code.count(old))
                code=code.replace(old,new)
            (d/name).write_text(code+'\n',encoding='utf8')
        row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1
        faults.append(row)
    (OUT/'tests.json').write_text(json.dumps({'all_passed':True,'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)

if __name__=='__main__': main()
