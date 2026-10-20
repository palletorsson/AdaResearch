"""Extract three printed files; test shader sampling, supplied host and independent edit."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_03'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def run(kind,changed=False):
 receipt=OUT/'tests'/(kind+'.json');receipt.parent.mkdir(exist_ok=True);log=receipt.with_suffix('.log')
 if log.exists():
  history=OUT/'attempts';history.mkdir(exist_ok=True);suffix=len(list(history.glob(kind+'-*.log')))+1
  shutil.copy2(log,history/f'{kind}-{suffix}.log')
  if receipt.exists():shutil.copy2(receipt,history/f'{kind}-{suffix}.json');receipt.unlink()
 cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_ribbon03_student.gd','--','--lesson='+res(OUT/'learner'/kind/'09_studio_lesson.tscn'),'--report='+res(receipt)]
 if changed:cmd.append('--changed')
 with log.open('w',encoding='utf8') as f:p=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
 data=json.loads(receipt.read_text()) if receipt.exists() else {};errors=any(s in log.read_text(encoding='utf8',errors='replace') for s in ['SCRIPT ERROR:','Parse Error:'])
 row={'kind':kind,'passed':p.returncode==0 and data.get('passed',False) and not errors,'exit':p.returncode,'checks':len(data.get('checks',[])),'failed_assertions':data.get('failures',[]),'script_error':errors,'receipt':receipt.relative_to(OUT).as_posix(),'log':log.relative_to(OUT).as_posix()}
 print(json.dumps(row),flush=True);return row
def main():
 src=ROOT/'commons/maps/Ribbon_Patterns_03/tutorial.md'
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl|ini)\n(.*?)\n```',src.read_text(encoding='utf8'),re.S));assert set(blocks)=={'09_fabric_sample.gdshader','09_studio_lesson.gd','09_studio_lesson.tscn'}
 def write(kind,edit=None,file='09_fabric_sample.gdshader'):
  folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
  for name,code in blocks.items():
   if edit and name==file:assert code.count(edit[0])==1,(kind,edit[0]);code=code.replace(*edit)
   (folder/name).write_text(code+'\n',encoding='utf8')
 write('printed');write('three_vertical',('vec2(repeats, 2.0)','vec2(repeats, 3.0)'))
 (OUT/'prediction.json').write_text(json.dumps({'source_sha256':sha(src),'prediction':'Independent three vertical repeats:wall2m/3;UV(.15,.20) with4horizontal phase0 reads source[2][2]=3gold. Existing recipe saves no vertical count or shader code. Fresh saved receiver keeps production two vertical repeats.','files':{n:sha(OUT/'learner/printed'/n) for n in blocks}},indent=2)+'\n')
 results=[run('printed'),run('three_vertical',True)]
 (OUT/'tests.json').write_text(json.dumps({'all_passed':all(r['passed'] for r in results),'checks':sum(r['checks'] for r in results),'results':results},indent=2)+'\n');assert all(r['passed'] for r in results)
 faults=[]
 for kind,edit in {
  'ignore-repeat':('UV * vec2(repeats, 2.0)','UV * vec2(1.0, 2.0)'),
  'ignore-offset':('vec2(phase, 0.0)','vec2(0.0, 0.0)'),
  'vertical-offset':('vec2(phase, 0.0)','vec2(0.0, phase)'),
  'swapped-uv':('UV * vec2(repeats, 2.0)','UV.yx * vec2(repeats, 2.0)'),
  'clamped-source':('repeat_enable','repeat_disable'),
  'linear-filter':('filter_nearest','filter_linear')}.items():
  write(kind,edit);row=run(kind);row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
 write('missed-skirt',('[studio.wall, skirt]','[studio.wall]'),'09_studio_lesson.gd');row=run('missed-skirt');row['rejected_by_assertions']=bool(row['failed_assertions']) and not row['script_error'] and row['exit']==1;faults.append(row)
 (OUT/'mutations.json').write_text(json.dumps({'all_rejected':all(r['rejected_by_assertions'] for r in faults),'results':faults},indent=2)+'\n');assert all(r['rejected_by_assertions'] for r in faults)
if __name__=='__main__':main()
