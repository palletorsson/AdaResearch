"""Reconstruct the printed surface frame; test a narrower-width transfer and faults."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def run(kind,changed=False):
    receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True)
    log=receipt.with_suffix('.log')
    if log.exists():
        history=OUT/'attempts';history.mkdir(exist_ok=True)
        suffix=len(list(history.glob(kind+'-*.log')))+1
        shutil.copy2(log,history/f'{kind}-{suffix}.log')
        if receipt.exists():shutil.copy2(receipt,history/f'{kind}-{suffix}.json');receipt.unlink()
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_surface_student.gd','--','--lesson='+res(OUT/'learner'/kind/'04_surface_frame.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row),flush=True);return row
def main():
    src=ROOT/'commons/maps/Array_Patterns/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'04_surface_frame.gd','palette.gd','grid_surface.gd','point_body.gd'}
    def write(kind,edit=None):
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name=='04_surface_frame.gd':
                assert code.count(edit[0])==1,(kind,edit[0]);code=code.replace(*edit)
            (folder/name).write_text(code+'\n',encoding='utf8')
    write('printed');write('narrower',('[0.32, 0.48]','[0.24, 0.36]'))
    for n,p in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[n]==(ROOT/p).read_text().rstrip()
    (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Widths 0.24 and 0.36 yield source spans 0.72 and 1.08 metres. Colours, source and all 25 local cubes stay unchanged. The same address (3,1) is selected in table/wall poses under a translated/rotated host. The point-centre gate remains 0.12 to 0.65 metres.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
    results=[run('printed'),run('narrower',True)]
    (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    assert all(r['passed'] for r in results)
    faults=[]
    for kind,edit in {
      'world-for-local':('grid.to_local(control.global_position)','control.global_position'),
      'scaled-distance':('local.y * grid.scale.y','local.y'),
      'wrong-wall-row':('Vector3(PI / 2, -PI / 2, 0)','Vector3(-PI / 2, -PI / 2, 0)'),
      'fixed-width':('Vector3.ONE * widths[width_index] / LOCAL_PITCH','Vector3.ONE'),
      'frame-mutates-source':('wall = not wall','wall = not wall\n    source[1][0] = 2'),
      'wrong-action-frame':('var local := to_local(control.global_position)','var local := control.global_position'),
      'missing-half-cell':('local.x + LOCAL_PITCH / 2','local.x')}.items():
        write(kind,edit);row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
