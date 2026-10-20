from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Swarm_Intelligence_Algorithms'
O=R/'doc/book/iterations/2026-10-10-swarm-who-keeps-the-count';S=R/'doc/book/studies/swarm-through-the-hands'/ID
text=(R/'commons/maps'/ID/'tutorial.md').read_text(encoding='utf8');blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S);assert len(blocks)==4
hashes={};edits={'variation':('include_supplied: bool = true','include_supplied: bool = false'),'fault-loss':('count -= total(species,"loss")','count += total(species,"loss")'),'fault-supply':('count += total(species,"supplied")','count += 2*total(species,"supplied")'),'fault-history':('events.append(event.duplicate(true))','events.append(event)')}
for folder in ['printed',*edits]:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  assert (S/name).read_bytes()==(R/'commons/artifacts/population_account_walk'/name).read_bytes()
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='account.gd' and folder in edits:
   a,b=edits[folder];assert a in source;source=source.replace(a,b)
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copy2(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(S.parent/'SwarmIntelligence_Particle_Swarm_Optimization/point_body.gd').read_bytes()
assert (O/'before/ecosystem.gd').read_bytes()==(R/'algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/swarm_account_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=110,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-70:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),supplied_ecosystem_unchanged=True,fresh_engine_run=True)
receipt.write_bytes((json.dumps(d,indent=2)+'\n').encode());print(len(d['checks']),'checks passed')
