"""Extract four printed files; test a controlled comparison and independent edit."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_02'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def run(kind,changed=False):
 receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True);log=receipt.with_suffix('.log')
 if log.exists():
  history=OUT/'attempts';history.mkdir(exist_ok=True);suffix=len(list(history.glob(kind+'-*.log')))+1
  shutil.copy2(log,history/f'{kind}-{suffix}.log')
  if receipt.exists():shutil.copy2(receipt,history/f'{kind}-{suffix}.json');receipt.unlink()
 cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_ribbon02_student.gd','--','--lesson='+res(OUT/'learner'/kind/'08_equal_targets.gd'),'--report='+res(receipt)]
 if changed:cmd.append('--changed')
 with log.open('w',encoding='utf8') as f:p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
 data=json.loads(receipt.read_text()) if receipt.exists() else {};errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
 row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
 print(json.dumps(row),flush=True);return row
def main():
 src=ROOT/'commons/maps/Ribbon_Patterns_02/tutorial.md'
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S));assert set(blocks)=={'08_equal_targets.gd','palette.gd','grid_surface.gd','point_body.gd'}
 def write(kind,edit=None):
  folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
  for name,code in blocks.items():
   if edit and name=='08_equal_targets.gd':assert code.count(edit[0])==1,(kind,edit[0]);code=code.replace(*edit)
   (folder/name).write_text(code+'\n',encoding='utf8')
 write('printed');write('grey_mint',('var source := [[0, 1, 0], [0, 0, 1]] # [z][x]\nvar palette = Palette.new([Color("172051")', 'var source := [[0, 1, 0], [0, 0, 2]] # [z][x]\nvar palette = Palette.new([Color(0.5, 0.5, 0.5)'))
 for n,p in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[n]==(ROOT/p).read_text().rstrip()
 (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Independent grey/mint edit: initial targets grey; cell2,1 selects mint; EQUAL follows selected colour; SWAP preserves targets/source and retains background order; same25 reference cubes.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
 results=[run('printed'),run('grey_mint',True)]
 (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n');assert all(r['passed'] for r in results)
 faults=[]
 for kind,edit in {
  'shared-surrounds':('surrounds.append(box(Vector3(x, 1.75, 0), Vector3(1.8, 1.2, 0.06)))','surrounds.append(box(Vector3(x, 1.75, 0), Vector3(1.8, 1.2, 0.06)))\n        if surrounds.size() == 2: surrounds[1].material_override = surrounds[0].material_override'),
  'detached-target':('target.material_override = target_material','target.material_override = target_material.duplicate()'),
  'detached-bridge':('bridge.material_override = target_material','bridge.material_override = target_material.duplicate()'),
  'no-refresh':('    refresh()\n\nfunc _process','    pass\n\nfunc _process'),
  'wrong-frame':('var local := to_local(control.global_position)','var local := control.global_position'),
  'wrong-wrap':('source[posmod(cell.y, source.size())][posmod(cell.x, source[0].size())]','source[posmod(cell.x, source.size())][posmod(cell.y, source[0].size())]'),
  'fixed-equal-grey':('target_material.albedo_color if equal else','Color(0.5, 0.5, 0.5) if equal else'),
  'ignored-swap':('var dark := (i == 0) != swapped','var dark := i == 0')}.items():
  write(kind,edit);row=run(kind);row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
 (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n');assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
