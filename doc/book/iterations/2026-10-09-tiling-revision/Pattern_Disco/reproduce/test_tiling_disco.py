"""Run the exact printed checker and the equal-grey-pair transfer."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Disco'
ENGINE=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(kind,changed=False):
    receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True)
    log=receipt.with_suffix('.log')
    if log.exists():
        history=OUT/'attempts';history.mkdir(exist_ok=True)
        suffix=len(list(history.glob(kind+'-*.log')))+1
        shutil.copy2(log,history/f'{kind}-{suffix}.log')
        if receipt.exists():shutil.copy2(receipt,history/f'{kind}-{suffix}.json');receipt.unlink()
    cmd=[ENGINE,'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_disco_student.gd','--','--lesson='+res(OUT/'learner'/kind/'01_palette_return.gd'),'--report='+res(receipt)]
    if changed:cmd.append('--changed')
    with log.open('w',encoding='utf8') as f:
        p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(receipt.read_text()) if receipt.exists() else {}
    errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
    row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
    print(json.dumps(row),flush=True);return row
def main():
    src=ROOT/'commons/maps/Pattern_Disco/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S))
    assert set(blocks)=={'01_palette_return.gd','palette.gd','grid_surface.gd','point_body.gd'}
    def write(kind,edit=None):
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name=='01_palette_return.gd':
                assert code.count(edit[0])==1,(kind,edit[0])
                code=code.replace(*edit)
            (folder/name).write_text(code+'\n',encoding='utf8')
    write('printed');write('equal-grey',('Palette.new([Color("172051"), Color("fc62ad")])','Palette.new([Color(0.4, 0.4, 0.4), Color(0.4, 0.4, 0.4)])'))
    for name,path in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[name]==(ROOT/path).read_text().rstrip()
    (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Replacing only the navy/pink pair with equal .4 grey entries preserves phase, addresses, transforms and binary values. A step exchanges values but all displayed tiles remain grey. Choosing another pair reveals the retained pattern; palette selection preserves partial elapsed time.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
    results=[run('printed'),run('equal-grey',True)]
    (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n')
    assert all(r['passed'] for r in results)
    faults=[]
    for kind,edit in {
      'phase-ignored':('address.x + address.y + phase','address.x + address.y'),
      'palette-resets-phase':('    palette_index = (palette_index + 1) % palettes.size()','    palette_index = (palette_index + 1) % palettes.size()\n    phase = 0'),
      'one-colour-for-all':('pair[value_at(address)]','pair[0]'),
      'lost-remainder':('        elapsed -= interval','        elapsed = 0.0'),
      'pause-ignored':('    if not playing:\n        return','    if false:\n        return')}.items():
        write(kind,edit);row=run(kind)
        row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1
        faults.append(row)
    (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n')
    assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
