from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-connectivity-a-way-back';S=R/'doc/book/studies/graphs-through-the-hands/GT_Connectivity'
text=(R/'commons/maps/GT_Connectivity/tutorial.md').read_text(encoding='utf8');blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==7;hashes={}
for folder in ['printed','variation','fault-direction','fault-filter','fault-omission']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='reachability.gd':
   if folder=='variation':source=source.replace('"from": 5, "to": 1','"from": 5, "to": 2').replace('R04: 5 reports to 1.','R04: 5 reports to 2.')
   if folder=='fault-direction':source=source.replace('directed(reverse_arrows)','directed(false)')
   if folder=='fault-filter':source=source.replace('vertex in outward and vertex in inward','vertex in outward or vertex in inward')
   if folder=='fault-omission':source=source.replace('for index in active_records():','for index in range(records.size()):')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copy2(S/'study.tscn',O/folder/'study.tscn')
for name in ['point_body.gd','traversal.gd','route.gd','ledger.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Network_Analysis'/name).read_bytes()
assert (S/'network_study.gd').read_bytes()==(S.parent/'GT_Network_Analysis'/'study.gd').read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/graph_connectivity_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-45:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(started=started,finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_files_unchanged=True,fresh_engine_run=True)
receipt.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8');print(len(d['checks']),'checks passed')
