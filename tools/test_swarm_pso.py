from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Particle_Swarm_Optimization'
O=R/'doc/book/iterations/2026-10-10-pso-a-place-remembered';S=R/'doc/book/studies/swarm-through-the-hands'/ID
text=(R/'commons/maps'/ID/'tutorial.md').read_text(encoding='utf8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==3;hashes={}
edits={'variation':('var social_pull := 1.5','var social_pull := 0.0'),
 'fault-initial':('best_scores.append(score(p))','best_scores.append(-INF)'),
 'fault-objective':('objective = clampi(next,Objective.CENTER,Objective.RIDGE)\n\treset_memories()','objective = clampi(next,Objective.CENTER,Objective.RIDGE)'),
 'fault-shared':('next_positions.append(p)','next_positions.append(p)\n\t\tif score(p) > shared_score:\n\t\t\tshared_score = score(p)\n\t\t\tshared = p')}
for folder in ['printed',*edits]:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  assert (S/name).read_bytes()==(R/'commons/artifacts/particle_swarm_walk'/name).read_bytes()
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='swarm.gd' and folder in edits:
   a,b=edits[folder];assert a in source;source=source.replace(a,b)
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copy2(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(S.parent/'SwarmIntelligence_Ant_Colony_Optimization/point_body.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/swarm_pso_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-65:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_point_unchanged=True,fresh_engine_run=True)
receipt.write_bytes((json.dumps(d,indent=2)+'\n').encode());print(len(d['checks']),'checks passed')
