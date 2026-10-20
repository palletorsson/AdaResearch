from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Agent_Based_Modeling_ABM'
O=R/'doc/book/iterations/2026-10-10-abm-what-the-point-carries';S=R/'doc/book/studies/swarm-through-the-hands'/ID
text=(R/'commons/maps'/ID/'tutorial.md').read_text(encoding='utf8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==3;hashes={}
edits={'variation':('var return_speed := 3.0','var return_speed := 1.5'),
 'fault-pickup':('has_food = true','has_food = false'),
 'fault-replace':('func replace_agents() -> void:','func replace_agents() -> void:\n\tvalues.fill(0.0)'),
 'fault-delivery':('has_food and positions[i].distance_to(HOME)','positions[i].distance_to(HOME)')}
for folder in ['printed',*edits]:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='foragers.gd' and folder in edits:
   a,b=edits[folder];assert a in source;source=source.replace(a,b)
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copy2(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Boids_Algorithm/point_body.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/swarm_abm_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-65:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_point_unchanged=True,fresh_engine_run=True)
receipt.write_bytes((json.dumps(d,indent=2)+'\n').encode());print(len(d['checks']),'checks passed')
