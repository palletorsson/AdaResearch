from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside';S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_PhysarumColony'
text=(R/'commons/maps/SwarmIntelligence_PhysarumColony/tutorial.md').read_text(encoding='utf8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==3;hashes={}
for folder in ['printed','variation','fault-turn','fault-decay','fault-wrap']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='trail.gd':
   if folder=='variation':source=source.replace('Vector2(4,8)','Vector2(6,8)')
   if folder=='fault-turn':source=source.replace('headings[i] += TURN','headings[i] -= TURN')
   if folder=='fault-decay':source=source.replace('values[cell] *= retention','values[cell] *= 1.0')
   if folder=='fault-wrap':source=source.replace('fposmod(p.x, WIDTH), fposmod(p.y, WIDTH)','clampf(p.x,0,WIDTH-0.01), clampf(p.y,0,WIDTH-0.01)')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copy2(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/point_body.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/swarm_physarum_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-45:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_point_unchanged=True,fresh_engine_run=True)
receipt.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8');print(len(d['checks']),'checks passed')
