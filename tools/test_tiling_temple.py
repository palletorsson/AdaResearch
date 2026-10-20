"""Extract exactly the four printed files; run ownership, transfer and fault tests."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def run(kind,changed=False):
 receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True);log=receipt.with_suffix('.log')
 if log.exists():
  history=OUT/'attempts';history.mkdir(exist_ok=True);suffix=len(list(history.glob(kind+'-*.log')))+1
  shutil.copy2(log,history/f'{kind}-{suffix}.log')
  if receipt.exists():shutil.copy2(receipt,history/f'{kind}-{suffix}.json');receipt.unlink()
 cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_temple_student.gd','--','--lesson='+res(OUT/'learner'/kind/'06_receivers.gd'),'--report='+res(receipt)]
 if changed:cmd.append('--changed')
 with log.open('w',encoding='utf8') as f:p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
 data=json.loads(receipt.read_text()) if receipt.exists() else {};errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
 row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
 print(json.dumps(row),flush=True);return row
def main():
 src=ROOT/'commons/maps/Pattern_Temple/tutorial.md'
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',src.read_text(encoding='utf8'),re.S));assert set(blocks)=={'06_receivers.gd','palette.gd','grid_surface.gd','point_body.gd'}
 def write(kind,edit=None):
  folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
  for name,code in blocks.items():
   if edit and name=='06_receivers.gd':assert code.count(edit[0])==1,(kind,edit[0]);code=code.replace(*edit)
   (folder/name).write_text(code+'\n',encoding='utf8')
 write('printed');write('four_columns',('var source := [[0, 1, 0], [0, 0, 1]]','var source := [[0, 1, 2, 0], [2, 0, 1, 2]]'))
 for n,p in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[n]==(ROOT/p).read_text().rstrip()
 (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'With four columns, PG surface [0,4] reads source [1,3]=2. Table paint cycles it to0 and changes indices4,8,14,18,24 only on table. ALL copies it; later wall paint changes its own entry to1, table remains0. Copy works in either direction; poses and instance IDs persist.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
 results=[run('printed'),run('four_columns',True)]
 (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n');assert all(r['passed'] for r in results)
 faults=[]
 for kind,edit in {
  'alias-recipe':('recipes[i] = recipes[target].duplicate(true)','recipes[i] = recipes[target]'),
  'shallow-copy':('recipes[i] = recipes[target].duplicate(true)','recipes[i] = recipes[target].duplicate()'),
  'shared-initial-rows':('"source": source.duplicate(true)','"source": source'),
  'no-copy-repaint':('            repaint(i)','            pass'),
  'rule-wrong-target':('recipes[target]["rule"] = (recipes[target]["rule"] + 1)','recipes[0]["rule"] = (recipes[0]["rule"] + 1)'),
  'no-glide':('cell.y = posmod(cell.y + data.size() / 2, data.size())','cell.y = cell.y'),
  'wrong-action-frame':('var local := to_local(control.global_position)','var local := control.global_position'),
  'wrong-receiver-frame':('grid.to_local(control.global_position)','control.global_position')}.items():
  write(kind,edit);row=run(kind);row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
 (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n');assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
