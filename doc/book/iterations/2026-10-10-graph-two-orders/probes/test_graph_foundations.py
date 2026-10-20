from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-graph-two-orders'
S=R/'doc/book/studies/graphs-through-the-hands/GT_Foundations'
text=(R/'commons/maps/GT_Foundations/tutorial.md').read_text(encoding='utf8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==3 and {n for n,_ in blocks}=={'study.gd','traversal.gd','point_body.gd'}
hashes={}
for folder in ['printed','variation','fault-end','fault-copy','fault-repeat']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='traversal.gd':
   if folder=='variation':source=source.replace('[1, 2],','[2, 1],',1)
   if folder=='fault-end':source=source.replace('pending.pop_front() if breadth else pending.pop_back()','pending.pop_back()')
   if folder=='fault-copy':source=source.replace('neighbours[vertex].duplicate()','neighbours[vertex]')
   if folder=='fault-repeat':source=source.replace('\t\tif vertex in visited:\n\t\t\tcontinue\n','')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/point_body.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/graph_foundations_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-38:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
data=json.loads(receipt.read_text());assert data['passed'] and data['completed'],data['failures']
data.update(started=started,finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_point_unchanged=True,fresh_engine_run=True)
receipt.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
print(len(data['checks']),'checks passed; three exact printed scripts and unchanged PointBody verified.')
