"""Reconstruct the printed glide reader; test a four-row transfer and faults."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Symmetry_Seventeen'
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
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_symmetry_student.gd','--','--lesson='+res(OUT/'learner'/kind/'05_glide_reader.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row),flush=True);return row
def main():
    src=ROOT/'commons/maps/Symmetry_Seventeen/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'05_glide_reader.gd','04_surface_frame.gd','palette.gd','grid_surface.gd','point_body.gd'}
    def write(kind,edit=None):
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name=='05_glide_reader.gd':
                assert code.count(edit[0])==1,(kind,edit[0]);code=code.replace(*edit)
            (folder/name).write_text(code+'\n',encoding='utf8')
    write('printed');write('four_rows',('    assert(source.size()', '    source = [[0, 1, 0], [0, 0, 1], [2, 0, 0], [0, 2, 0]]\n    assert(source.size()'))
    for n,p in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[n]==(ROOT/p).read_text().rstrip()
    (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Four source rows give a two-row glide. Surface [row0,col3] reads source [2,2] value0; [row2,col4] reads [0,1] value1. Vertical translation period4, horizontal6. Paint [0,3] changes displayed flat indices3,12,23. Source and rule stay unchanged by receiver transforms.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
    results=[run('printed'),run('four_rows',True)]
    (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    assert all(r['passed'] for r in results)
    faults=[]
    for kind,edit in {
      'missing-glide':('cell.y = posmod(cell.y + source.size() / 2, source.size())','cell.y = cell.y'),
      'shift-every-block':('rule == 2 and posmod(tile_column, 2) == 1','rule == 2'),
      'no-reflection':('reflected = rule != 0','reflected = false'),
      'rule-mutates-source':('rule = (rule + 1) % RULE_NAMES.size()','rule = (rule + 1) % RULE_NAMES.size()\n    source[1][0] = 2'),
      'no-rule-repaint':('    reflected = rule != 0\n    repaint()','    reflected = rule != 0'),
      'paint-ignores-glide':('var cell := source_address(address)\n            source','var cell := super.source_address(address)\n            source'),
      'wrong-action-frame':('var local := to_local(control.global_position)','var local := control.global_position')}.items():
        write(kind,edit);row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
