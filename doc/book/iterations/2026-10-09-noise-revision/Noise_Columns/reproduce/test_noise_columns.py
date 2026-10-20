"""Extract and execute the files printed in Noise Columns, including changed and faulty copies."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-noise-revision/Noise_Columns'
ENGINE=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(kind,changed=False):
    receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True)
    log=receipt.with_suffix('.log')
    if receipt.exists():
        history=OUT/'attempts';history.mkdir(exist_ok=True)
        i=len(list(history.glob(kind+'-*.json')))+1
        shutil.copy2(receipt,history/f'{kind}-{i}.json')
        if log.exists():shutil.copy2(log,history/f'{kind}-{i}.log')
        receipt.unlink()
    cmd=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/noise_columns_student.gd','--','--lesson='+res(OUT/'learner'/kind/'02_column_drivers.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(x in log.read_text(encoding='utf8',errors='replace') for x in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'exit':p.returncode,'checks':len(data.get('checks',[])),'passed':p.returncode==0 and data.get('passed',False) and not errors,'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row),flush=True);return row
def main():
    src=ROOT/'commons/maps/Noise_Columns/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'02_column_drivers.gd','shaft.gd','point_body.gd'}
    def write(kind,edit=None):
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and edit[0]==name:
                assert code.count(edit[1])==1,(kind,edit[1])
                code=code.replace(edit[1],edit[2])
            (folder/name).write_text(code+'\n',encoding='utf8')
    write('printed');write('half-drop',('02_column_drivers.gd','@export var top_drop := 0.70','@export var top_drop := 0.35'))
    assert blocks['point_body.gd']==(ROOT/'doc/book/studies/randomness-lineage/point_body.gd').read_text().rstrip()
    prediction={'source_sha256':sha(src),'prediction':'Changing only top_drop .70 to .35 halves every Y displacement at the same source value. Drivers, period, seed, addresses, X/Z, rest positions and faces remain. At sine quarter-period top rises from 1.70 to 2.05m; zero value restores the source positions. Repeated calls do not accumulate displacement.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}}
    (OUT/'prediction.json').write_text(json.dumps(prediction,indent=2)+'\n')
    results=[run('printed'),run('half-drop',True)]
    (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    assert all(r['passed'] for r in results)
    mutations={
      'wrong-period':('02_column_drivers.gd','sin(seconds * 0.9)','sin(seconds * 1.8)'),
      'field-ignores-address':('02_column_drivers.gd','noise.get_noise_2d(seconds * 0.55, 0.0)','noise.get_noise_2d(0.0, 0.0)'),
      'pause-ignored':('02_column_drivers.gd','    if not playing:\n        return','    if false:\n        return'),
      'lost-rest':('shaft.gd','    points.clear()','    if not points.is_empty():\n        rest.assign(points)\n    points.clear()'),
      'uniform-drop':('shaft.gd','weights[i] * maximum_drop','1.0 * maximum_drop'),
    }
    faults=[]
    for kind,edit in mutations.items():
        write(kind,edit);row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1
        faults.append(row)
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
