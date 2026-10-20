from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-flow-room-for-another';S=R/'doc/book/studies/graphs-through-the-hands/GT_Flow'
t=(R/'commons/maps/GT_Flow/tutorial.md').read_text(encoding='utf8');blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',t,re.S)
assert len(blocks)==5;hashes={}
for folder in ['printed','variation','fault-reverse','fault-bottleneck','fault-residual']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='flow_model.gd':
   if folder=='variation':source=source.replace('"a": 5, "b": 6, "cap": 2','"a": 5, "b": 6, "cap": 1')
   if folder=='fault-reverse':source=source.replace('flow[b][a] -= amount','pass # cancellation omitted')
   if folder=='fault-bottleneck':source=source.replace('mini(amount, residual','maxi(amount, residual')
   if folder=='fault-residual':source=source.replace('capacity[a][b] - flow[a][b]','capacity[a][b]')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
for n in ['point_body.gd','traversal.gd']:assert (S/n).read_bytes()==(S.parent/'GT_Spanning_Trees'/n).read_bytes()
assert (S/'route.gd').read_bytes()==(S.parent/'GT_Pathfinding/route.gd').read_bytes()
for n in ['flow_model.gd','route.gd','traversal.gd']:assert (S/n).read_bytes()==(R/'commons/artifacts/graph_worlds'/n).read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copyfile(receipt,O/'previous-checks.json');receipt.unlink()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/graph_flow_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-44:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(started=started,finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(t.encode()).hexdigest(),carried_files_unchanged=True,fresh_engine_run=True)
receipt.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8');print(len(d['checks']),'checks passed')
