"""Extract and run the printed Foundry motif plus an independently extended source."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry'
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
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_foundry_student.gd','--','--lesson='+res(OUT/'learner'/kind/'02_source_motif.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row),flush=True);return row
def main():
    src=ROOT/'commons/maps/Pattern_Foundry/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'02_source_motif.gd','palette.gd','grid_surface.gd','point_body.gd'}
    def write(kind,edit=None):
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name=='02_source_motif.gd':
                assert code.count(edit[0])==1,(kind,edit[0])
                code=code.replace(*edit)
            (folder/name).write_text(code+'\n',encoding='utf8')
    write('printed');write('third-row',('[[0, 1, 0], [0, 0, 1]]','[[0, 1, 0], [0, 0, 1], [2, 0, 0]]'))
    for n,p in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[n]==(ROOT/p).read_text().rstrip()
    (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Adding [2,0,0] makes row period three, preserves width three, receiver dimensions and transforms. (0,2) and (3,2) become mint. Source row zero returns at preview row three, not two. Editing source[0][1] affects four displayed addresses instead of six.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
    results=[run('printed'),run('third-row',True)]
    (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    assert all(r['passed'] for r in results)
    faults=[]
    for kind,edit in {
      'wrong-width':('posmod(address.x, source[0].size())','posmod(address.x, source.size())'),
      'row-ignored':('posmod(address.y, source.size())','0'),
      'no-repaint':('    paint()\n\nfunc choose','    pass\n\nfunc choose'),
      'wrong-frame':('grid.to_local(control.global_position)','control.global_position'),
      'no-height-gate':('local.y < 0.12 or local.y > 0.65 or not grid.cells.has(address)','not grid.cells.has(address)')}.items():
        write(kind,edit);row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
